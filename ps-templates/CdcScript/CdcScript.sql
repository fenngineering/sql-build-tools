SET NOCOUNT ON

USE $(SourceDatabase)
GO

IF (
      SELECT is_cdc_enabled
      FROM sys.databases
      WHERE name = DB_NAME()
   ) = 1
  BEGIN

	DECLARE @ObjectIDCont INT = 1,
		@ObjectID INT = 0,
		@CaptureInstance SYSNAME = NULL,
		@SourceTableName SYSNAME = NULL,
		@SourceSchemaName SYSNAME = NULL,
		@CapturedColumns NVARCHAR(MAX ) = NULL,
		@SupportsNetChanges CHAR(1),
		@RoleName SYSNAME = NULL,
		@DmlOut NVARCHAR(4000),
		@CRLF NVARCHAR(10) = CHAR(13) + CHAR(10)  + 'GO' + CHAR(13) + CHAR(10)

 	SET @DmlOut = N'USE $(TargetDatabase)' + @CRLF

 	SET @DmlOut = @DmlOut +  N'EXEC sys.sp_cdc_enable_db;' + @CRLF

	WHILE (@ObjectIDCont <> @ObjectID)
		BEGIN

			SELECT TOP 1 @ObjectID = [object_id],
					 @CaptureInstance = capture_instance,
					 @SourceTableName = OBJECT_NAME(source_object_id),
					 @SourceSchemaName = OBJECT_SCHEMA_NAME(source_object_id) ,
					 @SupportsNetChanges = supports_net_changes,
					 @RoleName = role_name
			FROM cdc.change_tables
			WHERE [object_id] > @ObjectIDCont
			ORDER BY [object_id]

			IF(@ObjectID > 0)
				BEGIN
					SET @DmlOut = @DmlOut + N'PRINT N''Enabling CDC FOR ' + @CaptureInstance + '...'';' + @CRLF

					SELECT @CapturedColumns = 
					STUFF((
						SELECT	',' + c.column_name
						FROM [cdc].[captured_columns] c
						WHERE [object_id] = @ObjectID
						FOR XML PATH('') ), 1, 1, 
					'') 

					SET @DmlOut = @DmlOut + N'EXEC sys.sp_cdc_enable_table 
							@source_schema = ''' + @SourceSchemaName + ''', 
							@source_name = ''' + @SourceTableName + ''', 
							@captured_column_list = N''' + @CapturedColumns + ''', 
							@role_name = ' + COALESCE(@RoleName, 'NULL') + ', 
							@supports_net_changes = ' + @SupportsNetChanges + ', 
							@capture_instance = '''+ @CaptureInstance + ''';' + @CRLF

					END


			SET @ObjectIDCont = @ObjectID
			SET @ObjectID = 0

		END
  END

SET @DmlOut = @DmlOut + N'PRINT N''Finished deploying CDC.'';' + @CRLF

SELECT  @DmlOut AS ExtractedCDC