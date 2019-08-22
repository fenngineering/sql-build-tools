
[CmdletBinding()]
param(
    [Parameter(Mandatory = $False)]
    [string]$environmentOverride = $null,
    [Parameter(Mandatory = $False)]
    [string]$testProject = $null,
    [Parameter(Mandatory = $False)]
    [string]$test = $null
)

$here = Split-Path $MyInvocation.MyCommand.Path
$env:PSModulePath = $env:PSModulePath + ";$($here)"
Write-Verbose "build here folder [$($here)]"

Import-Module common -ArgumentList $environmentOverride, "$(Join-Path $(Get-Location) '\build\ps-config')", $True

Write-Pixel -Path "$(Join-Path $toolsPath 'logos\Programming-Sql-icon.png')" 

#1 Set the version of the .semver file from GO's environment vars1
Invoke-SetVersion | Out-Null

Invoke-GetVersion

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
$Error.Clear()
Get-PSSession | Remove-PSSession
Exit-PSSession
[System.GC]::Collect()