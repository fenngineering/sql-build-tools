<#
.SYNOPSIS  
    This script will provide an interface to DacFX     
.NOTES
  Version:        1.0
  Author:         Andrew J Fenna
  Creation Date:  01/10/2016
  Purpose/Change: Initial script development
#>
[CmdletBinding()]
param(
)

function New-AppDomain{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$appBase
	)
    process{
		try
		{
			$ads = [AppDomain]::CurrentDomain.SetupInformation
			#$ads = New-Object System.AppDomainSetup
			$env = [AppDomain]::CurrentDomain.Evidence
			$ads.ApplicationBase = $appBase
			[System.AppDomain]$script:newDomain = [System.AppDomain]::CreateDomain([System.Guid]::NewGuid().ToString(), $null, $ads);
			
			Load-AssemblyInAppDomain -domain $script:newDomain -assembly "mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089";
			Load-AssemblyInAppDomain -domain $script:newDomain -assembly "Microsoft.PowerShell.ConsoleHost, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35";
			Load-AssemblyInAppDomain -domain $script:newDomain -assembly "System, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089";
			Load-AssemblyInAppDomain -domain $script:newDomain -assembly "System.Core, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089";
			Load-AssemblyInAppDomain -domain $script:newDomain -assembly "System.Management.Automation, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35";
			Load-AssemblyInAppDomain -domain $script:newDomain -assembly "Microsoft.Management.Infrastructure, Version=1.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35";
			Load-AssemblyInAppDomain -domain $script:newDomain -assembly "System.Management, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a";
			Load-AssemblyInAppDomain -domain $script:newDomain -assembly "System.DirectoryServices, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a";
			Load-AssemblyInAppDomain -domain $script:newDomain -assembly "System.Xml, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089";
			Load-AssemblyInAppDomain -domain $script:newDomain -assembly "System.Numerics, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089";
			Load-AssemblyInAppDomain -domain $script:newDomain -assembly "System.Data, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089";
			#Load-AssemblyInAppDomain -domain $script:newDomain -assembly "Anonymously Hosted DynamicMethods Assembly, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null";
			Load-AssemblyInAppDomain -domain $script:newDomain -assembly "Microsoft.PowerShell.Security, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35";
			Load-AssemblyInAppDomain -domain $script:newDomain -assembly "System.Transactions, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089";
			Load-AssemblyInAppDomain -domain $script:newDomain -assembly "System.Configuration, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a";
			Load-AssemblyInAppDomain -domain $script:newDomain -assembly "Microsoft.PowerShell.Commands.Utility, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35";
			Load-AssemblyInAppDomain -domain $script:newDomain -assembly "System.Configuration.Install, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a";
			Load-AssemblyInAppDomain -domain $script:newDomain -assembly "Microsoft.PowerShell.Commands.Management, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35";
			Load-AssemblyInAppDomain -domain $script:newDomain -assembly "System.IO.Compression.FileSystem, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089";
			Load-AssemblyInAppDomain -domain $script:newDomain -assembly "System.IO.Compression, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089";

			Write-Verbose "Created child domain: $($newDomain.FriendlyName)"
		}
		catch [System.Exception]
		{
			Write-Error "Message: $($_.Exception.Message)"
			Write-Error "StackTrace: $($_.Exception.StackTrace)"
			$PSCmdlet.ThrowTerminatingError($PSitem)
		}
	}
}

