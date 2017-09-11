
/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/

--------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------Transfer to email schema
--------------------------------------------------------------------------------------------------------------------------------------------------------
IF EXISTS
(
    SELECT *
    FROM sysobjects
    WHERE id = OBJECT_ID(N'[BPR].[GetResourceNameFromPageClr]')
          AND OBJECTPROPERTY(id, N'IsProcedure') = 1
)
    BEGIN
        DROP PROCEDURE [BPR].[GetResourceNameFromPageClr];
END;
ALTER SCHEMA BPR TRANSFER dbo.GetResourceNameFromPageClr;

--Transfer function
IF EXISTS
(
    SELECT *
    FROM sysobjects
    WHERE id = OBJECT_ID(N'[BPR].[GetResourceContentClr]')
)
    BEGIN
        DROP FUNCTION [BPR].[GetResourceContentClr];
END;
ALTER SCHEMA BPR TRANSFER dbo.GetResourceContentClr;



--Transfer function
IF EXISTS
(
    SELECT *
    FROM sysobjects
    WHERE id = OBJECT_ID(N'[BPR].[GetResourceNameClr]')
)
    BEGIN
        DROP FUNCTION [BPR].[GetResourceNameClr];
END;
ALTER SCHEMA BPR TRANSFER dbo.GetResourceNameClr;

