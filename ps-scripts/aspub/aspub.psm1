<#
 -----------------------------------------------------------------------------------
.SYNOPSIS  
    This script will provide an interface to Microsoft.AnalysisServices.Deployment.exe
.NOTES
  Version:        1.1
  Author:         Paul Wallington
  Creation Date:  01/10/2016
  Purpose/Change: Initial script development
  -----------------------------------------------------------------------------------
.CHANGE_HISTORY
  -----------------------------------------------------------------------------------
  Date:       Author:           Detail:
  ----------  ----------------  -----------------------------------------------------
  31/08/2017  Ben Chorlton      Added SSASVersion in place of SQLversion


  -----------------------------------------------------------------------------------
#>
[CmdletBinding()]
param()

<#
.SYNOPSIS  
    This will attempt to resolve the path to the Microsoft.AnalysisServices.Deployment executable
#>
function Get-Exe{
    [cmdletbinding()]
        param(
            [Parameter(Mandatory=$True)]
            [string]$SSASVersion
        )
        process{
        $path = $script:defaultASPublishPath

        if(!$path){
            $root =  Get-ItemProperty "hklm:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server\$($SSASVersion)" | 
                        Select -ExpandProperty VerSpecificRootDir
        
            $path = "$(Join-Path $root 'Tools\Binn\ManagementStudio')\Microsoft.AnalysisServices.Deployment.exe"
        }
        return Get-Item $path
    }
}

<#
.SYNOPSIS  
    This will Publish the AS project using Microsoft.AnalysisServices.Deployment  
#>
function Invoke-ASPublish{
    [cmdletbinding()]
    param(      
        [Parameter(Mandatory=$True)]
        [string]$ssasProjectName,
        [Parameter(Mandatory=$True)]
        [string]$SSASVersion        
    )
    process{    

        Write-Output "Building Analysis Services Cube [$($ssasProjectName)]"

        Write-Output "Output [$(Get-BuildDir)]"         
   
        $cmdArgs = @()              
        $cmdArgs += "`"$(Get-BuildDir)\$($ssasProjectName).asdatabase`""
        $cmdArgs += "/s"

        $processFileName = $(Get-Exe -SSASVersion $SSASVersion)

        Import-Module process

        Write-Host $processFileName $cmdArgs
        
        'Running Microsoft.AnalysisServices.Deployment.exe with the following args: [{0} {1}]' -f $processFileName, ($cmdArgs -join ' ') | Write-Verbose 
            $returnCode = $(Invoke-Process -processFileName $processFileName -cmdArgs $cmdArgs)            
        
        return $ReturnCode
    }
}

Export-ModuleMember -Function 'Invoke-ASPublish'
