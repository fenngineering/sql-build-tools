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
1. CLONE your DB solution into a folder at the sampe level as sql-build-tools:-
   - ROOT
     - YourSolution
     - Sql-Build-Tools
2. Within your solution create folders:-
   - ps-config
   - ps-templates (ssis solutions only)
3. Create new config psd1 file:-
   - Copy [Sample Config](Samples/ps-config/sample.psd1/) to .\YourSolution\ps-config
   - Rename .\YourSolution\ps-config\sample.psd1 to .\YourSolution\ps-config\<YourSolutionFileName-WithoutExt>.psd1
4. Update new config psd1 file:-
   - Open .\YourSolution\ps-config\<YourSolutionFileName-WithoutExt>.psd1 with a text editor
   - Search & Replace Placeholders:-
     - $DB-PROJECTNAME
     - $DATABASE

## Advanced DB projects configuration

### Multiple Database Projects
> The tools are capable of publishing dacpacs from muliple database projects within the solution into seperate databases. Also the tools are capable of publishing dacpas from muliple database database projects within the solution into a single database in a given order. This can be useful when refactoring objects out of one database project into multiple projects. When there is a set dependency deployment order. A good example of this would be refactoring system CDC objects from the **main** database; you want the solution to build and recognise the CDC systems objects but you **do not** want them to the be published as they are system generared.     
> Another example would be when you want to reuse objects from one database project into another, instead of having multiple defined objects in two database projects, move the dupliate objects into a new database project, then reference the 'global' database project in both database projects.

1. Add multiple DB projects
   - Open .\YourSolution\ps-config\<SolutionFileName-WithoutExt>.psd1 with text editor
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
   - Open .\YourSolution\ps-config\<SolutionFileName-WithoutExt>.psd1 with a text editor
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
1. Change directory the solution folder.
```
cd SampleDBSolution
```
2. Ensuring the tools are in the same root folder run the below:-

```
..\sql-build-tools\ps-scripts\build.ps1 -build "DB"
```
This should produce the below:-
```
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

 ## Test a DB Solution
 > Testing can only occur on one configured database connection. This is configiured in the Testing collection of the Environment collection:-
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
 ## Setup your solution, with SSIS project

 To add 
 ToDo:-
 - [x] Build\Publish\Test your solutuion 
 - [x] Advanced DB projects configuration
 - [ ] Build\Publish\Test a DB project 
 - [ ] Add sample DB project 
 - [ ] Add SSIS project configuration
 - [ ] Advanced SSIS projects configuration
 - [ ] Add sample SSIS project
 - [ ] Other commands - Nuget\Package adding The Nuget config section to your config
