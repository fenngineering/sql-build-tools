<#
 -----------------------------------------------------------------------------------
.SYNOPSIS  
    This script will publish sql projects that require DacFx
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
  31/08/2017  Ben Chorlton      Added SSASVersion in place of SQLversion


  -----------------------------------------------------------------------------------
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $False)]
    [string]$publish ,
    [Parameter(Mandatory = $False)]
    [string]$isProject = $null,
    [Parameter(Mandatory = $False)]
    [string]$environmentOverride = $null,
    [Parameter(Mandatory = $False)]
    [bool]$installReferencedIsPacs = $False,
    [Parameter(Mandatory = $False)]
    [string]$extractedDacPacOverride = $null,
    [Parameter(Mandatory = $False)]
    [bool]$autoAcceptOverride = $false,
    [Parameter(Mandatory = $False)]
    [bool]$generateDeployScript = $false
)

Write-Verbose  "Deleting config $deleteConfig..."

$here = Split-Path $MyInvocation.MyCommand.Path
$env:PSModulePath = $env:PSModulePath + ";$($here)"

Import-Module common -Force -ArgumentList $environmentOverride, "$(Join-Path $(Get-Location) '\build\ps-config')", $True

Write-Host "Publishing to environment $environment..."

$isProduction = $config[$environment].IsProductionEnvironment
if ([string]::IsNullOrEmpty($isProduction))
{
    $isProduction = $False
}
Write-Host "Is this is a production environment? [$($isProduction)]"

function Invoke-Publish
{
    [cmdletbinding()]
    param()
    process
    {
        Invoke-PublishDb
        Invoke-PublishIs
        Invoke-PublishAs
    }
}

