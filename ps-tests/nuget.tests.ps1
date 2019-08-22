#
# This is a PowerShell Unit Test file.
# You need a unit test framework such as Pester to run PowerShell Unit tests. 
# You can download Pester from http://go.microsoft.com/fwlink/?LinkID=534084
#

Import-Module "$($PSScriptRoot)\..\ps-scripts\nuget"

InModuleScope nuget {
	Describe "Get-Exe nuget" {
		It 'returns the location of nuget.exe' {
			Get-Exe | Should Exist
		}
	}
}