#
# This is a PowerShell Unit Test file.
# You need a unit test framework such as Pester to run PowerShell Unit tests. 
# You can download Pester from http://go.microsoft.com/fwlink/?LinkID=534084
#

$psToolsConfig = "$($PSScriptRoot)\..\ps-config\SqlBuildTools.psd1"

Import-Module "$($PSScriptRoot)\..\ps-scripts\common" -ArgumentList $null, $psToolsConfig

InModuleScope common {
	Describe 'Invoke-Sql' {
		It 'execute some sql' {

			Mock -ModuleName common Invoke-Sql { $True }
			
			Invoke-Sql -dataSource $config[$environment].Server -databaseName "master" -query "select 1;" | Should Be $True

		}
	}
	Describe "Get-BuildDir" {
		It 'will return the build directory' {
			Get-BuildDir | Should Not BeNullOrEmpty
		}
	}
	Describe "Get-PackagesDir" {
		It 'will return the packages directory' {
			Get-PackagesDir | Should Not BeNullOrEmpty
		}
	}
	Describe "Invoke-GetVersion" {
		It 'will return the current version' {

			Set-Location $PSScriptRoot

			$rootConfig = "$(Join-Path $PSScriptRoot 'config.psd1')"

			$psToolsConfig = "$($PSScriptRoot)\..\ps-config\SqlBuildTools.psd1"
						
			Copy-Item $psToolsConfig $rootConfig

			Import-LocalizedData -FileName "config.psd1" -BindingVariable "config" -UICulture "en-GB"	
				
			$here = "$($PSScriptRoot)\..\ps-scripts"
			$env:PSModulePath = $env:PSModulePath + ";$($here)"

			$semver = $(Invoke-SetVersion)

			$semver | Should Exist

			$majorAssert = if($Env:majorVersion -eq $null) { 0 } else { $Env:majorVersion }

			$buildAssert= if($Env:GO_PIPELINE_COUNTER -eq $null) { 1 } else {$Env:GO_PIPELINE_COUNTER}

			$minorAssert = $config.SqlVersion

			Invoke-GetVersion | Should Be "$($majorAssert).$($minorAssert).$($buildAssert)"
				
			Remove-Item $semver -Recurse -Force
		}
	}
	Describe "Invoke-SetVersion" {
		It 'will create the .semver file at the correct build version' {

			$here = "$($PSScriptRoot)\..\ps-scripts"
			$env:PSModulePath = $env:PSModulePath + ";$($here)"

			$semver = $(Invoke-SetVersion)
			$semver | Should Exist

			Remove-Item $semver -Recurse -Force
		}
	}

	Describe "Get-App aspub" {
		It 'returns Microsoft.AnalysisServices.Deployment' {
			Get-App "Microsoft.AnalysisServices.Deployment" | Should Exist
		}
	}
	Describe "Get-App ISDeploymentWizard" {
		It 'returns ISDeploymentWizard' {
			Get-App "ISDeploymentWizard" | Should Exist
		}
	}
	Describe "Create-PreRelease" {
		It "will add pre-release to semver" {

			$rootConfig = "$(Join-Path $PSScriptRoot 'config.psd1')"

			$psToolsConfig = "$($PSScriptRoot)\..\ps-config\SqlBuildTools.psd1"
						
			Copy-Item $psToolsConfig $rootConfig

			Import-LocalizedData -FileName "config.psd1" -BindingVariable "config" -UICulture "en-GB"	
				
			$here = "$($PSScriptRoot)\..\ps-scripts"
			$env:PSModulePath = $env:PSModulePath + ";$($here)"

			$semver = $(Invoke-SetVersion)

			$semver | Should Exist

			$majorAssert = if($Env:majorVersion -eq $null) { 0 } else { $Env:majorVersion }

			$buildAssert= if($Env:GO_PIPELINE_COUNTER -eq $null) { 1 } else {$Env:GO_PIPELINE_COUNTER}

			$minorAssert = $config.SqlVersion
				
			Invoke-CreatePreRelease

			Invoke-GetVersion | Should Be "$($majorAssert).$($minorAssert).$($buildAssert)-pre-release"

			Remove-Item $semver -Recurse -Force
		}
	}
}