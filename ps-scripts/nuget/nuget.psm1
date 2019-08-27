<#
.SYNOPSIS  
    This script will provide an interface to nuget     
.NOTES
  Version:        1.0
  Author:         Andrew J Fenna
  Creation Date:  01/10/2016
  Purpose/Change: Initial script development
#>

[CmdletBinding()]
param()

<#
.SYNOPSIS
    If nuget is in the tools
    folder then it will be downloaded there.
#>
function Get-NugetExe(){
    [cmdletbinding()]
    param()
    process{
        $toolsDir = New-Item -Force -ItemType directory -Path "$($toolsPath)\ps-tools\"
        
        # Make sure we have Nuget.exe
		$nugetFolder = Join-Path $toolsDir "Nuget"

		$nugetExe = Join-Path $nugetFolder "Nuget.exe"

		if (-not (Test-Path $nugetFolder)) {
			New-Item $nugetFolder -ItemType Directory
		}

		if (-not (Test-Path $nugetExe)) {
			$ProgressPreference = "SilentlyContinue"
			Invoke-WebRequest 'https://dist.nuget.org/win-x86-commandline/latest/nuget.exe' -OutFile $nugetExe
		}

		& $nugetExe update -self | Out-Null

		$nugetExe = [System.IO.Path]::Combine($toolsDir, "Nuget", "Nuget.exe")

		return $nugetExe

    }
}   

