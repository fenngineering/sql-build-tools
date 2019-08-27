<#
.SYNOPSIS  
    This script will build sql projects that require msbuild    
.NOTES
  Version:        1.0
  Author:         Andrew J Fenna
  Creation Date:  01/10/2016
  Purpose/Change: Initial script development
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$False)]
    [string]$build,
    [Parameter(Mandatory=$False)]
    [string]$environmentOverride = $null,
    [Parameter(Mandatory=$False)]
    [bool]$initalisePackages = $True,
    [Parameter(Mandatory=$False)]
    [bool]$installPackages = $True
)

$here = Split-Path $MyInvocation.MyCommand.Path
$env:PSModulePath = $env:PSModulePath + ";$($here)"
Write-Verbose "build here folder [$($here)]"

Import-Module common -Force -ArgumentList $environmentOverride, "$(Join-Path $(Get-Location) 'ps-config')", $False

$solutionFilePath = $(Get-File -path $solutionPath -fileName "*.sln")

$buildConfiguration = "$($config[$environment].BuildConfiguration)"

if([string]::IsNullOrEmpty($buildConfiguration))
{
	$buildConfiguration = "Release"
}
Write-Host "Building $buildConfiguration configuration to environment $environment..."

function Invoke-CreateVersionClass{
    [cmdletbinding()]
    param()
    process{
        Import-Module EPS -Force -DisableNameChecking
            
        $template = "$(Join-Path $solutionPath "\ps-templates\Version\Version.cs.eps")"

        New-Item "$(Join-Path $solutionPath ".\Version\Version.cs")" -type file -force -value $(Expand-Template -file $template -binding @{ version = $(Invoke-GetVersion) }) | Out-Null

		Remove-Module EPS
    }
}

function Invoke-Build{
    [cmdletbinding()]
    param()
    process{       
        Invoke-BuildDb
        if(-not($environment -eq "QA")){
            Invoke-BuildIs
            Invoke-BuildAs
        }
    }
}

function Invoke-BuildDb{
    [cmdletbinding()]
    param()
    process{

		Import-Module msbuild

        if(-not($(Invoke-MSBuild -solutionFilePath $solutionFilePath.FullName -buildConfig $buildConfiguration) -eq "0")) {
            Throw  'Failed to build solution [$solutionFilePath]'
        }

        Write-Host "Successfully Built [$($solutionFilePath)] Solution " -foregroundcolor "green"

		Remove-Module msbuild
    }
}

function Invoke-BuildIs{
    [cmdletbinding()]
    param()
    process{

		Import-Module ssisbuild

        if ($config.ContainsKey("SsisProjects")) {    

            foreach ($ssisProject in $config["SsisProjects"].GetEnumerator()) {

				Write-Host "solutionPath [$($solutionPath)]"

				if(-not($(Invoke-SsisBuild -solutionFilePath $solutionFilePath.FullName -projectName $ssisProject.ProjectName) -eq "0")) {
					
					Throw "Failed to Build [$($ssisProject.ProjectName)] Project"
				}
				Write-Host "Successfully Built [$($ssisProject.ProjectName)] Project" -foregroundcolor "green"
			} 
		}

		Remove-Module ssisbuild
	}
}

function Invoke-BuildAs{
    [cmdletbinding()]
    param()
    process{

		Import-Module devenv

        if ($config.ContainsKey("SsasProjects")) {    
        
            foreach ($ssasProject in $config["SsasProjects"].GetEnumerator()) {

                Invoke-DevEnv -solutionName $solutionName -projectName $ssasProject.ProjectName

            }
        } 

		Remove-Module devenv
    }
}

function Invoke-DeleteBuildZip{
    [cmdletbinding()]
    param()
    process{

        if(Test-Path $(Join-Path $solutionPath "build.zip")){
            Remove-Item $(Join-Path $solutionPath "build.zip")
			Write-Host "Successfully deleted build.zip" -foregroundcolor "green"
        }
    }
}

