# Sql Build Tools 

A bunch of powershell scripts to perform DevOps routines like build, publish and test MSSQL Stack (SQLDB, SSIS, SSAS).

## Installation 
1. Open powershell.
2. Use git tools to clone the sql-build-tools repository to a folder.
```
git clone https://github.com/fenngineering/sql-build-tools.git
```
3. Change directory the tools folder.
```
cd sql-build-tools
```
4. Build the tools. (Might need to run it twice)
```
.\ps-scripts\build.ps1
```
5. Test the tools.
```
..\test.ps1
```
## Setup your solution, with a DB project 
1. CLONE your DB solution into a folder at the same level as sql-build-tools:-
   - ROOT
     - YourSolution
     - Sql-Build-Tools
2. Within your solution create folders:-
   - ps-config
   - ps-templates (ssis solutions only)
3. Create new config psd1 file:-
   - Copy [Sample Config](Samples/ps-config/config.psd1/) to .\YourSolution\ps-config\config.psd1
4. Update your new config psd1 file:-
   - Open .\YourSolution\ps-config\config.psd1 with a text editor
   - Search & Replace Placeholders:-
     - $DB-PROJECTNAME
     - $DATABASE

## Advanced DB projects configuration

### Multiple Database Projects
> The tools are capable of publishing dacpacs from muliple database projects within the solution into seperate databases. Also the tools are capable of publishing dacpacs from muliple database database projects within the solution into a single database in a given order. This can be useful when refactoring objects out of one database project into multiple projects. When there is a set dependency deployment order. A good example of this would be refactoring system CDC objects from the **main** database; you want the solution to build and recognise the CDC systems objects but you **do not** want them to the be published as they are system generared.     
> Another example would be when you want to reuse objects from one database project into another, instead of having multiple defined objects in two database projects, move the dupliate objects into a new database project, then reference the 'global' database project in both database projects.

1. Add multiple DB projects
   - Open .\YourSolution\ps-config\config.psd1 with text editor
   - Add a new item to the DbProjects Collection:-
  ```
  DbProjects = @(
		@{
			ProjectName="AGoodDB_v1"
			DatabaseName="AGoodDB_v1"
			PublishDB=$true
		},
		@{
			ProjectName="AGoodDB_v2.CDC"
			DatabaseName="AGoodDB_v2"
			PublishDB=$false
		}
		,@{
			ProjectName="AGoodDB_v2.Global"
			DatabaseName="AGoodDB_v2"
			PublishDB=$true
		}
		,
		@{
			ProjectName="AGoodDB_v2"
			DatabaseName="AGoodDB_v2"
			PublishDB=$true
		}		
	);
 ``` 
 ### Mulitple Database Environments
 > The tools are capable of building, deploying & testing to multiple environments, the sample.psd1 condig file has the default environment defined [Dev] this is your local environment. However, you can add multiple environemts, which is controlled by the **environment** system varaible, if this is not set the default [Dev] environemnts will **always** be chosen. However, this can be overidden at runtime by passing the **-environmentOverride "<ENV>"** into the powershell script, we'll discuss this later.
 
 2. Adding multiple database environments
   - Open .\YourSolution\ps-config\config.psd1 with a text editor
   - Add a new collection to the base of the config file:-  
 ```
 Dev = @( 
		@{
			IncludeCompositeObjects=$false
			Server="DEV-SERVER"
			Testing = @(
				@{
					Database="AGoodDB"
					UseEnvironmental = 0
					RunTimeOut = 0
					TestTimeOut = 0
				}
			)
		}
	);
 QA = @( 
		@{
			IncludeCompositeObjects=$false
			Server="QA-SERVER"
			Testing = @(
				@{
					Database="AGoodDB"
					UseEnvironmental = 0
					RunTimeOut = 0
					TestTimeOut = 0
				}
			)
		}
	);
 ```
## Build a DB Solution
1. Open powershell.
2. Change directory the solution folder.
```
cd SampleDBSolution
```
3. Ensuring the tools are in the same root folder run the below:-

