<#
 -----------------------------------------------------------------------------------
.SYNOPSIS  
    This script will extract a dacpac from the sqlserver using DacFX
.NOTES
	Version:        1.0
	Author:         Andrew J Fenna
	Creation Date:  01/10/2016
	Purpose/Change: Initial script development
  -----------------------------------------------------------------------------------
.CHANGE_HISTORY
  -----------------------------------------------------------------------------------
  Date:       Author:           Detail:
  ----------  ----------------  -----------------------------------------------------

  -----------------------------------------------------------------------------------
#>
[CmdletBinding()]
param(	
    [Parameter(Mandatory=$False)]
    [string]$serverName = $null,
    [Parameter(Mandatory=$True)]
    [string]$databaseName = $null,
    [Parameter(Mandatory=$False)]
    [string]$extractedDacPac = $null
)
Write-Verbose  "Deleting config $deleteConfig..."

$here = Split-Path $MyInvocation.MyCommand.Path
$env:PSModulePath = $env:PSModulePath + ";$($here)"

Import-Module common -Force -ArgumentList $environmentOverride, "$(Join-Path $(Get-Location) '\build\ps-config')", $True

Write-Host "Publishing to environment $environment..."

function Invoke-Extract{
    [cmdletbinding()]
        param()
        process{
            Import-Module dacfx

			if(-not($(Extract-DacPac -sourceServerName $serverName -sourceDatabaseName $databaseName -targetDacPac $extractedDacPac) -eq " 0")) {
                Throw "Failed to extract database [$($databaseName)] from server [$($serverName)]"
            }

        }
}

#Task 1
$global:ToolsDownloaded = $False

Invoke-Extract

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


$Error.Clear()
Get-PSSession | Remove-PSSession
Exit-PSSession
[System.GC]::Collect()