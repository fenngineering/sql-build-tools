[CmdletBinding()]
param(
    [Parameter(Mandatory=$False)]
    [bool]$createRelease = $False,
    [Parameter(Mandatory=$False)]
    [string]$environmentOverride = $null
)
$here = Split-Path $MyInvocation.MyCommand.Path
$env:PSModulePath = $env:PSModulePath + ";$($here)"

Import-Module common -Force -ArgumentList $environmentOverride, "$(Join-Path $(Get-Location) '\build\ps-config')", $True

Import-Module nuget

if($createRelease -eq $True){
	Invoke-CreateRelease
}

New-Package -solutionName $config.SolutionName

Push-Package -buildPath $(Join-Path $solutionPath "\build")

Compress-Archive -Path build\.semver -Update -DestinationPath build.zip

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