#
# This is a PowerShell Unit Test file.
# You need a unit test framework such as Pester to run PowerShell Unit tests. 
# You can download Pester from http://go.microsoft.com/fwlink/?LinkID=534084
#

Import-Module "$($PSScriptRoot)\..\ps-scripts\msbuild"

InModuleScope msbuild {
	Describe "Get-MsBuildExe msbuild" {
		It 'returns the location of msbuild.exe' {
			$(Get-MsBuildExe).FullName | Should Exist
		}
	}
}