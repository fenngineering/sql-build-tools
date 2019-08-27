<#
.SYNOPSIS  
    This script will provide an interface to ISDeploymentWizard.exe     
.NOTES
  Version:        1.0
  Author:         Andrew J Fenna
  Creation Date:  01/10/2016
  Purpose/Change: Initial script development
#>
[CmdletBinding()]
param()

function Get-IsPubExe{
    [cmdletbinding()]
        param(
            [Parameter(Mandatory=$True)]
            [string]$sqlVersion
        )
        process{
	    $path = $script:defaultISPublishPath

	    if(!$path){
	        $root =  Get-ItemProperty "hklm:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server\$($sqlVersion)" | 
                        Select -ExpandProperty VerSpecificRootDir
        
            $path = "$(Join-Path $root 'DTS\Binn')\ISDeploymentWizard.exe"
	    }

        return Get-Item $path
    }
}

function Invoke-ISPublish{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$isPac,
        [Parameter(Mandatory=$True)]
        [string]$destinationServer,
        [Parameter(Mandatory=$True)]
        [string]$databaseName,
        [Parameter(Mandatory=$True)]
        [string]$folderName,
        [Parameter(Mandatory=$True)]
        [string]$projectName,
        [Parameter(Mandatory=$True)]
        [string]$sqlVersion
    )
    process{    

        Write-Verbose "SourcePath [$isPac]"
   
        Write-Verbose "DestinationServer [$destinationServer]"

        Write-Verbose "DatabaseName [$databaseName]"
    
        Write-Verbose "FolderName [$folderName]"

        Write-Verbose "ProjectName [$projectName]"

        Write-Verbose "SqlVersion [$sqlVersion]"
   
        $cmdArgs = @()
        $cmdArgs += "/Silent"
        $cmdArgs += "/SourcePath:`"$($isPac)`""
        $cmdArgs += "/DestinationServer:$($destinationServer)"
        $cmdArgs += "/DestinationPath:/$($databaseName)/$($folderName)/$($projectName)"

        $processFileName = $(Get-IsPubExe -sqlVersion $sqlVersion)

        Import-Module process
        
        "Running ISDeploymentWizard with the following args: [$($processFileName) {0}]" -f ($cmdArgs -join ' ') | Write-Host 
            $ReturnCode = Invoke-Process -processFileName $processFileName -cmdArgs $cmdArgs
        
        return $ReturnCode
    }
}
Export-ModuleMember -Function 'Invoke-ISPublish'