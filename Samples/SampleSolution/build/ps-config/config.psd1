@{
	SqlVersion="130"
	IgnorePackageVersioning= $True
	SSISDatabaseName="SSISDB"
	DbProjects = @(
		@{
			ProjectName="SampleDB"
			DatabaseName="SampleDB"
			PublishDB=$true
		}
	);
	SsisProjects=@(
		@{
			ProjectName="SampleSSIS"
			FolderName="SampleSSIS"
			ProtectionLevel="DontSaveSensitive"
			EncryptedPassword=""
			SecureKeyFile=""
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
					Database="SampleDB"
					UseEnvironmental = 0
					RunTimeOut = 0
					TestTimeOut = 0
				}
			)
		}
	);
}