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

1. Add multiple DB projects
   - Open .\YourSolution\ps-config\<SolutionFileName-WithoutExt>.psd1 with text editor
   - Add a new item to the DbProjects Collection:-
  ```
  DbProjects = @(
		@{
			ProjectName="AGoodDBProject"
			DatabaseName="AGoodDB"
			PublishDB=$true
		}
		, 
		@{
			ProjectName="ANewDBProject"
			DatabaseName="ANewDB"
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
