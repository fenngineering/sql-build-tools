<#
.SYNOPSIS  
    This script will provide common functions to referencing modules\scripts
.NOTES
  Version:        1.0
  Author:         Andrew J Fenna
  Creation Date:  01/10/2016
  Purpose/Change: Initial script development
  
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$False)]
    [string]$environmentOverride = $null,
	[Parameter(Mandatory=$True)]
    [string]$configPath = $null,
    [Parameter(Mandatory=$False)]
    [bool]$unzipBuild = $False
)

$solutionPath = "$(Get-Location)"
$toolsPath = Split-Path -Parent $(Split-Path -Parent $PSScriptRoot)
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$semver = $(Join-Path $solutionPath "build\.semver")

Write-Verbose "tools folder [$($toolsPath)]"
Write-Verbose "common here folder [$($here)]"
Write-Verbose "solution folder [$($solutionPath)]"

$toolsConfig = "$(Join-Path $here config.psd1)"
$toolsBaseConfig = "$(Join-Path $toolsPath ps-config)"

Write-Verbose "tools config [$toolsConfig]"
Write-Verbose "tools base config [$toolsBaseConfig]"

if(Test-Path $toolsConfig)  {
	Write-Verbose "Removing config.psd1"
	Remove-Item $toolsConfig
}

if($unzipBuild -eq $True) {
	if(Test-Path $solutionPath)  {
		Write-Verbose "Unzipping build.zip"
		Invoke-UnzipBuildZip
	}
}     

#1 check if config exists in the $here folder
if(-Not(Test-Path $toolsConfig))  {
	#2 get the sln from the solution path 
		Get-ChildItem $configPath -Filter *.psd1 | 
			Foreach-Object {
				#3 copy the solutions config to $toolsPath\ps-scripts folder
				Write-Verbose "solution found [$($_.Name)]"
					
				$slnConfig = "$($_.FullName)"

				Write-Verbose "sln config [$slnConfig]"

				if(Test-Path $slnConfig)  {
							
					Copy-Item $slnConfig $toolsConfig
				}
				else {
					Write-Error "Config does not exist [$slnConfig]"
				}
			}
	}

Import-LocalizedData -FileName "config.psd1" -BindingVariable "config" -UICulture "en-GB"

if(Test-Path $(Join-Path $toolsBaseConfig "globalConfig.psd1"))
{
	Import-LocalizedData -BaseDirectory $toolsBaseConfig -FileName "globalConfig.psd1" -BindingVariable "globalConfig" -UICulture "en-GB"
}

if([string]::IsNullOrWhitespace($environmentOverride)) {
    $environment = if( $Env:environment -ne $null ) { "$Env:environment" } else {"dev"}
}
else {
    $environment = $environmentOverride
}

Write-Verbose "Env: [$environment]"

$vsWhereVersion = "[15.0,16.0]"
if(-not[string]::IsNullOrWhiteSpace($globalConfig.vsWhereVersion))
{
	$vsWhereVersion = $globalConfig.vsWhereVersion
}
if(-not[string]::IsNullOrWhiteSpace($config.vsWhereVersion))
{
	$vsWhereVersion = $config.vsWhereVersion
}

<#
.SYNOPSIS
#>
function Invoke-SetVersion{
    [cmdletbinding()]
    param()
    process{

        Import-Module EPS -Force -DisableNameChecking

		$major = if($Env:majorVersion -eq $null) { 0 } else {$Env:majorVersion }

		$minor = $config.SqlVersion

		$build= if($Env:GO_PIPELINE_COUNTER -eq $null) { 1 } else {$Env:GO_PIPELINE_COUNTER}
            
        $template = "$(Join-Path $toolsPath "ps-templates\Semver\.semver.eps")"

		Write-Verbose "semVer [$($semver)]"

        return $(New-Item $semver -type file -force -value $(Expand-Template -file $template -binding @{ major = $major; minor = $minor; build = $build}))
    }
}

<#
.SYNOPSIS
#>
function Invoke-GetVersion{

	Import-Module semver -ArgumentList $semver

    return Invoke-Semver -Format %M.%m.%p%s
}
	
<#
.SYNOPSIS
#>
function Invoke-UnzipBuildZip{
    [cmdletbinding()]
        param()
        process{
            
			Import-Module zip
            Invoke-Unzip -source $(Join-Path $solutionPath "build.zip") -destination $(Join-Path $solutionPath "build") | Out-Null

        }
}