```
..\sql-build-tools\ps-scripts\build.ps1 -build "DB"
```
This should produce the below:-
```
PS C:\dbgit\fenngineering\SampleDBSolution> ..\sql-build-tools\ps-scripts\build.ps1 -build "DB"
Building Release configuration to environment dev...
Successfully deleted build.zip
Deleting packages folder [C:\dbgit\fenngineering\SampleDBSolution\packages]
Building solution [C:\dbgit\fenngineering\SampleDBSolution\SampleDBSolution.sln]
Installing vswhere package.
Running msbuild with the following args: [C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\MSBuild\15.0\Bin\MSBuild.exe "C:\dbgit\fenngineering\SampleDBSolution\SampleDBSolution.sln" /p:Configuration=Release /p:OutputPath="C:\dbgit\fenngineering\SampleDBSolution\build" /verbosity:quiet /nologo /target:Clean;Build]
Successfully Built [SampleDBSolution.sln] Solution
Created pre-release 0.130.1-pre-release
Successfully created build.zip
                         |\=.
                         /  6'
                 .--.    \  .-'
                /_   \   /  (_()
                  )   | / ;--'
                 /   / /   (
                (    "    _)_
                 -==-'""" "
    ____  __  ________    ____  __________
   / __ )/ / / /  _/ /   / __ \/ ____/ __ \
  / __  / / / // // /   / / / / __/ / /_/ /
 / /_/ / /_/ // // /___/ /_/ / /___/ _, _/
/_____/\____/___/_____/_____/_____/_/ |_|
```
## Publish a DB Solution
1. Open powershell.
2. Change directory the solution folder.
```
cd SampleDBSolution
```
3. Ensuring the tools are in the same root folder run the below:-

```
..\sql-build-tools\ps-scripts\publish.ps1 -publish "DB"
```
This should produce the below:-
```
PS C:\dbgit\fenngineering\SampleDBSolution> ..\sql-build-tools\ps-scripts\publish.ps1 -publish "DB"
Publishing to environment dev...
Is this is a production environment? [False]

Setting Command Variables...

environment

Starting dacpac deployment...
Initializing deployment (Start)
The following SqlCmd variables are not defined in the target scripts: environment.
Initializing deployment (Complete)
Analyzing deployment plan (Start)
Analyzing deployment plan (Complete)
Updating database (Start)
Creating SampleDB...
Update complete.
Updating database (Complete)
                         |\=.
                         /  6'
                 .--.    \  .-'
                /_   \   /  (_()
                  )   | / ;--'
                 /   / /   (
                (    "    _)_
                 -==-'""" "
    ____  __  ________    ____  __________
   / __ )/ / / /  _/ /   / __ \/ ____/ __ \
  / __  / / / // // /   / / / / __/ / /_/ /
 / /_/ / /_/ // // /___/ /_/ / /___/ _, _/
/_____/\____/___/_____/_____/_____/_/ |_|
```
## Setup your solution, with SSIS project
 > Protection Level must not be configured with EncryptAllWithUserKey or EncryptSensitiveWithUserKey
 > If the SSIS project Protection Level is configure with EncryptAllWithPassword or EncryptSensitiveWithPassword, then a Encrypted Password must be configured, to create an Encrypted Passwprd then go to the Other Commands\Encrypt secition.
 > If the SSIS project type is configure with DontSaveSensitive then **no** Encrypted Password is required.
 
 1. CLONE your DB solution into a folder at the same level as sql-build-tools:-
   - ROOT
     - YourSolution
     - Sql-Build-Tools
2. Within your solution create folders:-
   - ps-config
   - ps-templates (ssis solutions only)
3. Create new config psd1 file:-
   - Copy [Sample Config](Samples/ps-config/config.psd1/) to .\YourSolution\ps-config\config.psd1
4. Update your new config psd1 file:-
   - Open .\YourSolution\ps-config\config.psd1 with a text editor
   - Search & Replace Placeholders:-
     - $SSIS-PROJECTNAME
     - $SSIS-FOLDERNAME

### Multiple SSIS Projects
> The tools are capable of publishing ispacs from muliple ssis projects within the solution.

