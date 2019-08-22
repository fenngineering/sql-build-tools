#
# This is a PowerShell Unit Test file.
# You need a unit test framework such as Pester to run PowerShell Unit tests. 
# You can download Pester from http://go.microsoft.com/fwlink/?LinkID=534084
#

Import-Module "$($PSScriptRoot)\..\ps-scripts\zip"

InModuleScope zip {
	Describe "Invoke-Zip" {		
		It 'creates a zip file' {

			$source = $(Join-Path $PSScriptRoot "\testzip") 

			$destination = $(Join-Path $PSScriptRoot "\testzip.zip") 

			$(New-Item $(Join-Path $source "test.txt")  -type file -force -value "test file")			

			Invoke-Zip -source $source -destination $destination | Should Be 0
			
			$destination | Should Exist

			Remove-Item $source -Recurse -Force

			Remove-Item $destination -Recurse -Force
		}
	}
	Describe "Invoke-Unzip" {		
		It 'unzips zip file' {

			$source = $(Join-Path $PSScriptRoot "\testzip") 

			$destination = $(Join-Path $PSScriptRoot "\testzip.zip") 

			$(New-Item $(Join-Path $source "test.txt")  -type file -force -value "test file")			

			Invoke-Zip -source $source -destination $destination | Should Be 0

			$destination | Should Exist

			Remove-Item $source -Recurse -Force
						
			$source = $destination
			$destination = $(Join-Path $PSScriptRoot "\testzip")
			
			Invoke-Unzip -source $source -destination $destination | Should Be 0

			$destination | Should Exist

			Remove-Item $source -Recurse -Force

			Remove-Item $destination -Recurse -Force
		}
	}
	Describe "Invoke-ZipDeletePart" {		
		It 'deletes a file in a zip file' {

			$source = $(Join-Path $PSScriptRoot "\testzip") 

			$destination = $(Join-Path $PSScriptRoot "\testzip.zip") 

			$(New-Item $(Join-Path $source "test.txt")  -type file -force -value "test file")			

			Invoke-Zip -source $source -destination $destination | Should Be 0

			$destination | Should Exist

			Invoke-ZipDeletePart -zipFilePath $destination -zipPart "/test.txt" | Should Be 0

			Remove-Item $source -Recurse -Force
						
			$source = $destination
			$destination = $(Join-Path $PSScriptRoot "\testzip")
			
			Invoke-Unzip -source $source -destination $destination | Should Be 0

			$(Join-Path $destination "test.txt") | Should Not Exist

			Remove-Item $source -Recurse -Force

			Remove-Item $destination -Recurse -Force
		}
	}
	Describe "Invoke-ZipCreatePart" {		
		It 'creates a file in a zip file' {

			$source = $(Join-Path $PSScriptRoot "\testzip") 

			$destination = $(Join-Path $PSScriptRoot "\testzip.zip") 

			$(New-Item $(Join-Path $source "test1.txt")  -type file -force -value "test file")			

			Invoke-Zip -source $source -destination $destination | Should Be 0

			$destination | Should Exist

			$newFile = $(Join-Path $source "test2.txt")

			$(New-Item $newFile -type file -force -value "test file")		
			
			Invoke-ZipCreatePart -zipFilePath $destination -file $newFile -mimeType "text/plain" | Should Be 0

			Remove-Item $source -Recurse -Force
						
			$source = $destination
			$destination = $(Join-Path $PSScriptRoot "\testzip")
			
			Invoke-Unzip -source $source -destination $destination | Should Be 0

			$(Join-Path $destination "test2.txt") | Should Exist

			Remove-Item $source -Recurse -Force

			Remove-Item $destination -Recurse -Force
		}
	}
	Describe "Invoke-ZipGetStreams" {		
		It 'returns a file list from a zip file' {

			$source = $(Join-Path $PSScriptRoot "\testzip") 

			$destination = $(Join-Path $PSScriptRoot "\testzip.zip") 

			$(New-Item $(Join-Path $source "test.txt")  -type file -force -value "txt test file")				

			Invoke-Zip -source $source -destination $destination | Should Be 0

			Remove-Item $source -Recurse -Force

			$destination | Should Exist

			$newFile = $(Join-Path $source "text1.sql")

			$(New-Item $newFile -type file -force -value "test sql file1")
			
			Invoke-ZipCreatePart -zipFilePath $destination -file $newFile -mimeType "text/plain" | Should Be 0
						
			Invoke-ZipGetStreams -zipFilePath $destination -extention ".sql" | Should BeOfType System.Object

			Remove-Item $destination -Recurse -Force
		}
	}
}