function Invoke-Sql{
    [cmdletbinding()]
        param(
            [Parameter(Mandatory=$True)]
            [string]$dataSource,
            [Parameter(Mandatory=$False)]
            [string]$databaseName = $null,
            [Parameter(Mandatory=$True)]
            [string]$query
        )
        process{

            try {

				Import-Module nuget

				if($(Install-SqlServerModule) -eq $False) {
                    Write-Error "Unable to SqlServer Module ."
                    return  $False
                }
				Remove-Module -Name nuget
                    
                Import-Module SqlServer

				$(Invoke-SqlCmd -ServerInstance $dataSource -Database $databaseName -Query $query)  | Out-Null
                
				Pop-Location

				Remove-Module -Name SqlServer

                return $True
            } 
			catch 
			{
				$PSCmdlet.ThrowTerminatingError($PSitem)
            }
        }
}

function Get-BuildDir{
    [cmdletbinding()]
    param()
    process{
        return $(Join-Path $solutionPath "build")
    }
}

function Get-PackagesDir{
    [cmdletbinding()]
    param()
    process{

		if(Test-Path variable:global:defaultPackagesPath)
		{
			return $global:defaultPackagesPath
		}

        return $(Join-Path $solutionPath "packages")
    }
}

function Get-ToolsDir{
    [cmdletbinding()]
    param()
    process{
        return $toolsPath
    }
}

<#
.SYNOPSIS  
	This will attempt to resolve the path to an executable using Get-Command and the AppPaths registry key
#>
function Get-App {
	param( 
		[string]$cmd 
	)
        $path = $(Get-Command $cmd -ErrorAction SilentlyContinue)

        if($path -eq $null) {

	        $AppPaths = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths"
	        if(!(Test-Path $AppPaths\$cmd)) {
		        $cmd = [IO.Path]::GetFileNameWithoutExtension($cmd)
		        if(!(Test-Path $AppPaths\$cmd)){
		        $cmd += ".exe"
		        }
	        }
	        if(Test-Path $AppPaths\$cmd) {
		        $path = $(Get-Command (Get-ItemProperty $AppPaths\$cmd)."(default)")
	        }
        }

        return $path.Source
}

function Invoke-CreatePreRelease{
    [cmdletbinding()]
    param()
    process{        
		Invoke-GetVersion | Out-Null
        Import-Module semver -ArgumentList $semver
        Invoke-Semver -Special "-pre-release" | Out-Null
		Write-Host "Created pre-release $($(Invoke-GetVersion))" -foregroundcolor "green"
    }
}

function Invoke-CreateRelease{
    [cmdletbinding()]
    param()
    process{        

		Invoke-GetVersion | Out-Null
        Import-Module semver -ArgumentList $semver
        Invoke-Semver -Special " " | Out-Null	
		Write-Host "Created release $($(Invoke-GetVersion))" -foregroundcolor "green"
    }
}

function Import-Library{
    [cmdletbinding()]
        param(
            [Parameter(Mandatory=$True)]
            [string]$path
        )
        process{

			try
			{
				Write-Verbose "Adding library [$($path)]..."
				Import-Module $path -Scope Local

				#$job = Start-Job -ScriptBlock {

				#	Add-Type -path $path
				#}
				#Wait-Job $job
				#Receive-Job $job

			}
			catch [System.Reflection.ReflectionTypeLoadException]
			{
				Write-Error "Message: $($_.Exception.Message)"
				Write-Error "StackTrace: $($_.Exception.StackTrace)"
				Write-Error "LoaderExceptions: $($_.Exception.LoaderExceptions)"
				$PSCmdlet.ThrowTerminatingError($PSitem)
			}
        }
}

function Test-Library{
    [cmdletbinding()]
        param(
            [Parameter(Mandatory=$True)]
            [string]$library
        )
        process{

			try
			{
				Write-Host "Testing library [$($library)]..."

				if(Get-Module -ListAvailable -Name $library ){
                    return $true
                }
                else {
                    return $false
                }
			}
			catch [System.Reflection.ReflectionTypeLoadException]
			{
				Write-Error "Message: $($_.Exception.Message)"
				Write-Error "StackTrace: $($_.Exception.StackTrace)"
				Write-Error "LoaderExceptions: $($_.Exception.LoaderExceptions)"
				$PSCmdlet.ThrowTerminatingError($PSitem)
			}
        }
}