function Install-Packages(){
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$True)]
        [bool]$restoreReferences,
        [Parameter(Mandatory=$True)]
        [bool]$initalisePackages,
        [Parameter(Mandatory=$False)]
        [string]$packageName = $null,
        [Parameter(Mandatory=$False)]
        [string]$solutionFilePath = $null
    )
    process{
       if($initalisePackages -eq $True) {
           Initialize-PackagesFolder
       }

		if(Test-Path $(Join-Path $solutionPath ".nuget\packages.config")){

			$pkgConfig = Get-Item (Join-Path $solutionPath ".nuget\packages.config")
            
			$pkgPath = New-Item -Force -ItemType directory -Path $(Get-PackagesDir) | Out-Null

			$packagesToIgnore = @()

			[xml]$packageFile = gc $pkgConfig
			$packagesToProcess = $packageFile.packages.package | Where-Object {$packagesToIgnore -notcontains $_.id} 

			$packagesToProcess | % {

				if(($packagesToProcess -ne $null ) -and ($_.id -eq $packageName -or $packageName -eq ""))
				{
					if($config.IgnorePackageVersioning -eq $True)
					{ 
						Write-Host "Installing package $($_.id)"

						$package = $(Install-Package $($_.id) -AllowPrereleaseVersions -Source $($config["Nuget"].Source) -Destination $pkgPath -SkipDependencies -ErrorAction SilentlyContinue -Force )
					} 
					else 
					{ 
						Write-Host "Installing package $($_.id) $($_.Version)"
						
						if($($_.id).Substring($($_.id).Length - 3) -eq ".DB")
						{
							$package = $(Install-Package $($_.id) -Source $($config["Nuget"].Source) -Destination $pkgPath -MinimumVersion "$($_.Version)" -SkipDependencies -ErrorAction SilentlyContinue -Force )	
						}
						else
						{
							$package = $(Install-Package $($_.id) -Source $($config["Nuget"].Source) -Destination $pkgPath -RequiredVersion "$($_.Version)" -SkipDependencies -ErrorAction SilentlyContinue -Force )	
						}
                    }
                    
					if($package -eq $null) {
						Write-Host "Installing package $($_.id) $($_.Version) From Remote"

						$package = $(Install-Package $($_.id) -Source $($config["Nuget"].Source) -Destination $pkgPath -Force -RequiredVersion "$($_.Version)" -SkipDependencies -ErrorAction SilentlyContinue)	
					}

                    if($package -ne $null) {
                        if($restoreReferences) {

                            $dbProjects = $config["DbProjects"];

                            if($dbProjects -ne $null)
                            {
                                foreach ($dbProject in $dbProjects.GetEnumerator()) {

									$sqlProject = $(Get-RelativeProjectPath -solutionFilePath $solutionFilePath -projectName $dbProject.ProjectName)

									Write-Verbose "sqlProject [$($sqlProject)]"

                                    Restore-References -sqlProject $sqlProject -pkgPath $pkgPath -pkgName $package.Name -pkgVersion $package.Version | Out-Null
                                }
                            }
                        }
                    }
                    else {
                        Write-Warning "Installing package $($_.id) $($_.Version) Failed, please investigate."

                    }
				}

            } #| Out-Null

		}

		if($config.EnableNuGetPackageRestore) {

			$cmdArgs = @("restore","`"$($solutionFilePath)`"")

			$processFileName = $(Get-NugetExe)
			
			'Restoring nuget packages with the following args: [{0} {1}]' -f $processFileName, ($cmdArgs -join ' ') | Write-Host
				$returnCode = $(Invoke-Process -processFileName $processFileName -cmdArgs $cmdArgs -workingDirectory $solutionPath -captureConsoleOut $True)

			Write-Host "Return Code [$($returnCode)]"
		}
    }
}

function Restore-References(){
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$sqlProject,        
        [Parameter(Mandatory=$True)]
        [string]$pkgPath,        
        [Parameter(Mandatory=$True)]
        [string]$pkgName,        
        [Parameter(Mandatory=$True)]
        [string]$pkgVersion
    )
    process{

            #$sqlProj = "$(Join-Path $solutionPath "$($dbProjectName)")\$($dbProjectName).sqlproj"

            [xml]$sqlProjectXml = [xml](Get-Content -Path $sqlProject)              

            $nodes = $sqlProjectXml.Project.ItemGroup.ArtifactReference | Where-Object {$_.Include -like "*$($pkgName)*"}
            
            foreach ($node in $nodes) {
                $fileName = [System.IO.Path]::GetFileName($node.Include)
                $path = "$($pkgPath)\$($pkgName).$($pkgVersion)\*"

                $referencePath = Get-ChildItem -Path $path -Filter $fileName -Recurse
                
				$relativePath = $(Get-RelativePath -AbsolutePath $referencePath.FullName -SourcePath $(Split-Path -Path $sqlProject))

                $node.Include = $("$([string]$relativePath)")
                $node.HintPath = $("$([string]$relativePath)")

				$node.SuppressMissingDependenciesErrors = "$($true)" #$True
            }

            $sqlProjectXml.Save($(Get-AbsolutePath -RelativePath $sqlProject))
    }
}

function Initialize-PackagesFolder{
    [cmdletbinding()]
    param()
    process{
        $packagesFolder = $(Get-PackagesDir)

        if(Test-Path $packagesFolder){
            'Deleting packages folder [{0}]' -f $packagesFolder | Write-Host
            Remove-Item $packagesFolder -Recurse -Force
        }
		return $packagesFolder
    }
}

function Install-DacServicesNuget(){
[cmdletbinding()]
    param(
		[Parameter(Mandatory=$True)]
		[string]$packagesPath
	)
    process{

        New-Item -Force -ItemType directory -Path $packagesPath
		
		if(Test-Path $packagesPath) {

			'Installing Microsoft.SqlServer.DacFx.x64 package.' | Write-Host
			 	Install-Package Microsoft.SqlServer.DacFx.x64 -Source $($config["Nuget"].Source) -Destination $packagesPath -Force

			return $True
		}
		return $False
    }
}

function Install-ISBuilderNuget(){
[cmdletbinding()]
    param(
		[Parameter(Mandatory=$True)]
		[string]$packagesPath
	)
    process{

        New-Item -Force -ItemType directory -Path $packagesPath
		
		if(Test-Path $packagesPath) {

			'Installing Microsoft.SqlServer.IntegrationServices.Build package.' | Write-Host
			 	Install-Package Microsoft.SqlServer.IntegrationServices.Build -Source $($config["Nuget"].Source) -Destination $packagesPath -Force

			return $True
		}
		return $False
    }
}

function Install-SqlServerModule(){
[cmdletbinding()]
    param()
    process{

		if (-Not(Get-Module -ListAvailable -Name SqlServer)) {
			'Installing SqlServer module.' | Write-Host
			Install-Module -Name SqlServer -Force -AllowClobber -Scope CurrentUser
		}

		return $True
    }
}

function Install-DacBuilderNuget(){
[cmdletbinding()]
    param(
		[Parameter(Mandatory=$True)]
		[string]$packagesPath
	)
    process{

        New-Item -Force -ItemType directory -Path $packagesPath
		
		if(Test-Path $packagesPath) {

			'Installing Microsoft.Data.Tools.Msbuild package.' | Write-Host
			 	Install-Package Microsoft.Data.Tools.Msbuild -Source $($config["Nuget"].Source) -Destination $packagesPath -Force

			return $True
		}
		return $False
    }
}

function Install-VsWhere(){
[cmdletbinding()]
    param(
		[Parameter(Mandatory=$True)]
		[string]$packagesPath
	)
    process{

        New-Item -Force -ItemType directory -Path $packagesPath
		
		if(Test-Path $packagesPath) {

			'Installing vswhere package.' | Write-Host
			 	Install-Package vswhere -Source $($config["Nuget"].Source) -Destination $packagesPath -Force

			return $True
		}
		return $False
    }
}

function Install-SqlBuildToolsNuget(){
[cmdletbinding()]
    param(
		[Parameter(Mandatory=$True)]
		[string]$packagesPath
	)
    process{

        New-Item -Force -ItemType directory -Path $packagesPath
		
		if(Test-Path $packagesPath) {

			'Installing SqlBuildTools.DB package from '+ $($config["Nuget"].Source) | Write-Host				
				Install-Package SqlBuildTools.DB -Source $($config["Nuget"].Source) -Destination $packagesPath -Force -AllowPrereleaseVersions
			
			return $True
		}
		return $False
    }
}

function Install-MsTestNuget(){
[cmdletbinding()]
    param(
		[Parameter(Mandatory=$True)]
		[string]$packagesPath
	)
    process{

        New-Item -Force -ItemType directory -Path $packagesPath
		
		if(Test-Path $packagesPath) {

			'Installing Microsoft.Data.Tools.UnitTest package.' | Write-Host
				Install-Package Microsoft.Data.Tools.UnitTest -Source $($config["Nuget"].Source) -Destination $packagesPath -Force

			return $True
		}
		return $False
    }
}

function Install-SsisBuild(){
[cmdletbinding()]
    param(
		[Parameter(Mandatory=$True)]
		[string]$packagesPath
	)
    process{
		
		New-Item -Force -ItemType directory -Path $packagesPath | Out-Null
		
		if(Test-Path $packagesPath) {

			'Installing ssis-build.DB package from [{0}]' -f $($config["Nuget"].Source) | Write-Host 
				
				Install-Package ssis-build.DB -Source $($config["Nuget"].Source) -Destination $packagesPath -Force
		}
		
		return $null

    }
}

function Add-Source(){
    [cmdletbinding()]
    param(
		[Parameter(Mandatory=$True)]
		[string]$pkgSourceName,
		[Parameter(Mandatory=$True)]
		[string]$pkgSource
	)
    process{
        #Remove-Source -pkgSourceName $pkgSourceName -pkgSource $pkgSource

        $cmdArgs = @("sources","add","-name $pkgSourceName","-source $pkgSource")

		$processFileName = $(Get-NugetExe)

        'Running nuget with the following args: [{0} {1}]' -f $processFileName, ($cmdArgs -join ' ') | Write-Verbose 
			$returnCode = $(Invoke-Process -processFileName $processFileName -cmdArgs $cmdArgs)

    }
}

function Remove-Source(){
    [cmdletbinding()]
    param(
		[Parameter(Mandatory=$True)]
		[string]$pkgSourceName,
		[Parameter(Mandatory=$True)]
		[string]$pkgSource
	)
    process{     
        $cmdArgs = @("sources","remove","-name $pkgSourceName","-source $pkgSource")

		$processFileName = $(Get-NugetExe)

        'Running nuget with the following args: [{0} {1}]' -f $processFileName, ($cmdArgs -join ' ') | Write-Verbose 
			$returnCode = $(Invoke-Process -processFileName $processFileName -cmdArgs $cmdArgs)
    }
}

function New-Package(){
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$solutionName
    )
    process{

        $nuSpec = $(New-NuSpec -solutionName $solutionName)
    
        #Add-Source -pkgSourceName $($config["Nuget"].Name) -pkgSource $($config["Nuget"].Source) | Out-Null
                
        $buildPath = $(Join-Path $solutionPath "build")
        
        $cmdArgs = @("pack","`"$nuSpec`"","-OutputDirectory", "`"$buildPath`"")

		$processFileName = $(Get-NugetExe)

        'Creating new nuget package with the following args: ["{0}" {1}]' -f $processFileName, ($cmdArgs -join ' ') | Write-Host 
			$returnCode = $(Invoke-Process -processFileName $processFileName -cmdArgs $cmdArgs)

        if($returnCode -ne 0){
            Throw "Failed creating nuget package"
        }
    }
}

