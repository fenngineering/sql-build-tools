[CmdletBinding()]
param(    
    [Parameter(Mandatory=$False)]        
    [bool]$restoreReferences = $True,
    [Parameter(Mandatory=$False)]
    [string]$environmentOverride = $null,
    [Parameter(Mandatory=$False)]        
    [bool]$initalisePackages = $False,
    [Parameter(Mandatory=$False)]
    [string]$packageName = $null
)

$here = Split-Path $MyInvocation.MyCommand.Path
$env:PSModulePath = $env:PSModulePath + ";$($here)"

Import-Module common -Force -ArgumentList $environmentOverride, "$(Join-Path $(Get-Location) '\ps-config')"

$solutionFilePath = $(Get-File -path $solutionPath -fileName "*.sln")

Import-Module nuget

#1 Installs the nuget packages from the \.nuget\packages.config

Install-Packages -restoreReferences $restoreReferences -initalisePackages $initalisePackages -packageName $packageName -solutionFilePath $solutionFilePath

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