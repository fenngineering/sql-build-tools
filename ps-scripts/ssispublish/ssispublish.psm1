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
        [Parameter(Mandatory=$true)]
		[string]$deploymentFilePath,
	    [Parameter(Mandatory=$true)]
		[string]$serverInstance,
	    [Parameter(Mandatory=$true)]
		[string]$catalog,
	    [Parameter(Mandatory=$true)]
		[string]$deploymentFolder,
	    [Parameter(Mandatory=$true)]
		[string]$projectName,
	    [Parameter(Mandatory=$false)]
		[string]$projectPassword = $null
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
			$ssisPublisher.DeploymentFilePath = $deploymentFilePath 
			$ssisPublisher.ServerInstance = $serverInstance 
			$ssisPublisher.Catalog = $catalog 
			$ssisPublisher.Folder = $deploymentFolder 
			$ssisPublisher.ProjectName =  $projectName 
			$ssisPublisher.ProjectPassword =  $projectPassword
			$ssisPublisher.EraseSensitiveInfo = $true

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
