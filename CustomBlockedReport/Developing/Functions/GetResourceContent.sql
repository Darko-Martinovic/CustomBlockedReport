--Drop if exists
IF EXISTS (SELECT
		*
	FROM sys.objects
	WHERE object_id = OBJECT_ID(N'[Bpr].[GetResourceContent]')
	AND type IN (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [Bpr].[GetResourceContent]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Get resource content
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [Bpr].[GetResourceContent] ( @waitResource AS nvarchar(500)
,                                            @tableName as nvarchar(256)
,                                            @paramName as sysname =NULL)
RETURNS nvarchar(max)
AS
BEGIN
	DECLARE @retValue as nvarchar(max)
	DECLARE @blockingType AS nvarchar(20)
	DECLARE @dbId as int
	DECLARE @blockingKey AS nvarchar(256);
	DECLARE @lockRes as nvarchar(20);
	DECLARE @pos1 as int;
	DECLARE @fileId as int;
	DECLARE @pageId as bigint;
	DECLARE @helper1 as nvarchar(500);

SET @retValue = '';
SET @blockingType = RTRIM(SUBSTRING(@waitResource, 1, CHARINDEX(':', @waitResource) - 1));
SET @blockingKey = SUBSTRING(@waitResource, CHARINDEX(':', @waitResource) + 1, LEN(@waitResource) - CHARINDEX(':', @waitResource));
SET @dbId = SUBSTRING(@blockingKey, 1, CHARINDEX(':', @blockingKey) - 1);
    IF @blockingType != 'KEY' AND @blockingType != 'PAGE'
	    RETURN @retValue
 
	IF @paramName IS NOT NULL
		BEGIN
SET @retValue = 'SET ' + @paramName + ' = (';
		END
	--Blocking type is KEY
	IF @blockingType = 'KEY'
	BEGIN

SET @lockRes = LTRIM(SUBSTRING(@blockingKey, CHARINDEX('(', @blockingKey) - 1, CHARINDEX(')', @blockingKey) - CHARINDEX('(', @blockingKey) + 2));

SET @retValue = @retValue +
'SELECT *
	                    FROM ' + DB_NAME(@dbId) + '.' + @tableName + ' (NOLOCK) 
					WHERE %%lockres%% = ''' + @lockRes + '''' + ' FOR XML AUTO';
	END

	--Blocking type is PAGE
	ELSE IF @blockIngType = 'PAGE'
		BEGIN
SET @pos1 = CHARINDEX(':', @blockingKey) + 1;
SET @helper1 = SUBSTRING(@blockingKey, @pos1, 100);
SET @fileId = SUBSTRING(@helper1, 1, CHARINDEX(':', @helper1) - 1);
SET @pageId = CAST(SUBSTRING(@helper1, CHARINDEX(':', @helper1) + 1, LEN(@helper1) - CHARINDEX(':', @helper1)) AS BIGINT)
SET @lockRes = '(' + CAST(@fileId AS NVARCHAR(10)) + ':' + CAST(@pageid AS NVARCHAR(MAX)) + '%'

SET @retValue = @retValue +
'SELECT *
				     FROM ' + DB_NAME(@dbId) + '.' + @tableName + ' (NOLOCK) 
					WHERE sys.fn_PhysLocFormatter(%%physloc%%) like  ''' + @lockRes + '''' + ' FOR XML AUTO';

		END
		IF @paramName IS NOT NULL
		BEGIN
SET @retValue = @retValue + ')'
		END
	RETURN @retvalue;

END

GO