1. Add multiple SSIS projects
   - Open .\YourSolution\ps-config\config.psd1 with text editor
   - Add a new item to the SsisProjects Collection:-
  ```
  SsisProjects = @(
		@{
			ProjectName="DWH_Staging"
			FolderName="DataWarehouse"
			ProtectionLevel="DontSaveSensitive"
			EncryptedPassword = ""
			SecureKeyFile = ""
		},
		@{
			ProjectName="DHW_Build"
			FolderName="DataWarehouse"
			ProtectionLevel="DontSaveSensitive"
			EncryptedPassword = ""
			SecureKeyFile = ""
		}
	);
 ``` 
 ### Mulitple SSIS Environments
 > The tools are capable of building, deploying & testing to multiple environments, the sample.psd1 condig file has the default environment defined [Dev] this is your local environment. However, you can add multiple environemts, which is controlled by the **environment** system varaible, if this is not set the default [Dev] environemnts will **always** be chosen. However, this can be overidden at runtime by passing the **-environmentOverride "<ENV>"** into the powershell script, we'll discuss this later.
 
 2. Adding multiple database environments
   - Open .\YourSolution\ps-config\config.psd1 with a text editor
   - Add a new collection to the base of the config file:-  
 ```
 Dev = @( 
		@{
			IncludeCompositeObjects=$false
			Server="DEV-SERVER"
			SSIS = @(
				@{
					Server="DEV-SSIS-SERVER"
				}
			)
			Testing = @(
				@{
					Database="AGoodDB"
					UseEnvironmental = 0
					RunTimeOut = 0
					TestTimeOut = 0
				}
			)
		}
	);
 QA = @( 
		@{
			IncludeCompositeObjects=$false
			Server="QA-SERVER"
			SSIS = @(
				@{
					Server="QA-SSIS-SERVER"
				}
			)
			Testing = @(
				@{
					Database="AGoodDB"
					UseEnvironmental = 0
					RunTimeOut = 0
					TestTimeOut = 0
				}
			)
		}
	);
## Build a DB Solution
1. Open powershell.
2. Change directory the solution folder.
```
cd SampleSolution
```
3. Ensuring the tools are in the same root folder run the below:-

```
..\sql-build-tools\ps-scripts\build.ps1 -build "DB"
```
This should produce the below:-
```
PS C:\dbgit\fenngineering\SampleDBSolution> ..\sql-build-tools\ps-scripts\build.ps1 -build "DB"
Building Release configuration to environment dev...
Successfully deleted build.zip
Deleting packages folder [C:\dbgit\fenngineering\SampleDBSolution\packages]
Building solution [C:\dbgit\fenngineering\SampleDBSolution\SampleDBSolution.sln]
Installing vswhere package.
Running msbuild with the following args: [C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\MSBuild\15.0\Bin\MSBuild.exe "C:\dbgit\fenngineering\SampleDBSolution\SampleDBSolution.sln" /p:Configuration=Release /p:OutputPath="C:\dbgit\fenngineering\SampleDBSolution\build" /verbosity:quiet /nologo /target:Clean;Build]
Successfully Built [SampleDBSolution.sln] Solution
Created pre-release 0.130.1-pre-release
Successfully created build.zip
                         |\=.
                         /  6'
                 .--.    \  .-'
                /_   \   /  (_()
                  )   | / ;--'
                 /   / /   (
                (    "    _)_
                 -==-'""" "
    ____  __  ________    ____  __________
   / __ )/ / / /  _/ /   / __ \/ ____/ __ \
  / __  / / / // // /   / / / / __/ / /_/ /
 / /_/ / /_/ // // /___/ /_/ / /___/ _, _/
/_____/\____/___/_____/_____/_____/_/ |_|
```
## Publish a DB Solution
1. Open powershell.
2. Change directory the solution folder.
```
cd SampleSolution
```
3. Ensuring the tools are in the same root folder run the below:-

```
..\sql-build-tools\ps-scripts\publish.ps1 -publish "SSIS"
```
This should produce the below:-
```
PS C:\dbgit\fenngineering\SampleDBSolution> ..\sql-build-tools\ps-scripts\publish.ps1 -publish "SSIS"
Publishing to environment dev...
Is this is a production environment? [False]

Setting Command Variables...

environment

Starting dacpac deployment...
Initializing deployment (Start)
The following SqlCmd variables are not defined in the target scripts: environment.
Initializing deployment (Complete)
Analyzing deployment plan (Start)
Analyzing deployment plan (Complete)
Updating database (Start)
Creating SampleDB...
Update complete.
Updating database (Complete)
                         |\=.
                         /  6'
                 .--.    \  .-'
                /_   \   /  (_()
                  )   | / ;--'
                 /   / /   (
                (    "    _)_
                 -==-'""" "
    ____  __  ________    ____  __________
   / __ )/ / / /  _/ /   / __ \/ ____/ __ \
  / __  / / / // // /   / / / / __/ / /_/ /
 / /_/ / /_/ // // /___/ /_/ / /___/ _, _/
/_____/\____/___/_____/_____/_____/_/ |_|
```

## Testing a Solution
 > Testing can only occur on one configured database connection. This is configiured in the Testing section of the Environment collection in  the solution config:-
 ```
 Dev = @(
		@{
			IncludeCompositeObjects=$false
			Server="."
			Testing = @(
				@{
					Database="$DATABASE"
					UseEnvironmental = 0
					RunTimeOut = 0
					TestTimeOut = 0
				}
			)
		}
	); 
 ```
1. Open powershell.
2. Change directory the solution folder.
```
cd SampleDBSolution
```
3. Ensuring the tools are in the same root folder run the below:-

```
..\sql-build-tools\ps-scripts\test.ps1
```
This should produce the below:-
```
PS C:\dbgit\fenngineering\SampleDBSolution> ..\sql-build-tools\ps-scripts\test.ps1
Testing against environment dev... 
Running vstest with the following args: [vstest.console.exe "C:\dbgit\fenngineering\SampleDBSolution\build\SampleDB.SqlTests.dll" /ResultsDirectory:"C:\dbgit\fenngineering\SampleDBSolution\TestResults" /Logger:trx;LogFileName="SampleDB.SqlTests_2019-08-28-10-15-17.trx" /Settings:"C:\dbgit\fenngineering\SampleDBSolution\build\SampleDB.SqlTests.dll.runsettings"]
Microsoft (R) Test Execution Command Line Tool Version 15.9.1
Copyright (c) Microsoft Corporation.  All rights reserved.

Starting test execution, please wait...
Passed   dbo_ATable_UnitTests
Results File: C:\dbgit\fenngineering\SampleDBSolution\TestResults\SampleDB.SqlTests_2019-08-28-10-15-17.trx

Total tests: 1. Passed: 1. Failed: 0. Skipped: 0.
Test Run Successful.
Test execution time: 2.2092 Seconds

Test fixture [C:\dbgit\fenngineering\SampleDBSolution\build\SampleDB.SqlTests.dll] Completed Successfully
Total Failed Tests 0
                         |\=.
                         /  6'
                 .--.    \  .-'
                /_   \   /  (_()
                  )   | / ;--'
                 /   / /   (
                (    "    _)_
                 -==-'""" "
    ____  __  ________    ____  __________
   / __ )/ / / /  _/ /   / __ \/ ____/ __ \
  / __  / / / // // /   / / / / __/ / /_/ /
 / /_/ / /_/ // // /___/ /_/ / /___/ _, _/
/_____/\____/___/_____/_____/_____/_/ |_|
``` 
     
 ## Build\Publish\Test the whole solution
> The tools are also capable of building the whole solution instead of individual project types. All project types supported by **MSBUILD** are compatable with these tools for Building. [MSBUILD info] (https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild-toolset-toolsversion?view=vs-2019).

> For publishing; database, ssis and analysis services projects are supported (with configuration mentioned above)

 ToDo:-
 - [x] Build\Publish\Test your solutuion 
 - [x] Build\Publish a DB project 
 - [x] Advanced DB projects configuration
 - [x] Add sample DB project 
 - [x] Add SSIS project configuration
 - [x] Build\Publish a SSIS project 
 - [x] Advanced SSIS projects configuration
 - [ ] Add sample SSIS project
 - [ ] Build\Publish\Test the Solution
 - [ ] Other commands - Encrypt\Nuget\Package adding The Nuget config section to your config
