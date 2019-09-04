<#
.SYNOPSIS  
    This script will provide an interface to vstest     
.NOTES
  Version:        1.0
  Author:         Andrew J Fenna
  Creation Date:  01/10/2016
  Purpose/Change: Initial script development
#>
[CmdletBinding()]
param()

$here = Split-Path -Parent $MyInvocation.MyCommand.Path

function Get-VsTestExe {
    [cmdletbinding()]
    param()
    process {
        $path = $script:defaultMSTestdPath

		if(!$path){
			# use vswhere to locate the vs2017 installation folder	
			$vswhere = Get-VsWhere
			# local installed visual studio 2017
			$path = & $vswhere -latest -version $vsWhereVersion -products * -requires Microsoft.VisualStudio.PackageGroup.TestTools.Core -property installationPath
			
			if (!$path) {
				# if not exists use TestAgent config
				$path = & $vswhere -latest -version $vsWhereVersion -products * -requires Microsoft.VisualStudio.ComponentGroup.TestTools.TestAgent  -property installationPath
			}
			if ($path) {

				$path = $(Get-File -path $path -fileName "vstest.console.exe") | Select-Object -Last 1

				if (Test-Path $path.FullName) {

					Write-Verbose ("found vstest.console [($path)]")
					return $path
				}
			}
		}
    }
}

function Invoke-CreateRunSettings {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $True)]
        [string]$testFile,
        [Parameter(Mandatory = $True)]
        [string]$testSettings,
        [Parameter(Mandatory = $True)]
        [string]$cpuArchitecture
    )
    process {
        if ($config[$environment].Testing -ne $null) {
            Import-Module EPS -Force -DisableNameChecking
            $settingsTemplate = "$(Join-Path $toolsPath "ps-templates\SqlUnitTesting\RunSettings.eps")"
            $settingsFile = "$($testFile).runsettings" 
			
			Write-Verbose "Test File [$($testFile)]"
			Write-Verbose "Run Settings [$($settingsFile)]"
			Write-Verbose "Run Settings Template [$($settingsTemplate)]"

			Remove-Module EPS
            return $(New-Item $settingsFile -type file -force -value $(Expand-Template -file $settingsTemplate -binding @{ testSettings = $testFile; cpuArchitecture = $cpuArchitecture }))
        }
        return $null
    }
}

function Invoke-VSTest {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $True)]
        [string]$testFilePath,
        [Parameter(Mandatory = $False)]
        [string]$testSettings,
        [Parameter(Mandatory = $True)]
        [string]$testResultsDir,
        [Parameter(Mandatory = $False)]
        [string]$test,
        [Parameter(Mandatory = $True)]
        [string]$cpuArchitecture
    )
    process {    
   
        Write-Verbose "Testing fixture [$($testFilePath)]"
        Write-Verbose "Testing settings [$($testSettings)]"

		$runSettings = $(Invoke-CreateRunSettings -testFile $testFilePath -testSettings $testSettings -cpuArchitecture $cpuArchitecture)

		$testResultsName = "$([System.IO.Path]::GetFileNameWithoutExtension($testFilePath))_$(Get-Date -f yyyy-MM-dd-hh-mm-ss).trx"

        $cmdArgs = @()
        $cmdArgs += "`"$testFilePath`""
        $cmdArgs += "/ResultsDirectory:`"$testResultsDir`""       
        $cmdArgs += "/Logger:trx;LogFileName=`"$testResultsName`""
        #$cmdArgs += "/detail:`"errormessage`""
        #$cmdArgs += "/nologo"

        if ($testSettings -ne $null) {
            $cmdArgs += "/Settings:`"$runSettings`""
        }
        
        if (-not([string]::IsNullOrEmpty($test))) {
            $cmdArgs += "/Tests:`"$test`""
        }        

        $processFileName = (Get-VsTestExe).FullName

        Import-Module process
  
        'Running vstest with the following args: [vstest.console.exe {0}]' -f ($cmdArgs -join ' ') | Write-Host
			$returnCode = $(Invoke-Process -processFileName $processFileName -cmdArgs $cmdArgs -captureConsoleOut $True)

		Write-Verbose "vstest returnCode [$($returnCode)["

		$resultsFile = $(Get-File -path $testResultsDir -fileName $testResultsName )
        
		if($resultsFile -ne $null) {
			if (Test-Path($resultsFile.FullName)) {
				
				$global:TestsRun = $true

				$results = [xml](Get-Content $resultsFile.FullName)
				$outcome = $results.TestRun.ResultSummary.outcome

				$failed = [int]$results.TestRun.ResultSummary.Counters.failed
            
				$global:failed = $global:failed + $failed

				Write-Verbose "Failed Tests [$failed]"
				Write-Verbose "Total Failed Tests [$($global:failed)]"

				if ($returnCode -eq 1) {            
					Write-Host "Test fixture [$($testFilePath)] $($outcome)" -foregroundcolor "red"
				}
				else {
					Write-Host "Test fixture [$($testFilePath)] $($outcome) Successfully" -foregroundcolor "green"
				}
			} 
		}
        else {
            Write-Host "Test fixture [$($testFilePath)] did not run" -foregroundcolor "yellow"
        }

		Remove-Module -name process
    }    
}

Export-ModuleMember -Function 'Invoke-VSTest'