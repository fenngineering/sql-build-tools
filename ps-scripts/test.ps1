<#
.SYNOPSIS  
    This script will test sqltest projects that require vstest    
.NOTES
  Version:        1.0
  Author:         Andrew J Fenna
  Creation Date:  01/10/2016
  Purpose/Change: Initial script development
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $False)]
    [string]$environmentOverride = $null,
    [Parameter(Mandatory = $False)]
    [string]$testProject = $null,
    [Parameter(Mandatory = $False)]
    [string]$test = $null
)
$here = Split-Path $MyInvocation.MyCommand.Path
$env:PSModulePath = $env:PSModulePath + ";$($here)"

Import-Module common -Force -ArgumentList $environmentOverride, "$(Join-Path $(Get-Location) '\build\ps-config')", $True

Write-Host "Testing against environment $environment..."

function Invoke-CreateSqlTestConfig {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $True)]
        [string]$sqlTestFile
    )
    process {            
        Import-Module EPS -Force -DisableNameChecking

        $configTemplate = "$(Join-Path $toolsPath "ps-templates\SqlUnitTesting\Config.eps")"
        $configFile = "$(Join-Path $solutionPath "\build\$($sqlTestFile).dll.config")"

        $connectionString = $(Get-ConnectionString -serverName $config[$environment].Server -databaseName $config[$environment].Testing.Database)

        New-Item $configFile -type file -force -value $(Expand-Template -file $configTemplate -binding @{ connectionString = $connectionString}) | Out-Null            
    
		Remove-Module -name EPS
	}
}

function Invoke-CreateTestSettings {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $True)]
        [string]$testFile
    )
    process {
        if ($config[$environment].Testing -ne $null) {
            Import-Module EPS -Force -DisableNameChecking
            $settingsTemplate = "$(Join-Path $toolsPath "ps-templates\SqlUnitTesting\TestSettings.eps")"
            $settingsFile = "$(Join-Path $solutionPath "\build\$($testFile).testsettings")" 
			Remove-Module EPS
            return $(New-Item $settingsFile -type file -force -value $(Expand-Template -file $settingsTemplate -binding @{ config = $config; environment = $environment; sqlTestFile = $testFile; }))
        }
        return $null
    }
}

function Initialize-TestDb {
    [cmdletbinding()]
    param()
    process {            
		if($config[$environment].ContainsKey("Testing")){
			
			if($config[$environment].Testing.Use64BitRunner -eq $true) {
				$cpuArchitecture = "x64"
			} else {
				$cpuArchitecture = "x86"
			}

			if (-not(($environment -EQ "CI") -or ($environment -EQ "DEV"))) {

				if (Test-Path $(Join-Path $solutionPath ".nuget\packages.config")) {

					Import-Module nuget

					Install-Packages -restoreReferences $False -initalisePackages $False | Out-Null

					Remove-Module nuget
					$useNugetPackage = $True
				}
			}

			if ($useNugetPackage) {
				Get-ChildItem  $(Join-Path $solutionPath "packages") -Filter "$($testProject)*.SqlTests.dll" -Recurse -ErrorAction Continue | 
					Foreach-Object {

					#1 copy sql test file to build folder
                        
					Copy-Item $_.FullName -Destination "$(Join-Path $solutionPath 'build')" 

					Invoke-CreateSqlTestConfig -sqlTestFile $_.BaseName 

					Invoke-Test -testFile $_.BaseName -cpuArchitecture $cpuArchitecture
				}
			}
			else {
				$ExcludedTestFixtures = @()
				if($config[$environment].Testing.ContainsKey("ExcludeTestFixtures")){
					foreach($Test2Exclude in $config[$environment].Testing.ExcludeTestFixtures.GetEnumerator()){
						$ExcludedTestFixtures += $($Test2Exclude.Test)
					}
				}
				Get-ChildItem  $(Get-BuildDir) -Filter "*.SqlTests.dll" -Recurse -ErrorAction Continue | 
					Foreach-Object {
						if( -not $ExcludedTestFixtures.Contains($($_.BaseName))){
							Invoke-CreateSqlTestConfig -sqlTestFile $_.BaseName

							Invoke-Test -testFile $_.BaseName -cpuArchitecture $cpuArchitecture
						}
						else{
							Write-Warning "Excluded test Fixture: $($_.BaseName)"
						}
				}
			}

		}
	}
}

