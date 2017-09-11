
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[Bpr].[ShowBlocking]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [Bpr].[ShowBlocking];
GO


/****** Object:  StoredProcedure [Bpr].[ShowBlocking]    Script Date: 01/27/2017 09:32:25 ******/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [Bpr].[ShowBlocking]
WITH EXECUTE AS OWNER
AS
     BEGIN
         SET NOCOUNT ON;
         DECLARE @x TABLE
         (blockedId    INT,
          blockingID   INT,
          blockingEcid INT,
          blockedEcid  INT,
          Level        INT
         );
         DECLARE @waitInfo TABLE
         ([BlockNo]                      INT,
          [LEVEL]                        INT,
          [DataBaseName]                 [NVARCHAR](128),
          [VictemProgramName]            [NVARCHAR](128),
          [VictemHostName]               [NVARCHAR](128),
          [VictemSessionId]              [SMALLINT],
          [VictemSessionEcid]            [INT],
          [VictemDruationSec]            [BIGINT],
          [VictemWaitType]               [NVARCHAR](60),
          [VictemDescription]            [NVARCHAR](3072),
          [VictemWaitResource]           [NVARCHAR](256),
          [VictemStartTime]              [DATETIME],
          [Command]                      [NVARCHAR](32),
          [CommandText]                  [NVARCHAR](MAX),
          [VictemStatus]                 [NVARCHAR](30),
          [VictemIsolationLevel]         [SMALLINT],
          [BLOCKED_BY]                   [VARCHAR](13),
          [BlockingSessionId]            [SMALLINT],
          [BlockingEcid]                 [INT],
          [BlockingProgramName]          [NVARCHAR](128),
          [BlockingHostName]             [NVARCHAR](128),
          [BlockingLastRequestStartTime] [DATETIME],
          [BlockingLastCommandText]      [NVARCHAR](MAX),
          [BlockingStatus]               [NVARCHAR](30),
          [BlockingIsolationLevel]       [SMALLINT]
         );
         INSERT INTO @x
                SELECT session_id,
                       blocking_session_id,
                       ISNULL(exec_context_id, 0) AS exec_context_id,
                       ISNULL(blocking_exec_context_id, 0) AS blocking_exec_context_id,
                       ROW_NUMBER() OVER(ORDER BY session_id,
                                                  blocking_session_id) AS level
                FROM sys.dm_os_waiting_tasks
                WHERE blocking_session_id IS NOT NULL;
         DECLARE @blockingID INT;
         DECLARE @blockedID INT;
         DECLARE @blockingECID INT;
         DECLARE @blockedECID INT;
         DECLARE @level INT;
         WHILE
         (
             SELECT COUNT(*)
             FROM @X
         ) > 0
             BEGIN
                 SET @level =
                 (
                     SELECT TOP 1 LEVEL
                     FROM @X
                 );
                 SET @blockingID =
                 (
                     SELECT TOP 1 blockingID
                     FROM @X
                 );
                 SET @blockedID =
                 (
                     SELECT TOP 1 blockedID
                     FROM @X
                 );
                 SET @blockingECID =
                 (
                     SELECT TOP 1 blockingECID
                     FROM @X
                 );
                 SET @blockedECID =
                 (
                     SELECT TOP 1 blockedECID
                     FROM @X
                 );
--Add header who is blocked by whom 
                 INSERT INTO @waitInfo
                 ([BlockNo],
                  [VictemProgramName]
                 )
                        SELECT @LEVEL,
                               CAST(@blockedID AS NVARCHAR(4))+'('+CAST(@blockedECID AS NVARCHAR(4))+')=>'+CAST(@blockingID AS NVARCHAR(4))+'('+CAST(@blockingECID AS NVARCHAR(4))+')';
--Add detail information 
                 INSERT INTO @waitInfo
                 ([BlockNo],
                  level,
                  [DataBaseName],
                  [VictemProgramName],
                  [VictemHostName],
                  [VictemSessionId],
                  [VictemSessionEcid],
                  [VictemDruationSec],
                  [VictemWaitType],
                  [VictemDescription],
                  [VictemWaitResource],
                  [VictemStartTime],
                  [Command],
                  [CommandText],
                  [VictemStatus],
                  [VictemIsolationLevel],
                  [BLOCKED_BY],
                  [BlockingSessionId],
                  [BlockingEcid],
                  [BlockingProgramName],
                  [BlockingHostName],
                  [BlockingLastRequestStartTime],
                  [BlockingLastCommandText],
                  [BlockingStatus],
                  [BlockingIsolationLevel]
                 )
                        SELECT @level,
                               level,
                               [DataBaseName],
                               [VictemProgramName],
                               [VictemHostName],
                               [VictemSessionId],
                               [VictemSessionEcid],
                               [VictemDruationSec],
                               [VictemWaitType],
                               [VictemDescription],
                               [VictemWaitResource],
                               [VictemStartTime],
                               [Command],
                               [CommandText],
                               [VictemStatus],
                               [VictemIsolationLevel],
                               [BLOCKED_BY],
                               [BlockingSessionId],
                               [BlockingEcid],
                               [BlockingProgramName],
                               [BlockingHostName],
                               [BlockingLastRequestStartTime],
                               [BlockingLastCommandText],
                               [BlockingStatus],
                               [BlockingIsolationLevel]
                        FROM BPR.GetWaitInfo(@blockingID, @blockedID, @blockingECID, @blockedECID);
                 DELETE FROM @x
                 WHERE LEVEL = @LEVEL;
             END;
         SELECT *
         FROM @waitInfo
         ORDER BY [BlockNo],
                  LEVEL;
     END;
         ADD SIGNATURE TO OBJECT::BPR.ShowBlocking BY CERTIFICATE [PBR] WITH PASSWORD = '$tr0ngp@$$w0rd';
GO