<#
.SYNOPSIS  
#>
function Invoke-PublishDb
{
    [cmdletbinding()]
    param()
    process
    {

        $global:sqlCommandVariables = $config["SqlCmdVaribles"]

        Import-Module dacfx -DisableNameChecking

        if ($isProduction)
        {

            # check staging db exists, if it does driop it
            Invoke-Sql -dataSource $config["Staging"].Server -databaseName "master" -query "IF DB_ID('$($config["Staging"].Database)') IS NOT NULL  BEGIN ALTER DATABASE [$($config["Staging"].Database)] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$($config["Staging"].Database)]; END"

            if ($autoAcceptOverride -eq $false)
            {

                $confirmation = Read-Host "Are you sure you want to create release scripts for production? [y/n]"

                while ($confirmation -ne "y")
                {

                    if ($confirmation -eq 'n') {exit}

                    $confirmation = Read-Host "Are you sure you want to create release scripts for production? [y/n]"
                }
            }
        }

        if ($config.ContainsKey("DbProjects"))
        {
			
            foreach ($DbProject in $config["DbProjects"].GetEnumerator())
            {

                if ($DbProject.PublishDb)
                {

                    $sourceDacPac = "$(Join-Path $solutionPath 'build\')$($DbProject.ProjectName).dacpac"
                    $targetDatabaseName = $DbProject.DatabaseName

                    if (-not(Test-Path $sourceDacPac))
                    {
                        Write-Host "Dacpac not specified [$($sourceDacPac)], please build solution." -foregroundcolor "red"
                        return 1
                    }
                    elseif ($targetDatabaseName -eq $null)
                    {
                        Write-Error "Database not specified, please check config.psd1."
                        return 1
                    }
                    else
                    {                    
						
                        if ($isProduction)
                        {
                            if ($confirmation -eq "y" -or $autoAcceptOverride)
                            {
                                Import-Module zip
                                Write-Host "Publishing [$($sourceDacPac)] to Staging Server [$($config["Staging"].Server)]" -foregroundcolor "White"
								
                                # Remove Post Deployment scripts 
                                Write-Host "Removing PostDeployment Scripts from [$($sourceDacPac)]" -foregroundcolor "White"
                                Invoke-ZipDeletePart -zipfilepath $sourceDacPac -zipPart "/postdeploy.sql" | Out-Null
                    
                                Remove-Module -name zip
                                if ($(Publish-DacPac -targetServerName $config["Staging"].Server -sourceDacPac $sourceDacPac -targetDatabaseName $config["Staging"].Database -includeCompositeObjects $false -generateDeployScript $generateDeployScript -dataPath $config["Staging"].Default.DataPath -logPath $config["Staging"].Default.LogPath) -ne $True)
                                {
                                    Throw "Failed to deploy [$($sourceDacPac)]"
                                }
                            }

                        }
                        else
                        {

                            if ($(Publish-DacPac -targetServerName $config[$environment].Server -sourceDacPac $sourceDacPac -targetDatabaseName $targetDatabaseName -includeCompositeObjects $false -generateDeployScript $generateDeployScript) -ne $True)
                            {
                                Throw "Failed to deploy [$($sourceDacPac)]"
                            }
                        }
                    }
                }
            }
			`
            if ($isProduction)
            {

                if ($confirmation -eq "y" -or $autoAcceptOverride)
                {

                    if (-$extractedDacPacOverride -ne [string]$null )
                    {
                        $extractedDacPac = $extractedDacPacOverride
                    }
                    else
                    {
                        $extractedDacPac = $config[$environment].ExtractedDacPac

                        ## 1) extracts the release dacpac from the staging server

                        $releaseDacPac = "$(Join-Path $solutionPath 'build\')Release.dacpac"

                        Export-DacPac -sourceServerName $config["Staging"].Server -sourceDatabaseName $config["Staging"].Database -targetDacPac $releaseDacPac
					
                        $deployTemplate = "$(Join-Path $toolsPath "ps-templates\SqlScripts\DeployScript.eps")"
					
                        Import-Module EPS -Force -DisableNameChecking      					
                        Import-Module git
                    }
                }

                ## 2) producte the deployment script

                $deployScript = $(Export-DeployScript -targetDatabaseName $targetDatabaseName -sourceDacPac $releaseDacPac -targetDacPac $extractedDacPac -dropObjectsNotInSource $False -dataPath $config[$environment].Default.DataPath -logPath $config[$environment].Default.LogPath)

                New-Item "$(Join-Path $solutionPath "$($targetDatabaseName)_DeployScript.sql")" -type file -force -value $(Expand-Template -file $deployTemplate -binding @{ databaseName = $targetDatabaseName; version = $(Invoke-GetVersion); config = $config; DeployScript = $deployScript; })

                ## 3) produce the rollback script if required 

                if ($extractedDacPac)
                {
                    ## compare staging with the extracted dacpac
                    $rollbackScript = $(Export-DeployScript -targetDatabaseName $targetDatabaseName -sourceDacPac $extractedDacPac -targetDacPac $releaseDacPac -dropObjectsNotInSource $True -dataPath $config[$environment].Default.DataPath -logPath $config[$environment].Default.LogPath)
                }
                else
                {     
                    $rollbackScript = $(Extract-DropDbScript -targetDatabaseName $targetDatabaseName -sourceDacPac $releaseDacPac)
                }

                New-Item "$(Join-Path $solutionPath "$($targetDatabaseName)_RollbakScript.sql")" -type file -force -value $(Expand-Template -file $deployTemplate -binding @{ databaseName = $targetDatabaseName; version = $(Invoke-GetVersion); config = $config; DeployScript = $rollbackScript; }) 
			
                Remove-Module -name EPS
                Remove-Module -name git

            }
        }

        Remove-Module -Name dacfx

    }
}

function Invoke-PublishIs
{
    [cmdletbinding()]
    param()
    process
    {

        $isPacDir = $(Join-Path $solutionPath "build")

        if ($config.ContainsKey("SsisProjects"))
        {

            if ($installReferencedIsPacs)
            {        

                Write-Output "Installing Packages for IsPacs"

                if (Test-Path $(Join-Path $solutionPath ".nuget\packages.config"))
                {
                    Import-Module nuget
                    Install-Packages -restoreReferences $False -initalisePackages $False
                    $useNugetPackage = $True                
                }

                $nugetIsPac = "$($ssisProject.ProjectName).ispac"

                Get-ChildItem  $(Get-PackagesDir) -Filter "ispacs" -Recurse -Directory | 
                    Foreach-Object {
                            
                    if (!(Test-Path -Path $isPacDir)) {New-Item $isPacDir -Type Directory}
                            
                    Get-ChildItem  $_.FullName  -Filter "*.ispac" -Recurse| 
                        Foreach-Object {
                            
                        Copy-Item $_.FullName -Destination $isPacDir
                    }
                }

                $build = "$(Join-Path $solutionPath "build")"
                $psTemplates = "$(Join-Path $build ".\ps-templates")"

                Get-ChildItem  $(Get-PackagesDir) -Filter "ps-templates" -Recurse -Directory | 
                    Foreach-Object {

                    if (!(Test-Path -Path $psTemplates)) {New-Item $psTemplates -Type Directory}
                            
                    Copy-Item $_.FullName -Destination $build -Force -Recurse
                }

            }
            Import-Module ssispublish

            foreach ($ssisProject in $config["SsisProjects"].GetEnumerator())
            {

                if ($isProduction)
                {

                    if ($autoAcceptOverride -eq $false)
                    {

                        $confirmation = Read-Host "Are you sure you want to publish ssis [$($ssisProject.ProjectName)] to production? [y/n]"
                        while ($confirmation -ne "y")
                        {
                            if ($confirmation -eq 'n') {exit}
                            $confirmation = Read-Host "Are you sure you want to publish ssis [$($ssisProject.ProjectName)] to production? [y/n]"
                        }
                    }
                }
                else
                {
                    $confirmation = "y"
                }

                if ($confirmation -eq "y" -or $autoAcceptOverride)
                {

                    if ([string]::IsNullOrEmpty($isProject) -or ($ssisProject.ProjectName -eq $isProject))
                    {

                        $isPac = "$($isPacDir)\$($ssisProject.ProjectName).ispac"

                        Invoke-UnzipIspac -ssisProjectName $ssisProject.ProjectName

                        Invoke-CreateIsProjectParams -ssisProjectName $ssisProject.ProjectName 

                        Invoke-ZipIspac -ssisProjectName $ssisProject.ProjectName

                        Invoke-CreateIsFolder -ssisFolderName $ssisProject.FolderName

                        if (-not($(Invoke-SsisPublish -DeploymentFilePath $isPac -ServerInstance $config[$environment].SSIS.Server -Catalog "SSISDB" -DeploymentFolder $ssisProject.FolderName -ProjectName $ssisProject.ProjectName) -eq " 0"))
                        {
                            Throw  "Failed to deploy [$($isPac)]"
                        }

                        Write-Host "Successfully deployed [$isPac]" -foregroundcolor "green"
                    }
                }
            }

            Remove-Module -Name ssispublish
        }
    }
}

function Invoke-PublishAs
{
    [cmdletbinding()]
    param()
    process
    {
        if ($config.ContainsKey("SsasProjects"))
        {    

            Import-Module aspub

            foreach ($ssasProject in $config.SsasProjects)
            {
                Invoke-CreateAsDeploymentTargets -ssasProjectName $ssasProject.ProjectName

                Invoke-CreateAsDeploymentOptions -ssasProjectName $ssasProject.ProjectName      				
				
                if (-not($(Invoke-ASPublish -ssasProjectName $ssasProject.ProjectName -sqlVersion $config.SqlVersion) -eq " 0"))
                {
                    Throw  "Failed to deploy project [$($ssasProject)]"
                }                                      
            }

            Remove-Module -name aspub
        } 
    }
}

function Invoke-CreateAsDeploymentTargets
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $True)]
        [string]$ssasProjectName
    )
    process
    {
        Import-Module EPS -Force -DisableNameChecking
    
        $projectDeploymentTargetsTemplate = "$(Join-Path $solutionPath "\build\ps-templates\SsasDeployment\deploymenttargets.eps")"            

        If (-Not (Test-path $projectDeploymentTargetsTemplate))
        {
            Write-Output "$projectDeploymentTargetsTemplate does not exist."
            Continue
        }

        New-Item "$(Join-Path $solutionPath "build\$($ssasProjectName).deploymenttargets")" -type file -force -value $(Expand-Template -file $projectDeploymentTargetsTemplate -binding @{ config = $config; environment = $environment }) | Out-Null
  
        Remove-Module -name EPS
    }
}

function Invoke-CreateAsDeploymentOptions
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $True)]
        [string]$ssasProjectName
    )
    process
    {
        Import-Module EPS -Force -DisableNameChecking
    
        $projectDeploymentOptionsTemplate = "$(Join-Path $solutionPath "\build\ps-templates\SsasDeployment\deploymentoptions.eps")"            

        if (-Not (Test-path $projectDeploymentOptionsTemplate))
        {
            Write-Output "$projectDeploymentOptionsTemplate does not exist."
            Continue
        }

        New-Item "$(Join-Path $solutionPath "build\$($ssasProjectName).deploymentoptions")" -type file -force -value $(Expand-Template -file $projectDeploymentOptionsTemplate -binding @{ config = $config; environment = $environment }) | Out-Null
        
        Remove-Module -name EPS
    }
}

function Invoke-UnzipIspac
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $True)]
        [string]$ssisProjectName
    )
    process
    {
        Import-Module zip
                    
        $source = "$(Join-Path $solutionPath "build")\$($ssisProjectName).ispac"
        $destination = "$(Join-Path $solutionPath "build")\$($ssisProjectName)"

        if (-not($(Invoke-Unzip -source $source -destination $destination) -eq 0))
        {
            Throw  "Failed to unzip [$($source)]"
        }

        Remove-Module -name zip
    }
}

function Invoke-CreateIsProjectParams
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $True)]
        [string]$ssisProjectName
    )
    process
    {
        Import-Module EPS -Force -DisableNameChecking
    
        $projectParamsTemplate = "$(Join-Path $solutionPath "\build\ps-templates\SsisProjectParams\$($ssisProjectName).eps")"        
            
        if (-Not (Test-path $projectParamsTemplate))
        {
            Write-Output "$projectParamsTemplate does not exist."
        }

        $newParams = New-Item "$(Join-Path $solutionPath "build\$($ssisProjectName)\Project.params")" -type file -force -value $(Expand-Template -file $projectParamsTemplate -binding @{ config = $config; environment = $environment; Env = $Env }) | Out-Null
			
        Remove-Module -name EPS
    }
}

function Invoke-ZipIspac
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $True)]
        [string]$ssisProjectName
    )
    process
    {            
        Import-Module zip

        $source = "$(Join-Path $solutionPath "build")\$($ssisProjectName)"
        $destination = "$(Join-Path $solutionPath "build")\$($ssisProjectName).ispac"

        if (-not($(Invoke-Zip -source $source -destination $destination) -eq 0))
        {
            Throw  "Failed to zip [$($source)]"
        }     

        Remove-Module -name zip
    }
}

function Invoke-CreateIsFolder
{
    [cmdletbinding()]
    param(            
        [Parameter(Mandatory = $True)]
        [string]$ssisFolderName
    )
    process
    {
        Import-Module EPS -Force -DisableNameChecking
				
        $ssisFolderTemplate = "$(Join-Path $toolsPath "ps-templates\SqlScripts\CreateIsFolder.eps")"

        $createFolderSql = $(Expand-Template -file $ssisFolderTemplate -binding @{ config = $config; ssisFolderName = $ssisFolderName})

        if ($(Invoke-Sql -dataSource $config[$environment].SSIS.Server -databaseName "master" -query $createFolderSql) -eq $False)
        {
            
            Throw "******** Creating IS Folder Failed ********"
        }

        Remove-Module -name EPS
    }
}

function Invoke-PostDeployment
{
    [cmdletbinding()]
    param()
    process
    {

        if ($isProduction)
        {
            $confirmation = Read-Host "Are you sure you want to publish execute post deployment tasks to production? [y/n]"

            if ($autoAcceptOverride -eq $false)
            {

                while ($confirmation -ne "y")
                {
                    if ($confirmation -eq 'n') {exit}
                    $confirmation = Read-Host "Are you sure you want to publish execute post deployment tasks to production? [y/n]"
                }
            }
        }
        else
        {
            $confirmation = "y"
        }

        if ($confirmation -eq "y" -or $autoAcceptOverride)
        {

            if ($config.ContainsKey($environment))
            {
                if ($config[$environment].ContainsKey("PostDeployment"))
                {
                    if ($config[$environment].PostDeployment.ContainsKey("CreateFolders"))
                    {
                        foreach ($folderName in $config[$environment].PostDeployment["CreateFolders"].GetEnumerator())
                        {
                            Set-Location -Path $solutionPath

                            $folderName.Path = "$(Get-PathFromKeyInConfig -keyInConfig $folderName.Path)"

                            try
                            {
                                Invoke-CreateFolder -FolderName $folderName.path -Server $($config[$environment].SSIS.Server)
                            }
                            catch
                            {
                                $PSCmdlet.ThrowTerminatingError($PSitem)
                            }
                        }
                    }

                    if ($config[$environment].PostDeployment.ContainsKey("CopyFiles"))
                    {
                        foreach ($CopyFile in $config[$environment].PostDeployment["CopyFiles"].GetEnumerator())
                        {
                            Set-Location -Path $solutionPath

                            $CopyFile.Destination = "$(Get-PathFromKeyInConfig -keyInConfig $CopyFile.Destination )"

                            try
                            {
                                Write-Verbose "Resolving Path [$($CopyFile.Source)]..."

                                $absolutePath = $(Resolve-Path -Path $CopyFile.Source)

                                Write-Host "Copying file [$($absolutePath)] >> [$($CopyFile.Destination)] on Server [$($config[$environment].SSIS.Server)]"
                                Invoke-CopyFile -Source $absolutePath -Destination $CopyFile.Destination -Server $($config[$environment].SSIS.Server)

                            }
                            catch
                            {
                                $PSCmdlet.ThrowTerminatingError($PSitem)
                            }
                        }
                    }

					if ($config[$environment].PostDeployment.ContainsKey("ApplyTemplates"))
                    {
                        foreach ($Template in $config[$environment].PostDeployment["ApplyTemplates"].GetEnumerator())
                        {
                            Set-Location -Path $solutionPath
                            
                            $Template.Destination = "$(Get-PathFromKeyInConfig -keyInConfig $Template.Destination )"

                            try
                            {
    
								$Template.Template = $(Resolve-Path -Path $Template.Template)
            
								if (-Not (Test-path $Template.Template))
								{
									Write-Output "$Template.Template does not exist."
								}

								Invoke-ApplyTemplate -Source $Template.Template -Destination $Template.Destination -Binding @{ config = $config; environment = $environment } -Server $($config[$environment].SSIS.Server)
								
                            }
                            catch
                            {
                                $PSCmdlet.ThrowTerminatingError($PSitem)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Task 1

switch ($publish)
{
    "DB" {Invoke-PublishDb}
    "SSIS" {Invoke-PublishIs}
    "SSAS" {Invoke-PublishAs}    
    default {Invoke-Publish}
}

#Task 2 Any Post Deployment Tasks
Invoke-PostDeployment | Out-Null

#End Session
Remove-Module -Name common
$Error.Clear()
Get-PSSession | Remove-PSSession
Exit-PSSession
[System.GC]::Collect()

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