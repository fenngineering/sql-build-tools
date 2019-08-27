# Sql Build Tools 

A bunch of powershell scripts to perform DevOps routines like build, publish and test MSSQL Stack (SQLDB, SSIS, SSAS).

## Installation for DB project

1. CLONE the sql-build-tools repository to a folder at the sample level as your solution:-
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
    
Advanced DB projects configuration

> The tools are capable of publishing dacpacs from muliple composite db projects in the given order, can this is useful when refactoring objects out of one database project into multiple projects. When there is a set dependency deployment order. A good example of this would be refactoring system CDC objects from the main database; you want the solution to build and recognise the CDC systems objects but you **do not** want them to the be published as they are system generared.     
> Another example would be when you want to reuse objects from one database project in another, instead of having multiple defined objects in two database projects, move the dupliate objects into a new database project, then refernce the 'shared' database project in both database projects, usually in this situation I would call the 'shared' database project a Global composite project.

1. Add multiple DB projects
   - Open .\YourSolution\ps-config\<SolutionFileName-WithoutExt>.psd1 with text editor
   - Add a new item to the DbProjects Collection:-
  ```
  DbProjects = @(
		@{
			ProjectName="ANewDBProject.CDC"
			DatabaseName="AGoodDB"
			PublishDB=$false
		}
		,@{
			ProjectName="ANewDBProject.Global"
			DatabaseName="AGoodDB"
			PublishDB=$true
		}
		,
		@{
			ProjectName="AGoodDBProject"
			DatabaseName="AGoodDB"
			PublishDB=$true
		}		
	);
 ``` 
 2. Add multiple DB environments
 *The tools enable deployment & test to multiple environments, the sample.psd1 condig file has the default environment defined [Dev]*
   - Open .\YourSolution\ps-config\<SolutionFileName-WithoutExt>.psd1 with a text editor
   - Add a new collection to the base of the config file:-  
 ```
 Dev = @( 
		@{
			IncludeCompositeObjects=$false
			Server="DEV-SERVER"
			Database="AGoodDB"
			Testing = @(
				@{
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
			Database="AGoodDB"
			Testing = @(
				@{
					UseEnvironmental = 0
					RunTimeOut = 0
					TestTimeOut = 0
				}
			)
		}
	);
 ```
 To add 
 ToDo:-
 - [ ] Add SSIS project configuration
 - [x] Add multiple DB environments configuration
 - [ ] Add sample DB project 
 - [ ] Add sample SSIS project 
