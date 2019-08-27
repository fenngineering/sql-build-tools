<#
.SYNOPSIS  
    This script will provide an interface to msbuild
.NOTES
  Version:        1.0
  Author:         Andrew J Fenna
  Creation Date:  01/10/2016
  Purpose/Change: Initial script development
#>

[CmdletBinding()]
param()

<#
.SYNOPSIS  
	This will return the path to msbuild.exe. If the path has not yet been set
	then the highest installed vers
	ion of msbuild.exe will be returned.
#>
function Get-MsBuildExe{
    [cmdletbinding()]
        param()
        process{
	    $path = $script:defaultMSBuildPath
		
		if(!$path){
			# use vswhere to locate the vs2017 installation folder	
			$vswhere = Get-VsWhere

			$path = & $vswhere -latest -version $vsWhereVersion -products * -requires Microsoft.Component.MSBuild -property installationPath

			if ($path) {

				$path = $(Get-File -path $path -fileName "MSBuild.exe") | Select-Object -Last 1

				if (Test-Path $path.FullName) {

					Write-Verbose ("found msbuild [($path)]")
					return $path
				}
			}
		}	
		if(!$path){
			$path =  Get-ChildItem "hklm:\SOFTWARE\Microsoft\MSBuild\ToolsVersions\" | 
						Sort-Object {[double]$_.PSChildName} -Descending | 
						Select-Object -First 1 | 
						Get-ItemProperty -Name MSBuildToolsPath |
						Select -ExpandProperty MSBuildToolsPath

			return Get-Item (Join-Path -Path $path -ChildPath 'msbuild.exe')
		}
    }
}

<#
.SYNOPSIS  
	This will build the solution 
#>
function Invoke-MSBuild{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$solutionFilePath,
        [Parameter(Mandatory=$True)]
        [string]$buildConfig
    )
    process{    

		## VS 2017 create ignore file for unsupported projects

		try {

			Invoke-CreateExcludeProjectsFile $solutionFilePath
        
			Write-Host "Building solution [$($solutionFilePath)]"

			$cmdArgs = @()
			$cmdArgs += "`"$($solutionFilePath)`""
			$cmdArgs += "/p:Configuration=$($buildConfig)"
			$cmdArgs += "/p:OutputPath=`"$(Get-BuildDir)`""
			$cmdArgs += "/verbosity:quiet"
			$cmdArgs += "/nologo"
			$cmdArgs += "/target:Clean;Build"

			$processFileName = (Get-MsBuildExe).FullName

			Import-Module process

			'Running msbuild with the following args: [{0} {1}]' -f $processFileName, ($cmdArgs -join ' ') | Write-Host 
			   $returnCode = $(Invoke-Process -processFileName $processFileName -cmdArgs $cmdArgs)

			Write-Verbose "MsBuild Return Code [$($returnCode)]"

			Invoke-RemoveExcludeProjectsFile $solutionFilePath

		} catch {
			$PSCmdlet.ThrowTerminatingError($PSitem)
			return $False
		}

        return $True
    }
}

function Get-DataToolsMsBuildDir{
    [cmdletbinding()]
    param()
    process{

		Import-Module nuget

		if($(Install-DacBuilderNuget -packagesPath $(Get-PackagesDir)) -eq $False) {
            Write-Error "Unable to install DacBuilderNuget."
            return  $False
        }

		return $(Get-File -path $(Get-PackagesDir) -fileName "Microsoft.Data.Tools.Schema.SqlTasks.targets").Directory.FullName
    }
}

function Get-DataToolsMsTestDir{
    [cmdletbinding()]
    param()
    process{

		Import-Module nuget

		if($(Install-MsTestNuget -packagesPath $(Get-PackagesDir)) -eq $False) {
            Write-Error "Unable to install MsTestNuget."
            return  $False
        }

		return $(Get-File -path $(Get-PackagesDir) -fileName "Microsoft.Data.Tools.Schema.Sql.UnitTesting.dll").Directory.FullName
    }
}

function Initialize-OutputFolder{
    [cmdletbinding()]
    param()
    process{
        $outputFolder = Get-BuildDir

        if(Test-Path $outputFolder){
            'Deleting output folder [{0}]' -f $outputFolder | Write-Verbose
            Remove-Item $outputFolder -Recurse -Force
        }
    }
}

function Invoke-CreateExcludeProjectsFile{
    [cmdletbinding()]
    param(	
        [Parameter(Mandatory=$True)]
        [string]$solutionFilePath
	)
    process{
        $excludeProjectsTemplate = "$(Join-Path $toolsPath "ps-templates\MSBuild\ExcludeProjects.eps")"

		$solutionName = [IO.Path]::GetFileName($solutionFilePath)

		New-Item "$(Join-Path "$($solutionPath)" "after.$($solutionName).targets")" -type file -force -value $(Expand-Template -file $excludeProjectsTemplate ) | Out-Null	
    }
}

function Invoke-RemoveExcludeProjectsFile{
    [cmdletbinding()]
    param(	
        [Parameter(Mandatory=$True)]
        [string]$solutionFilePath
	)
    process{
		$solutionName = [IO.Path]::GetFileName($solutionFilePath)

		Remove-Item "$(Join-Path "$($solutionPath)" "after.$($solutionName).targets")"| Out-Null	
    }
}

function Get-DataToolsMsTestDir{
    [cmdletbinding()]
    param()
    process{

		Import-Module nuget
        
		$packagesPath = Get-PackagesDir

		if($(Install-MsTestNuget -packagesPath $packagesPath) -eq $False) {
            Write-Error "Unable to install MsTestNuget."
            return  $False
        }

		return $(Get-File -path $packagesPath -library "Microsoft.Data.Tools.Schema.Sql.UnitTesting.dll").Directory.FullName
    }
}

Export-ModuleMember -Function 'Invoke-MSBuild'