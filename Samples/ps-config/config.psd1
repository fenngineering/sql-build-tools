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
	SsisProjects=@(
		@{
			ProtectionLevel="DontSaveSensitive"
			EncryptedPassword = ""
			SecureKeyFile = ""
			ProjectName="$SSIS-PROJECTNAME"
			FolderName="$SSIS-FOLDERNAME"
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
			SSIS = @(
				@{
					Server="."
				}
			)
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
}