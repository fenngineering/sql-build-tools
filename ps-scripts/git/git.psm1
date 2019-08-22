<#
.SYNOPSIS  
    This script will provide an interface to git 
.NOTES
  Version:        1.0
  Author:         Andrew J Fenna
  Creation Date:  01/10/2016
  Purpose/Change: Initial script development
#>
[CmdletBinding()]
param()

Import-Module common

function Get-LastHistory{
    [cmdletbinding()]
        param(			
            [Parameter(Mandatory=$True)]
            [string]$numOfCommits
		)
        process{
            $processFileName = "git.exe"
            $cmdArgs = "log --pretty=format:%h|%an|%ad|%s -$numOfCommits --date=short"

            Import-Module process

            'Running git with the following args: [git.exe {0}]' -f ($cmdArgs -join ' ') | Write-Verbose 
                $lastHistory = Invoke-Process -processFileName $processFileName -cmdArgs $cmdArgs -captureConsoleOut $True -consoleOut $consoleOut -solutionPath $solutionPath
        
            If ($lastHistory -isnot "String") {
                Write-Error "Failed to get history from Git"
                return -1
            }

			Write-Verbose "-----START GIT"
			Write-Verbose "$lastHistory"
			Write-Verbose "-----END GIT"

			return $lastHistory.Split([Environment]::NewLine)
        }
}

function Get-Commit {
    [cmdletbinding()]
        param()
        process{        
            $lastHistory = "$(Get-LastHistory -numOfCommits 1)".split("|")

            return $lastHistory[0]
        }
}

function Get-Author {
    [cmdletbinding()]
        param()
        process{        
            $lastHistory = "$(Get-LastHistory -numOfCommits 1)".split("|")

            return $lastHistory[1]
        }
}

function Get-CommitDate {
    [cmdletbinding()]
        param()
        process{        
            $lastHistory = "$(Get-LastHistory -numOfCommits 1)".split("|")

            return $lastHistory[2] 
        }
}

function Get-Comments {
    [cmdletbinding()]
        param(			
            [Parameter(Mandatory=$True)]
            [int]$num)
        process{        

			$count = 0

            Get-LastHistory -numOfCommits(5) | ForEach-Object {
				
				$history = $_.split("|")
				$count++

				if($num -eq $count)
				{
					return $history[3]
				}

			}
        }
}

Export-ModuleMember -Function 'Get-Commit'

Export-ModuleMember -Function 'Get-Author'

Export-ModuleMember -Function 'Get-CommitDate'

Export-ModuleMember -Function 'Get-Comments'