function Invoke-CreateBuildZip{
    [cmdletbinding()]
    param()
    process{        
        Import-Module zip
        if(-not($(Invoke-Zip -source $(Join-Path $solutionPath "build") -destination $(Join-Path $solutionPath "build.zip")) -eq 0)) {
			Throw  "Failed to create build.zip"
        }
        Write-Host "Successfully created build.zip" -foregroundcolor "green"
		Remove-Module zip
    }
}

function Copy-IsPacToBuild{
    [cmdletbinding()]
    param(
		[Parameter(Mandatory=$False)]
		[string]$ssisProject
	)
    process{
		$source = $(Join-Path $solutionPath "$($ssisProject)\bin")

		$destination  = $(Join-Path $solutionPath "build\")        

		if((Test-Path -Path $source) -eq $True -and (Test-Path -Path $destination) -eq $True){
			Copy-Item -Path $source -Destination $destination -Recurse -Force
		}
    }
}

function Copy-TemplatesToBuild{
    [cmdletbinding()]
    param()
    process{
		$source = $(Join-Path $solutionPath "ps-templates\")
		$destination  = $(Join-Path $solutionPath "build\")        

		if((Test-Path -Path $source) -eq $True -and (Test-Path -Path $destination) -eq $True)
		{
			Copy-Item -Path $source -Destination $destination -Recurse -Force
		}
    }
}

function Copy-ConfigToBuild{
    [cmdletbinding()]
    param()
    process{
		$source = $(Join-Path $solutionPath "ps-config\")
		$destination  = $(Join-Path $solutionPath "build\")

		if((Test-Path -Path $source) -eq $True -and (Test-Path -Path $destination) -eq $True)
		{
			Copy-Item -Path $source -Destination $destination -Recurse -Force
		}
    }
}

function Invoke-PostBuild{
    [cmdletbinding()]
    param()
    process{
		
		if($config.ContainsKey($environment))
		{
			if($config[$environment].ContainsKey("PostBuild"))
			{
				if($config[$environment].PostBuild.ContainsKey("CopyFiles"))
				{
					foreach ($CopyFile in $config[$environment].PostBuild["CopyFiles"].GetEnumerator()) 
					{
						Write-Verbose "Source $($CopyFile.Source) -> $($CopyFile.Destination)"

							try
						{
							Invoke-CopyFile  -Source $CopyFile.Source -Destination $CopyFile.Destination
						}
						catch {
							$PSCmdlet.ThrowTerminatingError($PSitem)
						}
					}
				}
			}
		}
    }
}

#0 Create the build.zip file for next stages
Invoke-DeleteBuildZip

if($installPackages)
{
	Write-Verbose "Installing Packages"

	Import-Module nuget

	Install-Packages -restoreReferences $True -initalisePackages $initalisePackages -solutionFilePath $solutionFilePath

	Remove-Module nuget
}

#1 Set the version of the .semver file from GO's environment vars1
Invoke-SetVersion | Out-Null

#2 Create the database projects version.cs class.
Invoke-CreateVersionClass

#3 Build the the solution
switch ($build)
{
    "DB" {Invoke-BuildDb}
    "SSIS" {Invoke-BuildIs}
    "SSAS" {Invoke-BuildAs}    
    default {Invoke-Build}
}

#3.1 Copy ps-templates to build structure
Copy-TemplatesToBuild

#3.2 Copy ps-config to build structure
Copy-ConfigToBuild

##4 Create the pre release .semver file
Invoke-CreatePreRelease

#5 Any Post Build Tasks
Invoke-PostBuild

##6 Create the build.zip file for next stages
Invoke-CreateBuildZip

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


#End Session
Remove-Module -Name common
$Error.Clear()
Get-PSSession | Remove-PSSession
Exit-PSSession
[System.GC]::Collect()

#Start-Process PowerShell.exe
##exit