function Initialize-Test {
    [cmdletbinding()]
    param()
    process {            

		$ExcludedTestFixtures = @()
		if($config[$environment].Testing.ContainsKey("ExcludeTestFixtures")){
			foreach($Test2Exclude in $config[$environment].Testing.ExcludeTestFixtures.GetEnumerator()){
				$ExcludedTestFixtures += $($Test2Exclude.Test)
			}
		}

        Get-ChildItem  $(Get-BuildDir) -Filter "*.Tests.dll" -ErrorAction Continue | 
            Foreach-Object {
	            if( -not $ExcludedTestFixtures.Contains($($_.BaseName))){
					Invoke-Test -testFile $($_.BaseName) -cpuArchitecture "x86"
				}
				else{
					Write-Warning "Excluded test Fixture: $($_)"
				}
		}
	}
}

function Invoke-Test {
    [cmdletbinding()]
    param(            
        [Parameter(Mandatory = $True)]
        [string]$testFile,
        [Parameter(Mandatory = $True)]
        [string]$cpuArchitecture
    )
    process {

        Import-Module vstest

        $testSettings = $(Invoke-CreateTestSettings -testFile $testFile)
        $testFilePath = "$(Join-Path $solutionPath '\build\')$($testFile).dll"
        $testResultsDir = Get-TestResultsDir
            
        $resultsFile = "$($testResultsDir)\$($testFile)_$([DateTime]::Now.ToString("yyyyMMdd-HHmmss")).trx"
        
        Invoke-VSTest -testFilePath $testFilePath -testSettings $testSettings.FullName -testResultsDir $testResultsDir -test $test -cpuArchitecture $cpuArchitecture

		Remove-Module -Name vstest
    }
}

function Get-TestResultsDir{
    [cmdletbinding()]
    param()
    process{
        return $(Join-Path $solutionPath "TestResults")
    }
}

function Initialize-TestResults{
    [cmdletbinding()]
    param()
    process{
        $testResultsDir = Get-TestResultsDir

        if(Test-Path $testResultsDir){
            'Deleting output folder [{0}]' -f $testResultsDir | Write-Verbose
            Remove-Item $testResultsDir -Recurse -Force
        }

		New-Item -ItemType directory -Path $testResultsDir -Force | Out-Null
    }
}

Initialize-TestResults

Initialize-TestDb

Initialize-Test

if($global:TestsRun -eq $true) {
	Write-Host "Total Failed Tests $($global:failed)" -foregroundcolor White
}

Write-Host -ForegroundColor Red "                         |\=."
Write-Host -ForegroundColor Red "                         /  6'"
Write-Host -ForegroundColor Red "                 .--.    \  .-'"
Write-Host -ForegroundColor Red "                /_   \   /  (_()"
Write-Host -ForegroundColor Red "                  )   | / `;--'"
Write-Host -ForegroundColor Red "                 /   / /   ("
Write-Host -ForegroundColor Red "                (    `"    _)_"
Write-Host -ForegroundColor Red "                 `-==-'`""""""`"
Write-Host -ForegroundColor Yellow "    ____  __  ________    ____  __________ "
Write-Host -ForegroundColor Yellow "   / __ )/ / / /  _/ /   / __ \/ ____/ __ \"
Write-Host -ForegroundColor Yellow "  / __  / / / // // /   / / / / __/ / /_/ /"
Write-Host -ForegroundColor Yellow " / /_/ / /_/ // // /___/ /_/ / /___/ _, _/ "
Write-Host -ForegroundColor Yellow "/_____/\____/___/_____/_____/_____/_/ |_| "


Remove-Module -Name common
$Error.Clear()
Get-PSSession | Remove-PSSession
Exit-PSSession
[System.GC]::Collect()

exit $global:failed

