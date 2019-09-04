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
        [string]$projectName,
        [Parameter(Mandatory=$True)]
        [string]$protectionLevel,
        [Parameter(Mandatory=$False)]
        [string]$password

    )
    process{

		$projectFilePath = $(Get-RelativeProjectPath -solutionFilePath $solutionFilePath -projectName $projectName)

        Write-Host "Building project [$($projectFilePath)]"

		if($(Confirm-AssemblyInAppDomain -domain $([AppDomain]::CurrentDomain) -assembly "SqlBuildTools.Utils.dll") -ne $true) {

			$ssisBuildPath = $(Get-File -path $(Join-Path $toolsPath "build") -fileName "SqlBuildTools.Utils.dll")

			Write-Host "SSIS Build '$($ssisBuildPath.FullName)'"

			Import-Module $ssisBuildPath.FullName
		}

		try
		{		
			$ssisBuilder = New-Object SqlBuildTools.Utils.SSISBuilder 
			$ssisBuilder.ProjectPath = $projectFilePath 
			$ssisBuilder.ProtectionLevel = $protectionLevel 
			$ssisBuilder.Password = $password
			$ssisBuilder.OutputFolder = $(Get-BuildDir) 
			$ssisBuilder.Configuration = "Development" 
			$ssisBuilder.Parameters = @{"Project::SourceDBServer" = "."; "Project::SourceDBName" = "SSISDB"}

			$ssisBuilder.Build($solutionPath)

			return $true
		}
		catch {
			$PSCmdlet.ThrowTerminatingError($PSitem)
			return $false
		}
		finally
		{
			Remove-Module "SqlBuildTools.Utils"
		}
    }
}

Export-ModuleMember -Function 'Invoke-SsisBuild'
