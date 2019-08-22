set-strictmode -version latest
$ErrorActionPreference = 'Stop'

function execute-externaltool
(
  [string] $context,
  [scriptblock] $actionBlock
)
{
  # This function exists to check the exit code for the external tool called within the script block, so we don't have to do this for each call
  & $actionBlock
  if ($LastExitCode -gt 0) { throw "$context : External tool call failed" }
}


try
{
  write-host "Script:            " $MyInvocation.MyCommand.Path
  write-host "Pid:               " $pid
  write-host "Host.Version:      " $host.version
  write-host "Execution policy:  " $(get-executionpolicy)
  
  $result = $(Invoke-Pester -PassThru)
  if($LastExitCode=$result.FailedCount -gt 0){
	throw "Failed Tests > 0, Testing Failed."
  }
}
catch
{
  write-host "$pid : Error caught - $_"
  if ($? -and (test-path variable:LastExitCode) -and ($LastExitCode -gt 0)) { exit $LastExitCode }
  else { exit 1 }
}