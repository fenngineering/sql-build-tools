
TRUNCATE TABLE [dbo].[ATable]

INSERT INTO [dbo].[ATable] ([ATableDescription])
SELECT CONVERT(VARCHAR(255), NEWID())
FROM master..spt_values v
WHERE number > 0 and number < 11