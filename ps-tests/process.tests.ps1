#
# This is a PowerShell Unit Test file.
# You need a unit test framework such as Pester to run PowerShell Unit tests. 
# You can download Pester from http://go.microsoft.com/fwlink/?LinkID=534084
#

Import-Module "$($PSScriptRoot)\..\ps-scripts\process"

InModuleScope process {
	Describe "Invoke-Process powershell" {		
		It 'starts a cmd process' {

			$cmdArgs = @()
			$cmdArgs += "-NonInteractive"
			$cmdArgs += "-NoProfile"
			$cmdArgs += "-NoLogo"
			$cmdArgs += "-Command Write-Host 'Passed!'"

			$processFileName = Get-Command "powershell"

			$(Invoke-Process -processFileName $processFileName -cmdArgs $cmdArgs) | Should Be 0
		}
	}
}