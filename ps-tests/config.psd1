@{
   SolutionName="SqlBuildTools"
   SqlVersion="140"
   SSASVersion="140"
   EnableNuGetPackageRestore=$true
   IgnorePackageVersioning=$True
   DbProjects = @(
        @{
            ProjectName="SqlBuildTools.DB"
            DatabaseName="SqlBuildTools"
            PublishDB=$True
        }
   );
   Nuget = @(
      @{
         Source = ""
         Name=""
		 ApiKey = ""
      }
   );
   Dev = @(
      @{
		 IncludeCompositeObjects=$False
         Server="."
         Database ="SqlBuildTools"
         Testing = @(
            @{
                RunTimeOut = 0
                TestTimeOut = 0
            }
         )
       }
   );
   CI = @(
      @{
		 IncludeCompositeObjects=$False
         Server="DEV-SQL-01"
         Database ="SqlBuildTools"
         Testing = @(
            @{
                RunTimeOut = 0
                TestTimeOut = 0
            }
         )
       }
   );
   QA = @(
      @{
		 IncludeCompositeObjects=$False
         Server="DEV-SQL-02"
         Database ="SqlBuildTools"
         Testing = @(
            @{
                RunTimeOut = 0
                TestTimeOut = 0
            }
         )
       }
   );
   Live = @(
      @{
		 IncludeCompositeObjects=$False
         Server="."
         Database ="SqlBuildTools"
         Testing = @(
            @{
                RunTimeOut = 0
                TestTimeOut = 0
            }
         )
       }
   );
}
