#
# This is a PowerShell Unit Test file.
# You need a unit test framework such as Pester to run PowerShell Unit tests. 
# You can download Pester from http://go.microsoft.com/fwlink/?LinkID=534084
#

Import-Module "$($PSScriptRoot)\..\ps-scripts\dacfx"

Describe "Register-DacServices" {

	InModuleScope dacfx {

		It 'Registers Microsoft.SqlServer.Dac.dll' {

			Mock -ModuleName dacfx Register-DacServices { return $True }

			Register-DacServices | Should Be $True
		}
	}
}
Describe "Get-DacServices" {

	InModuleScope dacfx {

		It 'returns type Microsoft.SqlServer.Dac.DacServices' {

			$dacFxPath = $(Get-File -path "$($toolsPath)\build\" -fileName "Microsoft.SqlServer.Dac.dll")

			$([AppDomain]::CurrentDomain).Load($([System.Reflection.AssemblyName]::GetAssemblyName($dacFxPath.FullName))) | Out-Null;

			Mock -ModuleName dacfx Get-DacServices { return New-Object Microsoft.SqlServer.Dac.DacServices "Server=someServer;Database=somneDatabase;Trusted_Connection=True;" }

			Get-DacServices -serverName "someServer" -databaseName "someDatabase" | Should Not BeNullOrEmpty

		}
	}
}