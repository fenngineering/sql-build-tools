<#
.SYNOPSIS  
    This script will provide an interface to SsisBuild    
.NOTES
  Version:        1.0
  Author:         Andrew Fenna
  Creation Date:  19/06/2018
  Purpose/Change: Initial script development
#>
[CmdletBinding()]
param()

<#
.SYNOPSIS  
	This will Build the IS project using the ssisbuild library.
#>

function Invoke-SsisBuild{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$solutionFilePath,
        [Parameter(Mandatory=$True)]
        [string]$projectName
    )
    process{

		$projectFilePath = $(Get-RelativeProjectPath -solutionFilePath $solutionFilePath -projectName $projectName)

        Write-Host "Building project [$($projectFilePath)]"

		foreach ($x in [AppDomain]::CurrentDomain.GetAssemblies() ) {
			Write-Verbose "Assemnbly Loaded [$($x.GetName() )]"
			$ssisBuildLoaded = $x.GetName().ToString().Contains("SsisBuild.Core")
			if($ssisBuildLoaded -eq $True) {
				Write-Verbose "Existing, found [SsisBuild.Core]"
				break
			}
		}

		Write-Verbose "SsisBuildLoaded: $($ssisBuildLoaded)"

		$buildDir = Get-BuildDir

		$packagesDir = Get-PackagesDir

		if( ($ssisBuildLoaded -eq $False) ) { 

			Import-Module nuget

			$installed = $(Install-SsisBuild -packagesPath $buildDir) | Select-Object -first 1

			if($installed.Status -eq "Installed")
			{
				$folderName = "$($installed.Name).$($installed.Version)"

				Copy-Item -Path "$(Join-Path $buildDir $folderName)" -Destination "$(Join-Path $packagesDir $folderName)" -Recurse

				Remove-Module nuget
			}
		}

		$ssisBuildPath = $(Get-File -path $packagesDir -fileName "SsisBuild.Core.dll")

		Write-Host "SSIS Build [$($ssisBuildPath.FullName)]"

		Import-Module $ssisBuildPath.FullName

		try
		{
		
			New-SsisDeploymentPackage -ProtectionLevel "EncryptSensitiveWithPassword" -ProjectPath $projectFilePath -NewPassword "test" -OutputFolder $(Get-BuildDir) -Configuration "Development" -Parameters @{"Project::SourceDBServer" = "."; "Project::SourceDBName" = "SSISDB"}
			return $true
		}
		catch {
			$PSCmdlet.ThrowTerminatingError($PSitem)
			return $false
		}
		finally
		{
			Remove-Module "SsisBuild.Core"
		}
    }
}

Export-ModuleMember -Function 'Invoke-SsisBuild'