function Remove-Library{
    [cmdletbinding()]
        param(
            [Parameter(Mandatory=$True)]
            [string]$library
        )
        process{

			try
			{
				Write-Verbose "Removing library [$($library)]..."

				Remove-Module -Name $library -Force
			}
			catch [System.Reflection.ReflectionTypeLoadException]
			{
				Write-Error "Message: $($_.Exception.Message)"
				Write-Error "StackTrace: $($_.Exception.StackTrace)"
				Write-Error "LoaderExceptions: $($_.Exception.LoaderExceptions)"
				$PSCmdlet.ThrowTerminatingError($PSitem)
			}
        }
}

function Get-File{
    [cmdletbinding()]
        param(
			[Parameter(Mandatory=$True)]
			[string]$path,
			[Parameter(Mandatory=$True)]
			[string]$fileName
		)
        process{			

			if(Test-Path $path) {
                return $(Get-ChildItem -Path $path -Filter $fileName -Recurse -File | Select-Object -first 1)
            }
        }
}

function Get-ConnectionString{
    [cmdletbinding()]
        param(			
            [Parameter(Mandatory=$True)]
            [string]$serverName,
            [Parameter(Mandatory=$True)]
            [string]$databaseName
		)
        process{			

			$connectionBuilder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder
			$connectionBuilder.Server = $serverName
			$connectionBuilder.Database = $databaseName
			$connectionBuilder.Trusted_Connection = $true

            return $connectionBuilder.ConnectionString

        }
}

