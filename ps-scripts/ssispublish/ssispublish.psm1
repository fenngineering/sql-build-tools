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
	This will Publish the IS project using the ssispublish library.
#>

function Invoke-SsisPublish{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true)][string]$DeploymentFilePath,
	    [Parameter(Mandatory=$true)][string]$ServerInstance,
	    [Parameter(Mandatory=$true)][string]$Catalog,
	    [Parameter(Mandatory=$true)][string]$DeploymentFolder,
	    [Parameter(Mandatory=$true)][string]$ProjectName,
	    [Parameter(Mandatory=$false)][string]$ProjectPassword = $null
    )
    process{

        Write-Host "Publishing project [$($ProjectName)]"

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
			
			$folderName = Get-ChildItem -Path $buildDir -Filter "ssis-build.DB*" -Directory | Select-Object -first 1

			Copy-Item -Path $folderName.FullName -Destination $packagesDir -Recurse
		}

		$ssisBuildPath = $(Get-File -path $packagesDir -fileName "SsisBuild.Core.dll")

		Write-Host "SSIS Build '$($ssisBuildPath.FullName)'"

		Import-Module $ssisBuildPath.FullName

		try
		{
			Publish-SsisDeploymentPackage -DeploymentFilePath $DeploymentFilePath -ServerInstance $ServerInstance -Catalog $Catalog -Folder $DeploymentFolder -ProjectName $ProjectName -ProjectPassword "test"
			
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

Export-ModuleMember -Function 'Invoke-SsisPublish'
