#
# This is a PowerShell Unit Test file.
# You need a unit test framework such as Pester to run PowerShell Unit tests. 
# You can download Pester from http://go.microsoft.com/fwlink/?LinkID=534084
#

Import-Module "$($PSScriptRoot)\..\ps-scripts\aspub"

InModuleScope aspub {
	Describe "Get-AsPubExe aspub" {
		It 'returns the location of Microsoft.AnalysisServices.Deployment.exe' {
		
			#Set-Location $PSScriptRoot

			$rootConfig = "$(Join-Path $PSScriptRoot 'config.psd1')"

			$psToolsConfig = "$($PSScriptRoot)\..\ps-config\SqlBuildTools.psd1"
						
			Copy-Item $psToolsConfig $rootConfig

			Import-LocalizedData -FileName "config.psd1" -BindingVariable "config" -UICulture "en-GB"			

			$(Get-AsPubExe -SSASVersion $config.SSASVersion) | Should Exist
		}
	}
}
