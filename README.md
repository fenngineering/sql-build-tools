# Sql Build Tools 

A bunch of DevOps powershell scripts to build, publish and test SQL Databases & SSIS Packages.

Installation for db project

1) CLONE THE REPO TO A FOLDER AT THE SAME LEVEL AS YOUR SOLUTION:-
  ROOT
  |-> Your Solution
  |-> Sql Build Tools
2) Within your solution create folders:-
  a) ps-config
  b) ps-templates (ssis solutions only)
3) Create new config psd1 file:-
  a) Copy .\samples\ps-config\solution-config.psd1 to .\Your-Solution\ps-config
  b) Rename .\Your-Solution\ps-config\solution-config.psd1 to .\Your-Solution\ps-config\<SolutionFileName-WithoutExt>.psd1
4) Update new config psd1 file:-
  a) Open .\Your-Solution\ps-config\<SolutionFileName-WithoutExt>.psd1 with a text editor
  b) Search & Replace Placeholders:-
    i) $DB-PROJECTNAME
    ii) $DATABASE

Advanced db projects configuration

1) Add multiple db projects
  a) Open .\Your-Solution\ps-config\<SolutionFileName-WithoutExt>.psd1 with text editor
  b) Add a new item to the DbProjects Collection:-
  DbProjects = @(
		@{
			ProjectName="AGoodDBProject"
			DatabaseName="AGoodDB"
			PublishDB=$true
		}
    #, 
		# @{
		#	ProjectName="ANewDBProject"
		#	DatabaseName="ANewDB"
		#	PublishDB=$true
		# }
	);
    
 ToDo:-
 1) Add ssis project configuration
 2) Add multiple environments configuration
