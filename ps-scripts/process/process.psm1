<#
.SYNOPSIS  
    This script will provide an interface to the .Net Process 
    Starter object
    
.NOTES
  Version:        1.0
  Author:         Paul Wallington
  Creation Date:  01/10/2016
  Purpose/Change: Initial script development
#>
[CmdletBinding()]
param()

function Invoke-Process(){
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$processFilename,
        [Parameter(Mandatory=$True)]
        [string[]]$cmdArgs,
        [Parameter(Mandatory=$False)]
        [string]$solutionPath,
        [Parameter(Mandatory=$False)]
        [bool]$captureConsoleOut = $False,
        [Parameter(Mandatory=$False)]
        [string]$consoleOut
    )
    process{

        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = $processFilename
        $pinfo.UseShellExecute = $False
        $pinfo.Arguments = $cmdArgs
        $pinfo.WorkingDirectory = $solutionPath
        $pinfo.RedirectStandardError = $True
        $pinfo.RedirectStandardOutput = $captureConsoleOut
        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = $pinfo
        $p.Start() | Out-Null
        $p.WaitForExit()

        if($captureConsoleOut -eq $True) {
            return $p.StandardOutput.ReadToEnd()
        }
        else
        {
            return $p.ExitCode
        }
    }
}

Export-ModuleMember -Function 'Invoke-Process'