function Get-PathFromKeyInConfig{
    [cmdletbinding()]
        param(			
            [Parameter(Mandatory=$True)]
            [string]$keyInConfig,	
            [Parameter(Mandatory=$False)]
            [string]$server = $null
		)
        process{			

			if(-not(Test-Path($keyInConfig) -PathType Any)) 
			{
				## Function Body
				$splitPath = $keyInConfig.Split("\")
				$key= $splitPath.Item(0).Replace("]", "").Replace("[","")
				$splitKey = $key.Split(".")

				$retVal = $config[$environment]

				foreach($keyPart in $splitKey)
				{
					$retVal = $retVal.$keyPart
				}

				$count = $splitPath.Count		

				If($splitPath.Count -gt 1)
				{
					for($i=1; $i -le $splitPath.Count-1; $i++)
					{
						$retVal = $retVal + "\" + $splitPath.Item($i)
					}				
				}

				return $retVal

			}
			return $keyInConfig
        }
}

Function Write-Pixel { 
    param( 
            [String] [parameter(mandatory=$true, Valuefrompipeline = $true)] $Path, 
            [Switch] $ToASCII 
    ) 
    Begin 
    { 
        [void] [System.Reflection.Assembly]::LoadWithPartialName('System.drawing') 
         
        # Console Colors and their Hexadecimal values 
        $Colors = @{ 
            'FF000000' =   'Black'          
            'FF000080' =   'DarkBlue'       
            'FF008000' =   'DarkGreen'      
            'FF008080' =   'DarkCyan'       
            'FF800000' =   'DarkRed'        
            'FF800080' =   'DarkMagenta'    
            'FF808000' =   'DarkYellow'     
            'FFC0C0C0' =   'Gray'           
            'FF808080' =   'DarkGray'       
            'FF0000FF' =   'Blue'           
            'FF00FF00' =   'Green'          
            'FF00FFFF' =   'Cyan'           
            'FFFF0000' =   'Red'            
            'FFFF00FF' =   'Magenta'        
            'FFFFFF00' =   'Yellow'          
            'FFFFFFFF' =   'White'                  
        } 
         
        # Algorithm to calculate closest Console color (Only 16) to a color of Pixel 
        Function Get-ClosestConsoleColor($PixelColor) 
        { 
            ($(foreach ($item in $Colors.Keys) { 
                [pscustomobject]@{ 
                    'Color' = $Item 
                    'Diff'  = [math]::abs([convert]::ToInt32($Item,16) - [convert]::ToInt32($PixelColor,16)) 
                }  
            }) | Sort-Object Diff)[0].color 
        } 
    } 
    Process 
    { 
        Foreach($item in $Path) 
        { 
            #Convert Image to BitMap             
            $BitMap = [System.Drawing.Bitmap]::FromFile((Get-Item $Item).fullname) 
 
            Foreach($y in (1..($BitMap.Height-1))) 
            { 
                Foreach($x in (1..($BitMap.Width-1))) 
                { 
                    $Pixel = $BitMap.GetPixel($X,$Y)         
                    $BackGround = $Colors.Item((Get-ClosestConsoleColor $Pixel.name)) 
                     
 
                    If($ToASCII) # Condition to check ToASCII switch 
                    { 
                        Write-Host "$([Char](Get-Random -Maximum 126 -Minimum 33))" -NoNewline -ForegroundColor $BackGround 
                    } 
                    else 
                    { 
                        Write-Host " " -NoNewline -BackgroundColor $BackGround 
                    } 
                } 
                Write-Host '' # Blank write-host to Start the next row 
            } 
        }         
     
    } 
    end 
    { 
     
    } 
}

Function New-Folder{
	param(
            [Parameter(Mandatory=$True)]
            [string]$folderName
	)
	if(!(Test-Path -Path $folderName)) {New-Item $folderName -Type Directory | Out-Null}
}

Function Invoke-CreateFolder{
    [cmdletbinding()]
    param
    (			
        [Parameter(Mandatory=$True)]
        [string]$FolderName,	
        [Parameter(Mandatory=$False)]
        [string]$Server = '.'
	)
    process
    {
        Write-Host "Creating Folder $($FolderName) on $($Server)"

        if(($Server -ne ".") -and ( $Server -ne $Env:ComputerName ) )
        {
            Invoke-Command -ComputerName $Server -ScriptBlock{
                param ($folderName)

                if(!(Test-Path -Path $folderName))
                {
                    New-Item -Path $folderName -ItemType Directory -Force | Out-Null
                }
            } -ArgumentList $FolderName
        }
        else
        {
            if(!(Test-Path -Path $FolderName))
            {
                New-Item -Path $FolderName -ItemType Directory -Force | Out-Null
            }
        }
    }
}

Function Invoke-CheckDestinationExistance{
    [cmdletbinding()]
    param
    (			
        [Parameter(Mandatory=$True)]
        [string]$Destination,	
        [Parameter(Mandatory=$False)]
        [string]$Server = '.'
	)
    process
    {
        Write-Host "Checking Destinatation Folder $($Destination) on $($Server)"

        if(($Server -ne ".") -and ($Server -ne $Env:ComputerName ))
        {
            Invoke-Command -ComputerName $Server -ScriptBlock { param ($destination)

                if((Test-Path -Path $destination -PathType Container) -and -Not( Test-Path -Path $destination -PathType Leaf))
                {
                    $destinationFolder = $destination.TrimEnd('\')
                }
                elseif ( -Not( Test-Path -Path $destination -PathType Container) -and (Test-Path -Path $destination -PathType Leaf))
                {
                    $destinationFolder = $destination.Replace($destination.Split("\")[-1], "").TrimEnd('\')
                }
                else
                {
                    if($destination.Split("\")[-1].TrimEnd('\').Contains('.'))
                    {
                        $destinationFolder = $destination.Replace($destination.Split("\")[-1], "").TrimEnd('\')
                    }
                    else
                    {
                        $destinationFolder = $destination.TrimEnd('\')
                    }
                }

                if(!(Test-Path -Path $destinationFolder))
                {
                    New-Item -Path $destinationFolder -ItemType Directory -Force | Out-Null
                }

                if((Test-Path -Path $Destination -PathType Container))
                {
                    return $True
                }
            } -ArgumentList $Destination
        }
        else
        {
            if((Test-Path -Path $Destination -PathType Container) -and -Not( Test-Path -Path $Destination -PathType Leaf))
            {
                $destinationFolder = $Destination.TrimEnd('\')
            }
            elseif ( -Not( Test-Path -Path $Destination -PathType Container) -and (Test-Path -Path $Destination -PathType Leaf))
            {
                $destinationFolder = $Destination.Replace($Destination.Split("\")[-1], "").TrimEnd('\')
            }
            else
            {
                if($Destination.Split("\")[-1].TrimEnd('\').Contains('.'))
                {
                    $destinationFolder = $Destination.Replace($Destination.Split("\")[-1], "").TrimEnd('\')
                }
                else
                {
                    $destinationFolder = $Destination.TrimEnd('\')
                }
            }

            if(!(Test-Path -Path $destinationFolder))
            {
                New-Item -Path $destinationFolder -ItemType Directory -Force | Out-Null
            }

            if((Test-Path -Path $Destination -PathType Container))
            {
                return $True
            }
        }

        return $False
    }
}

Function Invoke-CopyFile{
    [cmdletbinding()]
    param
    (			
        [Parameter(Mandatory=$True)]
        [string]$Source,	
        [Parameter(Mandatory=$True)]
        [string]$Destination,
        [Parameter(Mandatory=$False)]
        [string]$Server = "."
	)
    process
    {
        $IsContainer = Invoke-CheckDestinationExistance -Destination $Destination -Server $Server

        if(($Server -ne ".") -and ($Server -ne $Env:ComputerName ))
        {
            $Session = New-PSSession -ComputerName $Server
            if($IsContainer -EQ $True)
            {
                return Copy-Item -Path $Source -Destination $Destination -ToSession $Session -Force -Recurse -Container
            }
            else
            {
                return Copy-Item -Path $Source -Destination $Destination -ToSession $Session -Force -Recurse
            }
            Remove-PSSession -Session $Session

        }
        else
        {
			if($IsContainer -eq $True)
            {
                return Copy-Item -Path $Source -Destination $Destination -Force -Recurse -Container
            }
            else
            {
                return Copy-Item -Path $Source -Destination $Destination -Force -Recurse
            }
        }
    }
}

Function Invoke-ApplyTemplate{
    [cmdletbinding()]
    param
    (			
        [Parameter(Mandatory=$True)]
        [string]$Source,	
        [Parameter(Mandatory=$True)]
        [string]$Destination,
        [Parameter(Mandatory=$False)]
        [Hashtable]$Binding = @{},
        [Parameter(Mandatory=$False)]
        [string]$Server = "."
	)
    process
    {
		Import-Module EPS -Force -DisableNameChecking

		$templateValue = $(Expand-Template -file $Source -binding @{ config = $config; environment = $environment })

        if(($Server -ne ".") -and ($Server -ne $Env:ComputerName ))
        {
            $Session = New-PSSession -ComputerName $Server

			Write-Host "Destination [$Destination]"

			$NewScriptBlock = {
				param ($Destination, $templateValue)
				New-Item $Destination -type file -force -value $templateValue
			
			}

			Invoke-Command -Session $Session -ScriptBlock $NewScriptBlock -ArgumentList ($Destination, $templateValue)
            Remove-PSSession -Session $Session
        }
        else
        {
             New-Item $Destination -type file -force -value $templateValue -Force
        }
		Remove-Module -name EPS
		return
    }
}

function Get-UncFromRelativePath {
 [cmdletbinding()]
    param
    (			
        [Parameter(Mandatory=$True)]
        [string]$Server,	
        [Parameter(Mandatory=$True)]
        [string]$RelativePath
	)
    process
    {
		$absolutePath = $(Resolve-Path -Path $RelativePath)

		Write-Verbose "Resolved Path [$($RelativePath)] >> [$($absolutePath)]..."
		
		if($Server -eq ".")
		{
			$Server = $Env:ComputerName
		}
	
		if(-not([System.Net.DNS]::GetHostByName($Server).HostName -eq $Env:ComputerName))
		{
			return "\\$Server\$($absolutePath.ToString().Replace(':','$'))"
		}
		return $absolutePath
	}
}

function Get-AbsolutePath {
 [cmdletbinding()]
    param
	(
        [Parameter(Mandatory=$True)]
        [string]$RelativePath,
        [Parameter(Mandatory=$False)]
        [string]$SourcePath
	)
    process
    {



		if($SourcePath) {

			Push-Location -Path $SourcePath
		}

		$absolutePath = Resolve-Path $RelativePath

		Write-Verbose $("RelativePath [$($RelativePath)] => AbsolutePath [$($absolutePath)] From $(Get-Location)")
		
		if($SourcePath) {

			Pop-Location
		}

		return $absolutePath
	}
}

function Get-RelativePath {
 [cmdletbinding()]
    param
	(
        [Parameter(Mandatory=$True)]
        [string]$AbsolutePath,
        [Parameter(Mandatory=$False)]
        [string]$SourcePath
	)
    process
    {

		if($SourcePath) {

			Push-Location -Path $SourcePath
		}

		$relativePath = Resolve-Path -Relative $AbsolutePath

		Write-Verbose $("AbsolutePath [$($AbsolutePath)] => RelativePath [$($relativePath)] From $(Get-Location)")
		
		if($SourcePath) {

			Pop-Location
		}

		return $relativePath
	}
}

function Get-RelativeProjectPath {
	[cmdletbinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$solutionFilePath = $null,
		[Parameter(Mandatory=$True)]
        [string]$projectName = $null
	)
    process{

		Get-Content $solutionFilePath |
		Select-String 'Project\(' |
		ForEach-Object {
			$projectParts = $_ -Split '[,=]' | ForEach-Object { $_.Trim('[ "{}]') };

			Write-Verbose "Part1 [$($projectParts[1])]"
			Write-Verbose "Part2 [$($projectParts[2])]"
			Write-Verbose "Part3 [$($projectParts[3])]"

			if($projectParts[1] -eq $projectName) {

				return $($projectParts[2].ToString().Trim()) 
			}
		}
    }
}

function Get-VsWhere{
    [cmdletbinding()]
    param()
    process{

		Import-Module nuget
        
		$packagesPath = Get-PackagesDir

		$vsWhere = $(Get-File -path $packagesPath -fileName "vswhere.exe").FullName

		if(-not($vsWhere) ) {

			if($(Install-VsWhere -packagesPath $packagesPath) -eq $False) {
				Write-Error "Unable to install Vs Where."
				return  $False
			}
		}

		return $(Get-File -path $packagesPath -fileName "vswhere.exe").FullName
    }
}

function Import-AssemblyInAppDomain{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$True)]
        [System.AppDomain]$domain,
		[Parameter(Mandatory=$True)]
        [System.Reflection.AssemblyName]$assemblyName
	)
    process{
		Write-Verbose "Adding assembly [$($assembly)]..."

		#$amsLoaderProxy = [SqlBuildTools.DacLoader.Proxy]$domain.CreateInstanceAndUnwrap([System.Reflection.Assembly]::GetExecutingAssembly().FullName, [SqlBuildTools.DacLoader.Proxy].GetType().FullName);

		$domain.Load($assemblyName) | Out-Null;

		#$amsLoaderProxy.GetAssembly($assembly);
	}
}

function Confirm-AssemblyInAppDomain {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$True)]
        [System.AppDomain]$domain,
		[Parameter(Mandatory=$True)]
        [string]$assembly
	)
    process{ 

		$loaded = $False

		foreach ($x in $domain.GetAssemblies() ) {
				#Write-Host "Assemnbly Loaded [$($x.GetName() )]"
				$loaded = $x.GetName().ToString().Contains($assembly)
				if($loaded -eq $True) {
					#Write-Host "Existing, found [$assembly]"
					break
				}
			}

		return $loaded
	}
}

Export-ModuleMember -Function 'New-Folder'

Export-ModuleMember -Function 'Write-Pixel'

Export-ModuleMember -Function 'Invoke-ImportConfig'

Export-ModuleMember -Function 'Invoke-SetVersion'

Export-ModuleMember -Function 'Invoke-GetVersion'

Export-ModuleMember -Function 'Invoke-UnzipBuildZip'

Export-ModuleMember -Function 'Invoke-Sql'

Export-ModuleMember -Function 'Get-BuildDir'

Export-ModuleMember -Function 'Get-PackagesDir'

Export-ModuleMember -Function 'Get-App'

Export-ModuleMember -Function 'Get-VsWhere'

Export-ModuleMember -Function 'Invoke-CreateFolder'

Export-ModuleMember -Function 'Invoke-CheckDestinationExistance'

Export-ModuleMember -Function 'Invoke-CopyFile'

Export-ModuleMember -Function 'Invoke-CreatePreRelease'

Export-ModuleMember -Function 'Invoke-CreateRelease'

Export-ModuleMember -Function 'Import-Library'

Export-ModuleMember -Function 'Remove-Library'

Export-ModuleMember -Function 'Test-Library'

Export-ModuleMember -Function 'Get-File'

Export-ModuleMember -Function 'Get-ToolsDir'

Export-ModuleMember -Function 'Get-ConnectionString'

Export-ModuleMember -Function 'Get-PathFromKeyInConfig'

Export-ModuleMember -Function 'Get-UncFromRelativePath'

Export-ModuleMember -Function 'Get-AbsolutePath'

Export-ModuleMember -Function 'Get-RelativePath'

Export-ModuleMember -Function 'Get-RelativeProjectPath'

Export-ModuleMember -Function 'Invoke-ApplyTemplate'

Export-ModuleMember -Function 'Import-AssemblyInAppDomain'

Export-ModuleMember -Function 'Confirm-AssemblyInAppDomain'

Export-ModuleMember -Variable 'config'

Export-ModuleMember -Variable 'environment'

Export-ModuleMember -Variable 'here'

Export-ModuleMember -Variable 'toolsPath'

Export-ModuleMember -Variable 'solutionPath'

Export-ModuleMember -Variable 'semver'

Export-ModuleMember -Variable 'globalConfig'

Export-ModuleMember -Variable 'vsWhereVersion'
