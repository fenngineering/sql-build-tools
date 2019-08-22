<#
.SYNOPSIS  
    This script will provide an interface to devenv.exe     
.NOTES
  Version:        1.0
  Author:         PaulWallington
  Creation Date:  01/10/2016
  Purpose/Change: Initial script development
#>
[CmdletBinding()]
param()

<#
.SYNOPSIS  
	This will Build the AS project using devenv  
#>

function Get-Exe{
    [cmdletbinding()]
        param()
        process{
	    $path = $script:defaultDevEnvPath
		
		if(!$path){
			# use vswhere to locate the vs2017 installation folder	
			$vswhere = Get-VsWhere

			$path = & $vswhere -latest -version $vsWhereVersion -products * -property installationPath

			Write-Host "vs2017 installPath $($path)"

			if ($path) {

				$path = $(Get-File -path $path -fileName "devenv.com") | Select-Object -first 1

				if (Test-Path $path.FullName) {

					Write-Host ("found devenv.com [($path)]")
					return $path
				}
			}
		}
    }
}


function Invoke-DevEnv{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$solutionName,
        [Parameter(Mandatory=$True)]
        [string]$projectName
    )
    process{

        $slnFilePath = $(Get-File -path $solutionPath -fileName $solutionName) 
		$projFilePath =  $(Get-File -path $solutionPath -fileName $projectName) | Select-Object -first 1

        Write-Host "Building project [$($projectName)]"

        $cmdArgs = @()
        $cmdArgs += "$($slnFilePath.FullName)"
        $cmdArgs += "/Build release"
        $cmdArgs += "/Project $($projFilePath.FullName)"

        $processFileName = (Get-Exe).FullName

        Import-Module process

        Write-Host $processFileName $cmdArgs         

        'Running devenv with the following args: [{0} {1}]' -f $processFileName, ($cmdArgs -join ' ') | Write-Verbose 
            $returnCode = $(Invoke-Process -processFileName $processFileName -cmdArgs $cmdArgs)

		return $returnCode
    }
}


Export-ModuleMember -Function 'Invoke-DevEnv'
