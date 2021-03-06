--Drop if exists
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[Bpr].[GetResourceContent]')
          AND type IN(N'FN', N'IF', N'TF', N'FS', N'FT')
)
    DROP FUNCTION [Bpr].[GetResourceContent];
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- =============================================
-- Get resource content
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [Bpr].[GetResourceContent]
(@waitResource AS NVARCHAR(500),
 @tableName AS    NVARCHAR(256),
 @paramName AS    SYSNAME       = NULL
)
RETURNS NVARCHAR(MAX)
AS
     BEGIN
         DECLARE @retValue AS NVARCHAR(MAX);
         DECLARE @blockingType AS NVARCHAR(20);
         DECLARE @dbId AS INT;
         DECLARE @blockingKey AS NVARCHAR(256);
         DECLARE @lockRes AS NVARCHAR(20);
         DECLARE @pos1 AS INT;
         DECLARE @fileId AS INT;
         DECLARE @pageId AS BIGINT;
         DECLARE @helper1 AS NVARCHAR(500);
         DECLARE @columns AS NVARCHAR(MAX)='';
         SET @retValue = '';
         SET @blockingType = RTRIM(SUBSTRING(@waitResource, 1, CHARINDEX(':', @waitResource)-1));
         SET @blockingKey = SUBSTRING(@waitResource, CHARINDEX(':', @waitResource)+1, LEN(@waitResource)-CHARINDEX(':', @waitResource));
         SET @dbId = SUBSTRING(@blockingKey, 1, CHARINDEX(':', @blockingKey)-1);
         IF @blockingType != 'KEY'
            AND @blockingType != 'PAGE'
             RETURN @retValue;
---Determine column list exclude column with clr types
	   SELECT
		  @columns = @columns + RTRIM(c.name) + ','
	   FROM sys.columns c
	   LEFT OUTER JOIN sys.tables t
		  ON c.object_id = t.object_id
	   LEFT OUTER JOIN SYS.schemas s
		  ON s.schema_id = t.schema_id
	   WHERE t.name = PARSENAME(@tableName, 1)
	   AND c.system_type_id != 240
	   AND s.name = PARSENAME(@tableName, 2);
	   SET @columns = SUBSTRING(@columns, 1, LEN(@columns) - 1);

         IF @paramName IS NOT NULL
             BEGIN
                 SET @retValue = 'SET '+@paramName+' = (';
         END;
	--Blocking type is KEY
         IF @blockingType = 'KEY'
             BEGIN
                 SET @lockRes = LTRIM(SUBSTRING(@blockingKey, CHARINDEX('(', @blockingKey)-1, CHARINDEX(')', @blockingKey)-CHARINDEX('(', @blockingKey)+2));
                 SET @retValue = @retValue+'SELECT ' + @columns + 
	                    ' FROM '+DB_NAME(@dbId)+'.'+@tableName+' (NOLOCK) 
					WHERE %%lockres%% = '''+@lockRes+''''+' FOR XML AUTO';
         END

	--Blocking type is PAGE;
             ELSE
         IF @blockIngType = 'PAGE'
             BEGIN
                 SET @pos1 = CHARINDEX(':', @blockingKey)+1;
                 SET @helper1 = SUBSTRING(@blockingKey, @pos1, 100);
                 SET @fileId = SUBSTRING(@helper1, 1, CHARINDEX(':', @helper1)-1);
                 SET @pageId = CAST(SUBSTRING(@helper1, CHARINDEX(':', @helper1)+1, LEN(@helper1)-CHARINDEX(':', @helper1)) AS BIGINT);
                 SET @lockRes = '('+CAST(@fileId AS NVARCHAR(10))+':'+CAST(@pageid AS NVARCHAR(MAX))+'%';
                 SET @retValue = @retValue+'SELECT ' + @columns + 
				     'FROM '+DB_NAME(@dbId)+'.'+@tableName+' (NOLOCK) 
					WHERE sys.fn_PhysLocFormatter(%%physloc%%) like  '''+@lockRes+''''+' FOR XML AUTO';
         END;
         IF @paramName IS NOT NULL
             BEGIN
                 SET @retValue = @retValue+')';
         END;
         RETURN @retvalue;
     END;
GO
