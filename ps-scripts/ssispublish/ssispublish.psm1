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

		if($(Confirm-AssemblyInAppDomain -domain $([AppDomain]::CurrentDomain) -assembly "SqlBuildTools.Utils.dll") -ne $true) {

			$ssisBuildPath = $(Get-File -path $(Join-Path $toolsPath "build") -fileName "SqlBuildTools.Utils.dll")

			Write-Host "SSIS Build '$($ssisBuildPath.FullName)'"

			Import-Module $ssisBuildPath.FullName
		}

		try
		{
			$ssisPublisher = New-Object SqlBuildTools.Utils.SSISPublisher
			$ssisPublisher.DeploymentFilePath =  $DeploymentFilePath 
			$ssisPublisher.ServerInstance =  $ServerInstance 
			$ssisPublisher.Catalog =  $Catalog 
			$ssisPublisher.Folder =  $DeploymentFolder 
			$ssisPublisher.ProjectName =  $ProjectName 
			$ssisPublisher.ProjectPassword =  "test"
			$ssisPublisher.EraseSensitiveInfo = $true

			Write-Host "solutionPath: [$($solutionPath)]"
			
			$ssisPublisher.Publish($solutionPath)

			#Publish-SsisDeploymentPackage -DeploymentFilePath $DeploymentFilePath -ServerInstance $ServerInstance -Catalog $Catalog -Folder $DeploymentFolder -ProjectName $ProjectName -ProjectPassword "test"

			return $true
		}
		catch {
			
			Write-Error "SSIS Build Exception: [$($_.Exception.Message)]"
			
			#Write-Host "SSIS Build Stack: [$($_.Exception.StackTrace)]"

			$PSCmdlet.ThrowTerminatingError($PSitem)
		 	return $false
		}
		finally
		{
			Remove-Module "SqlBuildTools.Utils"
		}    
    }
}

Export-ModuleMember -Function 'Invoke-SsisPublish'
