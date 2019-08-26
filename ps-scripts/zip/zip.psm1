<#
.SYNOPSIS  
    This script will provide an interface to performing compression routines
    Starter object
    
.NOTES
  Version:        1.0
  Author:         Andrew Fenna
  Creation Date:  01/10/2016
  Purpose/Change: Initial script development
#>
[CmdletBinding()]
Param ()

function Invoke-Zip{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$source,
        [Parameter(Mandatory=$True)]
        [string]$destination
    )
    process{
        If(Test-path $destination) {Remove-item $destination}

        If (-Not (Test-path $source)) {
            Write-Error "$source does not exist."
            return -1
        }

        try{
             Add-Type -assembly "System.Io.Compression.FileSystem"

            'Creating [{0}]' -f $destination | Write-Verbose
                [IO.Compression.ZipFile]::CreateFromDirectory($source, $destination, "Optimal", $False)
            return 0
        } catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        } 
    }
}

function Invoke-Unzip{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$source,
        [Parameter(Mandatory=$True)]
        [string]$destination
    )
    process{

        If (-Not (Test-path $source)) {
            Write-Error "$source does not exist."
            return 1
        }

        If(Test-path $destination) {Remove-item $destination -Recurse }

        try{
            Add-Type -assembly "System.Io.Compression.FileSystem"

            "Unzipping [{0}]" -f $source | Write-Verbose
                [IO.Compression.ZipFile]::ExtractToDirectory($source, $destination)
            return 0
        } catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
    }
}

function Invoke-ZipDeletePart{
    [cmdletbinding()]
        param(
            [Parameter(Mandatory=$True)]
            [string]$zipFilePath,
            [Parameter(Mandatory=$True)]
            [string]$zipPart
        )
        process{

			Add-Type -AssemblyName WindowsBase
			$zipPackage=[System.IO.Packaging.ZipPackage]::Open($zipFilePath, [System.IO.FileMode]"OpenOrCreate", [System.IO.FileAccess]"ReadWrite")

			try{
				Write-Verbose "Removing $zipPart"
				$zipPackage.DeletePart("$zipPart")
				return 0
			} catch {
				$PSCmdlet.ThrowTerminatingError($PSitem)
			} 
			finally {
				$zipPAckage.Close()
				$zipPackage.Dispose()
			}
        }
}

function Invoke-ZipCreatePart{
    [cmdletbinding()]
        param(
            [Parameter(Mandatory=$True)]
            [string]$zipFilePath,
            [Parameter(Mandatory=$True)]
            [string]$file,
            [Parameter(Mandatory=$True)]
            [string]$mimeType
        )
        process{
            Add-Type -AssemblyName WindowsBase
            $zipPackage=[System.IO.Packaging.ZipPackage]::Open($zipFilePath, [System.IO.FileMode]"OpenOrCreate", [System.IO.FileAccess]"ReadWrite")
            $zipPart = "/$([System.IO.Path]::GetFileName($file))"
            
            try{

				if($zipPackage.PartExists($zipPart) -eq $False){
					Write-Host "Creating $zipPart"
					$part = $packagePart=$zipPackage.CreatePart($zipPart, $mineType)
					$bytes=[System.IO.File]::ReadAllBytes($file)

					$stream=$part.GetStream()
					$stream.Write($bytes, 0, $bytes.Length)
					$stream.Close()
					return 0
				}
			}
			catch {
				$PSCmdlet.ThrowTerminatingError($PSitem)
            }
			finally {
				$zipPAckage.Close()
				$zipPackage.Dispose()
			}
        }
}

function Invoke-ZipGetStreams{
    [cmdletbinding()]
        param(
            [Parameter(Mandatory=$True)]
            [string]$zipFilePath,
            [Parameter(Mandatory=$False)]
            [string]$extention = $null
        )
        process{

            Add-Type -AssemblyName WindowsBase

            $zipPackage=[System.IO.Packaging.ZipPackage]::Open($zipFilePath, [System.IO.FileMode]"Open", [System.IO.FileAccess]"Read")
            
            $files = @()
            try {    

				ForEach($packagePart in $zipPackage.GetParts()){

					$addFile = $False

					if([System.IO.Path]::GetExtension($packagePart.Uri) -eq $extention) {
						$addFile = $True
					}
					elseif($extention -eq $null){
						$addFile = $True
					}

					if($addFile -eq $True) {
						$source = $packagePart.GetStream([System.IO.FileMode]"Open", [System.IO.FileAccess]"Read")                    
						$sr = New-Object System.IO.StreamReader ($source)
						$files += $sr.ReadToEnd()
					}
				}

				return $files
			} catch {
				$PSCmdlet.ThrowTerminatingError($PSitem)
            }
			finally {
				$zipPAckage.Close()
				$zipPackage.Dispose()
			}
        }
}

Export-ModuleMember -Function 'Invoke-ZipDeletePart'

Export-ModuleMember -Function 'Invoke-ZipCreatePart'

Export-ModuleMember -Function 'Invoke-ZipGetStreams'

Export-ModuleMember -Function 'Invoke-Unzip'

Export-ModuleMember -Function 'Invoke-Zip' 