function New-NuSpec(){
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$solutionName
    )
    process{
        Import-Module EPS -Force -DisableNameChecking
            
        $nuSpecTemplate = "$(Join-Path $toolsPath "ps-templates\NuSpec\nuspec.eps")"

        $nuSpec = "$(Join-Path $solutionPath "build\$solutionName.nuspec")"

        $(New-Item $nuSpec -type file -force -value $(Expand-Template -file $nuSpecTemplate -binding @{ solutionName = $solutionName; config = $config; version = $(Invoke-GetVersion); solutionPath = $solutionPath }))
    }
}

function Push-Package(){
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$buildPath
    )
    process{
        
        #Add-Source -pkgSourceName $($config["Nuget"].Name) -pkgSource $($config["Nuget"].Source)  | Out-Null

        Get-ChildItem $buildPath -Filter *.nupkg | 
        Foreach-Object {

            Write-Verbose "ApiKey: $($config["Nuget"].ApiKey)"

            $cmdArgs = @("push","`"$($_.FullName)`"","-source $($config["Nuget"].Source)",$($config["Nuget"].ApiKey))

			$processFileName = $(Get-NugetExe)

			Write-Host "cmdArgs [$($cmdArgs)]"

            'Pushing nuget package with the following args:["{0}" {1}]' -f $processFileName, ($cmdArgs -join ' ') | Write-Host 
				$returnCode = $(Invoke-Process -processFileName $processFileName -cmdArgs $cmdArgs)

        }
    }
}

Export-ModuleMember -Function 'Install-Packages'

Export-ModuleMember -Function 'Install-DacServicesNuget'

Export-ModuleMember -Function 'Install-DacBuilderNuget'

Export-ModuleMember -Function 'Install-ISBuilderNuget'

Export-ModuleMember -Function 'Install-VsWhere'

Export-ModuleMember -Function 'Install-SqlBuildToolsNuget'

Export-ModuleMember -Function 'Install-MsTestNuget'

Export-ModuleMember -Function 'Install-MsBuild'

Export-ModuleMember -Function 'Install-SsisBuild'

Export-ModuleMember -Function 'Install-SqlServerModule'

Export-ModuleMember -Function 'New-Package'

Export-ModuleMember -Function 'Push-Package'

Export-ModuleMember -Function 'Initialize-PackagesFolder'