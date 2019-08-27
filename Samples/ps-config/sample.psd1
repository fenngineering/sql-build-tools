@{
	SolutionName="$SOLUTION-NAME"
	SqlVersion="130"
	IgnorePackageVersioning= $True
	DbProjects = @(
		@{
			ProjectName="$DB-PROJECTNAME"
			DatabaseName="$DATABASE"
			PublishDB=$true
		}
	);
	Nuget = @(
		@{
			Source = "https://www.nuget.org/api/v2"
			ApiKey = ""
			Name = "Nuget"
		}
	);
	Dev = @(
		@{
			IncludeCompositeObjects=$false
			Server="."
			Database="$DATABASE"
			Testing = @(
				@{
					UseEnvironmental = 0
					RunTimeOut = 0
					TestTimeOut = 0
				}
			)
		}
	);
}