function Register-DacServices{
    [cmdletbinding()]
        param()
        process{	

			#if($(Confirm-DacFxInstalled) -ne $true )

			if($(Confirm-AssemblyInAppDomain -domain $([AppDomain]::CurrentDomain) -assembly "Microsoft.SqlServer.Dac") -eq $false)
			{
				#TODO: Investigate loading dlls into new appdomain so that when finished the dlls can be unloaded with the new appDomain
				
				#[AppDomain]::CurrentDomain.Load("System.Runtime, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a");	
				#$loader = $(Get-File -path $packagesPath -fileName "SqlBuildTools.DacLoader.dll")
				##register the loader
				#Import-Module $loader.FullName -Scope Local
				#$(New-AppDomain -appBase $dacFxPath)


				$dacDomPath = $(Get-File -path "$($toolsPath)\build\" -fileName "Microsoft.SqlServer.TransactSql.ScriptDom.dll")
				$dacFxExtPath = $(Get-File -path "$($toolsPath)\build\" -fileName "Microsoft.SqlServer.Dac.Extensions.dll") 
				$dacFxToolsath = $(Get-File -path "$($toolsPath)\build\" -fileName "Microsoft.Data.Tools.Utilities.dll") 
				$dacFxPath = $(Get-File -path "$($toolsPath)\build\" -fileName "Microsoft.SqlServer.Dac.dll")
				$dacFxConts = $(Get-File -path "$($toolsPath)\build\" -fileName "SqlBuildTools.Contributors.dll")
			
				#Load-AssemblyInAppDomain -domain $script:newDomain -assembly $([System.Reflection.AssemblyName]::GetAssemblyName($dacDomPath.FullName))
				#Load-AssemblyInAppDomain -domain $script:newDomain -assembly $dacFxExtPath.FullName
				#Load-AssemblyInAppDomain -domain $script:newDomain -assembly $dacFxToolsath.FullName
				#Load-AssemblyInAppDomain -domain $script:newDomain -assembly $dacFxPath.FullName
				#Load-AssemblyInAppDomain -domain $script:newDomain -assembly $dacFxConts.FullName

				Import-AssemblyInAppDomain -domain $([AppDomain]::CurrentDomain) -assembly $([System.Reflection.AssemblyName]::GetAssemblyName($dacDomPath.FullName))
				Import-AssemblyInAppDomain -domain $([AppDomain]::CurrentDomain) -assembly $([System.Reflection.AssemblyName]::GetAssemblyName($dacFxExtPath.FullName))
				Import-AssemblyInAppDomain -domain $([AppDomain]::CurrentDomain) -assembly $([System.Reflection.AssemblyName]::GetAssemblyName($dacFxToolsath.FullName))
				Import-AssemblyInAppDomain -domain $([AppDomain]::CurrentDomain) -assembly $([System.Reflection.AssemblyName]::GetAssemblyName($dacFxPath.FullName))
				Import-AssemblyInAppDomain -domain $([AppDomain]::CurrentDomain) -assembly $([System.Reflection.AssemblyName]::GetAssemblyName($dacFxConts.FullName))
			}
			return $(Confirm-AssemblyInAppDomain -domain $([AppDomain]::CurrentDomain) -assembly "Microsoft.SqlServer.Dac")
        }
}

function Unregister-DacServices{
    [cmdletbinding()]
        param()
        process{		
			#[AppDomain]::Unload($script:newDomain)
			#Remove-Library -library "Microsoft.SqlServer.Dac"
			#Remove-Library -library "Microsoft.SqlServer.Dac.Extensions"
			#Remove-Library -library "Microsoft.Data.Tools.Utilities"
			#Remove-Library -library "SqlBuildTools.Contributors"
			Unregister-Event -SourceIdentifier $script:DacMessageEvent.Name
        }
}

function Get-DacServices{
    [cmdletbinding()]
        param(
            [Parameter(Mandatory=$True)]
            [string]$serverName,
            [Parameter(Mandatory=$True)]
            [string]$databaseName
        )
        process{

            if($(Register-DacServices) -eq $True) {

				$connectionString = $(Get-ConnectionString -serverName $serverName -databaseName $databaseName)

				$dacServices = New-Object Microsoft.SqlServer.Dac.DacServices $connectionString

				#Register-ObjectEvent -InputObject $dacServices -EventName "Message" -Action { Write-Host $EventArgs.Message.Message} | Out-Null

				$script:DacMessageEvent = Register-ObjectEvent -InputObject $dacServices -EventName "Message" -Action { 
					$message = $EventArgs.Message.Message
					$colour = "DarkGray"
					if ($message -contains "Error SQL")
					{
						$colour = "Red"
					}

					Write-Host $message -ForegroundColor $colour
				}

				#Register-ObjectEvent -InputObject $dacServices -EventName "ProgressChanged" -Action { Write-Host $EventArgs.ProgressChanged.Message } | Out-Null

				return $dacServices
            }
        }
}

function Write-EventToConsole ($evt)
{
    Write-Host $Evt.MessageData
    Write-Host $Evt.Sender
    Write-Host $Evt.TimeGenerated      
    Write-Host $Evt.SourceArgs
}

function Export-DeployScript{
    [cmdletbinding()]
        param(
		    [Parameter(Mandatory=$True)]
            [string]$targetDatabaseName ,
            [Parameter(Mandatory=$True)]
            [string]$sourceDacPac,
			[Parameter(Mandatory=$False)]
            [string]$targetDacPac,
            [Parameter(Mandatory=$False)]
            [bool]$dropObjectsNotInSource,
            [Parameter(Mandatory=$False)]
            [bool]$includeCompositeObjects,
			[Parameter(Mandatory=$False)]
            [string]$dataPath,
			[Parameter(Mandatory=$False)]
            [string]$logPath
        )
        process{

			if(Register-DacServices) {

				try {
					Write-Host "Starting generating change script..."

					$deployOptions = New-Object Microsoft.SqlServer.Dac.DacDeployOptions -Property @{
						'DropObjectsNotInSource' = $dropObjectsNotInSource;
						'IncludeCompositeObjects' = $includeCompositeObjects;
						'BlockOnPossibleDataLoss' = $False;
						'VerifyDeployment' = $False;
						'IgnoreFileAndLogFilePath'= $True;
						'IgnoreFilegroupPlacement'= $True;
						'IgnoreFileSize' = $True;
						'IgnoreFillFactor' = $True;
						##'DoNotAlterReplicatedObjects' = $True;
						'ScriptDatabaseOptions' = $False;
						'IgnoreRoleMembership' = $True;
						'IgnoreUserSettingsObjects' = $True;
						'IgnorePermissions' = $True;
						'IgnoreLoginSids' = $True;
						'DoNotAlterChangeDataCaptureObjects' = $True;
						'IgnoreAuthorizer' = $True;
						'ScriptRefreshModule' = $False;
						'IgnoreNotForReplication' = $True;
						'IgnoreComments' = $False;		
						'IgnoreAnsiNulls' = $True;		
						'IgnoreIndexPadding' = $True;
						'IgnoreKeywordCasing' = $True;
						'IgnoreWhitespace' = $True;
						'IgnoreSemicolonBetweenStatements' = $True;
						'UnmodifiableObjectWarnings' = $True;
						'IgnoreColumnOrder' = $True;
						'IgnoreQuotedIdentifiers' = $True;
						'IgnoreIndexOptions' = $True;
						'IgnoreTableOptions' = $True;
						'IgnoreFullTextCatalogFilePath' = $True;
						'IgnoreIdentitySeed' = $True;
						'IgnoreIncrement' = $True;
						'IncludeTransactionalScripts' = $False
						'ExcludeObjectTypes' = "Users", "Logins", "RoleMembership" ,"ExtendedProperties"
					}

					<#

						Aggregates, ApplicationRoles, Assemblies, AsymmetricKeys, BrokerPriorities, Certificates, 
					    Contracts, DatabaseRoles, DatabaseTriggers, Defaults, ExtendedProperties, Filegroups, FileTables, 
						FullTextCatalogs, FullTextStoplists, MessageTypes, PartitionFunctions, PartitionSchemes, Permissions, 
						Queues, RemoteServiceBindings, RoleMembership, Rules, ScalarValuedFunctions, SearchPropertyLists, 
						Sequences, Services, Signatures, StoredProcedures, SymmetricKeys, Synonyms, Tables, TableValuedFunctions, 
						UserDefinedDataTypes, UserDefinedTableTypes, ClrUserDefinedTypes, Users, Views, XmlSchemaCollections, Audits, 
						Credentials, CryptographicProviders, DatabaseAuditSpecifications, Endpoints, ErrorMessages, EventNotifications, 
						EventSessions, LinkedServerLogins, LinkedServers, Logins, Routes, ServerAuditSpecifications, ServerRoleMembership,
						ServerRoles, ServerTriggers.

					#>

					$deployOptions.AdditionalDeploymentContributors = "SqlBuildTools.Contributors.LocationModifier;SqlBuildTools.Contributors.IgnoreSchemas"

					$contArgs = New-Object 'System.Collections.Generic.Dictionary[String,String]'
					$contArgs.Add("LocationModifier.DatabaseName", $targetDatabaseName)
					$contArgs.Add("LocationModifier.DataLocation", $dataPath)
					$contArgs.Add("LocationModifier.LogLocation", $logPath)
					$contArgs.Add("IgnoreSchemas.Schemas", $config.ExcludedSchemas)

					$deployOptions.AdditionalDeploymentContributorArguments = [SqlBuildTools.Contributors.Utils]::BuildContributorArguments($contArgs)

					$sqlCmdVars = New-Object 'System.Collections.Generic.Dictionary[String,String]'

                    
					foreach($ht in $global:sqlCommandVariables )
					{
						foreach ($i in $ht.keys)
						{
							$deployOptions.SqlCommandVariableValues.Add($i,$ht[$i])
						}                        
					}

					$sourcePackage = [Microsoft.SqlServer.Dac.DacPackage]::Load($sourceDacPac)

					if($targetDacPac)
					{
						$targetPackage = [Microsoft.SqlServer.Dac.DacPackage]::Load($targetDacPac)

						$deployScript = [Microsoft.SqlServer.Dac.DacServices]::GenerateDeployScript($sourcePackage, $targetPackage, $targetDatabaseName, $deployOptions)

						return $deployScript
					}
					else
					{
						Write-Host "Target dacpac not available, generating create database script..."

						$deployOptions.CreateNewDatabase = $True
						$deployOptions.CompareUsingTargetCollation = $False

						$deployOptions.AdditionalDeploymentContributors = [SqlBuildTools.Contributors.LocationModifier]::ContributorId+";"+[SqlBuildTools.Contributors.DropDatabaseRemover]::ContributorId

						$createScript = [Microsoft.SqlServer.Dac.DacServices]::GenerateCreateScript($sourcePackage, $targetDatabaseName, $deployOptions)

						return $createScript
					}
						
				} catch {
					$PSCmdlet.ThrowTerminatingError($PSitem)
					return $False
				}
				finally {
					Unregister-DacServices				
				}
			}
			return $null
		}
}

function Export-DropDbScript{
    [cmdletbinding()]
        param(
		    [Parameter(Mandatory=$True)]
            [string]$targetDatabaseName ,
            [Parameter(Mandatory=$True)]
            [string]$sourceDacPac
        )
        process{

			if(Register-DacServices) {

				try {
					Write-Host "Starting generating drop database script..."

					$deployOptions = New-Object Microsoft.SqlServer.Dac.DacDeployOptions -Property @{
						'CreateNewDatabase' = $True;
					}

					$sqlCmdVars = New-Object 'System.Collections.Generic.Dictionary[String,String]'
                    
					foreach($ht in $global:sqlCommandVariables )
					{
						foreach ($i in $ht.keys)
						{
							$deployOptions.SqlCommandVariableValues.Add($i,$ht[$i])
						}                        
					}

                    $sourcePackage = [Microsoft.SqlServer.Dac.DacPackage]::Load($sourceDacPac)

					$deployOptions.AdditionalDeploymentContributors = [SqlBuildTools.Contributors.DropDatabase]::ContributorId

					$dropDatabaseScript = [Microsoft.SqlServer.Dac.DacServices]::GenerateCreateScript($sourcePackage, $targetDatabaseName, $deployOptions)

					return $dropDatabaseScript
						
				} catch {
					$PSCmdlet.ThrowTerminatingError($PSitem)
					return $False
				}
			}
			return $null
		}
}

function Export-Database{
    [cmdletbinding()]
        param(
            [Parameter(Mandatory=$True)]
            [string]$sourceServerName,
            [Parameter(Mandatory=$True)]
            [string]$sourceDatabaseName,
            [Parameter(Mandatory=$True)]
            [string]$targetDatabaseName
        )
        process{

			$extractedDacPac = $(Join-Path $solutionPath "Extracted.dacpac")
			            
            if($(Export-DacPac -sourceServerName $sourceServerName -sourceDatabaseName $sourceDatabaseName -targetDacPac $extractedDacPac) -eq " 0") {

				$extractedCdc = (Export-Cdc -dataSource $sourceServerName -sourceDatabaseName $sourceDatabaseName -targetDatabaseName $targetDatabaseName)

				Import-Module zip

				Invoke-ZipCreatePart -zipFilePath $extractedDacPac -file $extractedCdc -mimeType "plain/text"

	            return $extractedDacPac
			}
			return $null
        }
}

function Export-DacPac{
    [cmdletbinding()]
        param(
            [Parameter(Mandatory=$True)]
            [string]$sourceServerName,
            [Parameter(Mandatory=$True)]
            [string]$sourceDatabaseName,
            [Parameter(Mandatory=$True)]
            [string]$targetDacPac
        )
        process{

            $dacServices = Get-DacServices -serverName $sourceServerName -databaseName $sourceDatabaseName

			$version = "1.2.3.4"

            if($dacServices -ne $null) {

                $extractOptions = New-Object Microsoft.SqlServer.Dac.DacExtractOptions -Property @{
                    'IgnorePermissions' = $True;
                    'IgnoreUserLoginMappings' = $True;
                }
                try {                    

                    Write-Host "Starting dacpac extract from $sourceDatabaseName..."

                    $dacServices.Extract($targetDacPac, $sourceDatabaseName, $sourceDatabaseName, $version,  $null, $null, $extractOptions)

                    Write-Host "Dacpac export succeeded!"

                    return $true
                }
                catch {
                    $PSCmdlet.ThrowTerminatingError($PSitem)
                    return $null
                }
            }
            return $null

        }
}

function Export-Cdc{
    [cmdletbinding()]
        param(
            [Parameter(Mandatory=$True)]
            [string]$dataSource,
            [Parameter(Mandatory=$True)]
            [string]$sourceDatabaseName,
            [Parameter(Mandatory=$True)]
            [string]$targetDatabaseName
        )
        process{

            $extractedCdc = "$(Join-Path $solutionPath "ExtractedCdc.sql")"
            
            $cmdVars = "SourceDatabase=$sourceDatabaseName", "TargetDatabase=$targetDatabaseName"

            try {

                Import-Module nuget

				if($(Install-SqlServerModule) -eq $False) {
                    Write-Error "Unable to SqlServer Module ."
                    return  $False
                }
				Remove-Module -Name nuget
                    
                Import-Module SqlServer -Force -DisableNameChecking

                $output = (Invoke-SqlCmd -ServerInstance $dataSource -InputFile "$(Join-Path $toolsPath "ps-templates\CdcScript\CdcScript.sql")" -OutputAs DataRows -Variable $cmdVars -Host)
        
                [IO.File]::WriteAllText($extractedCdc, $output[0], [System.Text.Encoding]::UTF8)

                return $extractedCdc
            }
            catch {
                $PSCmdlet.ThrowTerminatingError($PSitem)
                return $null
            }
        }
}

function Publish-Database{
    [cmdletbinding()]
        param(
            [Parameter(Mandatory=$True)]
            [string]$connectionString,
            [Parameter(Mandatory=$True)]
            [string]$targetDatabaseName,
            [Parameter(Mandatory=$False)]
            [bool]$createDatabase = $False,
            [Parameter(Mandatory=$True)]
            [string]$sourceDacPac,
            [Parameter(Mandatory=$True)]
            [bool]$includeCompositeObjects
        )
        process{

            if(Register-DacServices) {         
            
                Publish-DacPac -connectionString $connectionString -sourceDacPac $sourceDacPac -targetDatabaseName $targetDatabaseName -deployType "tables" -createDatabase $createDatabase -includeCompositeObjects $includeCompositeObjects

                Publish-SqlScripts -connectionString $connectionString -sourceDacPac $sourceDacPac -databaseName $targetDatabaseName
                       
                Publish-DacPac -connectionString $connectionString -sourceDacPac $sourceDacPac -targetDatabaseName $targetDatabaseName -deploy "objects" -includeCompositeObjects $includeCompositeObjects
            }
        }
}

function Publish-SqlScripts{
    [cmdletbinding()]
        param(
            [Parameter(Mandatory=$True)]
            [string]$connectionString,
            [Parameter(Mandatory=$True)]
            [string]$sourceDacPac,
            [Parameter(Mandatory=$True)]
            [string]$databaseName
        )
        process{

            $files = Invoke-ZipGetStreams -zipFilePath $sourceDacPac -extention ".sql"

            ForEach($file in $files){
                Import-Module nuget

				if($(Install-SqlServerModule) -eq $False) {
                    Write-Error "Unable to SqlServer Module ."
                    return  $False
                }
				Remove-Module -Name nuget
                    
                Import-Module SqlServer -Force -DisableNameChecking

				$connectionBuilder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder($connectionString);            
				
				Invoke-Sql -dataSource $connectionBuilder.DataSource -databaseName $databaseName -query $file
            }
        }
}

function Publish-DacPac{
    [cmdletbinding()]
        param(
            [Parameter(Mandatory=$True)]
            [string]$targetServerName,
            [Parameter(Mandatory=$True)]
            [string]$sourceDacPac,
            [Parameter(Mandatory=$True)]
            [string]$targetDatabaseName,
            [Parameter(Mandatory=$False)]
            [string]$deployType,
            [Parameter(Mandatory=$True)]
            [bool]$includeCompositeObjects,
            [Parameter(Mandatory=$False)]
            [bool]$createDatabase = $False,
            [Parameter(Mandatory=$False)]
            [bool]$generateDeployScript = $False,
			[Parameter(Mandatory=$False)]
            [string]$dataPath,
			[Parameter(Mandatory=$False)]
            [string]$logPath
        )
        process{
                $dacServices = Get-DacServices -serverName $targetServerName -databaseName $targetDatabaseName

                if($dacServices -ne $null) {

                    try {
                        $sourcePackage = [Microsoft.SqlServer.Dac.DacPackage]::Load($sourceDacPac)

                        switch($deployType)
                        {
                            "tables" {
                                $deployOptions = New-Object Microsoft.SqlServer.Dac.DacDeployOptions -Property @{
                                    'DoNotAlterChangeDataCaptureObjects' = $False;
									'DoNotAlterReplicatedObjects' = $False;
                                    'CreateNewDatabase' = $createDatabase;
                                    'ExcludeObjectTypes' = "Logins","Users","RoleMembership","Services","RemoteServiceBindings", "StoredProcedures", "TableValuedFunctions", "Queues";
                                    'VerifyDeployment' = $False;
                                }
                            }
                            "objects" {   
                                $deployOptions = New-Object Microsoft.SqlServer.Dac.DacDeployOptions -Property @{
                                    'DoNotAlterChangeDataCaptureObjects' = $False;
									'DoNotAlterReplicatedObjects' = $False;
                                    'ExcludeObjectTypes' = "Logins","Users","RoleMembership","Services","RemoteServiceBindings";
                                    'VerifyDeployment' = $False;
                                }
                            }
                            default {
                                $deployOptions = New-Object Microsoft.SqlServer.Dac.DacDeployOptions -Property @{
									'DropObjectsNotInSource' = $dropObjectsNotInSource;
									'IncludeCompositeObjects' = $includeCompositeObjects;
									'BlockOnPossibleDataLoss' = $False;
									'VerifyDeployment' = $False;
									#'DropConstraintsNotInSource' = $False;
									'DoNotAlterReplicatedObjects' = $False;
									'ScriptDatabaseOptions' = $False;
									'IgnoreFileAndLogFilePath'= $True;
									'IgnoreRoleMembership' = $True;
									'IgnoreUserSettingsObjects' = $True;
									'IgnorePermissions' = $True;
									'IgnoreLoginSids' = $True;
									'DoNotAlterChangeDataCaptureObjects' = $False;
									'IgnoreAuthorizer' = $True;
									'ScriptRefreshModule' = $True;
									'IgnoreNotForReplication' = $True;
									'IgnoreComments' = $True;		
									'IgnoreAnsiNulls' = $True;		
									'IgnoreIndexPadding' = $True;
									'IgnoreKeywordCasing' = $True;
									'IgnoreWhitespace' = $True;
									'IgnoreSemicolonBetweenStatements' = $True;
									'UnmodifiableObjectWarnings' = $True;
									'IgnoreColumnOrder' = $True;
                                    'CreateNewDatabase' = $createDatabase;
									##'IgnoreIndexOptions' = $False;
									##'IgnoreTableOptions' = $True;
									'ExcludeObjectTypes' = "Users", "Logins", "RoleMembership" ,"ExtendedProperties"
								}
                            }
                        }

						if($dataPath -ne $null) 
						{
							$deployOptions.AdditionalDeploymentContributors = [SqlBuildTools.Contributors.LocationModifier]::ContributorId

							$contArgs = New-Object 'System.Collections.Generic.Dictionary[String,String]'
							$contArgs.Add("LocationModifier.DatabaseName", $targetDatabaseName)
							$contArgs.Add("LocationModifier.DataLocation", $dataPath)
							$contArgs.Add("LocationModifier.LogLocation", $logPath)

							$deployOptions.AdditionalDeploymentContributorArguments = [SqlBuildTools.Contributors.Utils]::BuildContributorArguments($contArgs)
						}

						Write-Host ""
						Write-Host "Setting Command Variables... "
                        Write-Host ""

						Write-Host "environment"

						$deployOptions.SqlCommandVariableValues.Add("environment", $environment)

						foreach($ht in $global:sqlCommandVariables )
						{
							foreach ($i in $ht.keys)
							{
								$deployOptions.SqlCommandVariableValues.Add($i,$ht[$i])
								Write-Host "$i"
							}                        
						}

                        Write-Host ""
                        Write-Host 'Starting dacpac deployment...'

						if($generateDeployScript) {
								
							$deployTemplate = "$(Join-Path $toolsPath "ps-templates\SqlScripts\DeployScript.eps")"
            
							$deployScript = $dacServices.GenerateDeployScript($sourcePackage, $targetDatabaseName, $deployOptions, $null)
							
							Import-Module EPS -Force -DisableNameChecking            
							Import-Module git

							New-Item "$(Join-Path $solutionPath "$([System.IO.Path]::GetFileNameWithoutExtension($sourceDacPac))_DeployScript.sql")" -type file -force -value $(Expand-Template -file $deployTemplate -binding @{ databaseName = $targetDatabaseName; version = $(Invoke-GetVersion); config = $config; DeployScript = $deployScript;}) | Out-Null

							Remove-Module -name EPS
							Remove-Module -name git
						}
						else {
						
							$dacServices.Deploy($sourcePackage, $targetDatabaseName, $True, $deployOptions, $null)

						}
                        $sourcePackage.Dispose()

                        return $True

                    } catch [Microsoft.SqlServer.Dac.DacServicesException] {
						Write-Host "Dacpac deployment failed! $($_.Exception.ToString())" -foregroundcolor "red"
                        $PSCmdlet.ThrowTerminatingError($PSitem)
                        return $False
                    } catch {
						Write-Host "Dacpac deployment failed! $($_.Exception.Message)" -foregroundcolor "red"
						$PSCmdlet.ThrowTerminatingError($PSitem)
                        return $False
					}
					finally {
						Unregister-DacServices				
					}
                }
                else {
                    return $False
                }                
        }
}

Export-ModuleMember -Function 'Export-DeployScript'

Export-ModuleMember -Function 'Export-RollbackScript'

Export-ModuleMember -Function 'Extract-DropDbScript'

Export-ModuleMember -Function 'Export-Database'

Export-ModuleMember -Function 'Export-DacPac'

Export-ModuleMember -Function 'Publish-Database'

Export-ModuleMember -Function 'Publish-DacPac'

Export-ModuleMember -Function 'Register-DacServices'