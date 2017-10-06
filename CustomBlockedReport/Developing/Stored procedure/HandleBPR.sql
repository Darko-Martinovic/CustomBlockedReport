
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[Bpr].[HandleBPR]')
          AND type IN(N'P', N'PC')
)
    DROP PROCEDURE [Bpr].[HandleBPR];
GO


/****** Object:  StoredProcedure [Bpr].[HandleBPR]    Script Date: 01/27/2017 09:32:25 ******/

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE PROCEDURE [Bpr].[HandleBPR]
WITH EXECUTE AS OWNER
AS
     BEGIN
         SET NOCOUNT ON;
         DECLARE @message_body XML;
         DECLARE @blocked AS XML;
         DECLARE @blocking AS XML;
         DECLARE @message_type INT;
         DECLARE @dialog UNIQUEIDENTIFIER;
         DECLARE @subject NVARCHAR(512);
         DECLARE @body NVARCHAR(MAX);
         DECLARE @blockingKey AS NVARCHAR(128);
         DECLARE @sql AS NVARCHAR(MAX);
         DECLARE @lockRes AS NVARCHAR(128);
         DECLARE @dbId BIGINT;
         DECLARE @waitResource AS NVARCHAR(128);
         DECLARE @tableName AS NVARCHAR(256);
         DECLARE @resourceContent AS NVARCHAR(MAX);
         DECLARE @blockingType AS NVARCHAR(20);
         DECLARE @blockedSpid AS INT, @blockedEcid AS INT;
         DECLARE @blockedIsolationLevel NVARCHAR(50), @blockingIsolationLevel NVARCHAR(50);
         DECLARE @blockingSpid AS INT, @blockingEcid AS INT;
         DECLARE @waitSec AS BIGINT;
         DECLARE @innerBody AS XML;
         DECLARE @addedId AS BIGINT;
         DECLARE @addedCounter AS BIGINT;
         DECLARE @counter AS INT;
	--DECLARE @newid table ( ID      int
	--,                      counter int )
         DECLARE @rowCounterBlocked BIGINT;
         DECLARE @rowCounterBlocking BIGINT;
         DECLARE @lastBachStarted AS DATETIME;
         DECLARE @sessionsKey AS NVARCHAR(50);
         DECLARE @t1 DATETIME;
         DECLARE @t2 DATETIME;
         DECLARE @messageTypeName AS NVARCHAR(256);

------------------------------------------------------------------------------
	---Get configuration
------------------------------------------------------------------------------
         DECLARE @configCustomerName NVARCHAR(35)= CAST(
                                                       (
                                                           SELECT TOP 1 value
                                                           FROM [Bpr].[Bpr_Configuration]
                                                           WHERE ID = 1
                                                       ) AS NVARCHAR(35));
         DECLARE @configNumberOfEvents INT= CAST(
                                                (
                                                    SELECT TOP 1 value
                                                    FROM [Bpr].[Bpr_Configuration]
                                                    WHERE ID = 10
                                                ) AS INT);
         DECLARE @configProfileName NVARCHAR(35)= CAST(
                                                      (
                                                          SELECT TOP 1 value
                                                          FROM [Bpr].[Bpr_Configuration]
                                                          WHERE ID = 9
                                                      ) AS NVARCHAR(35));
         DECLARE @configEmailAddress NVARCHAR(100)= CAST(
                                                        (
                                                            SELECT TOP 1 value
                                                            FROM [Bpr].[Bpr_Configuration]
                                                            WHERE ID = 8
                                                        ) AS NVARCHAR(100));
         DECLARE @configNumberOfBlockingLocks INT= CAST(
                                                       (
                                                           SELECT TOP 1 value
                                                           FROM [Bpr].[Bpr_Configuration]
                                                           WHERE ID = 6
                                                       ) AS INT);
         DECLARE @configNumberOfBlockedLocks INT= CAST(
                                                      (
                                                          SELECT TOP 1 value
                                                          FROM [Bpr].[Bpr_Configuration]
                                                          WHERE ID = 7
                                                      ) AS INT);
         DECLARE @configShowBlockingInfo BIT= CAST(
                                                  (
                                                      SELECT TOP 1 value
                                                      FROM [Bpr].[Bpr_Configuration]
                                                      WHERE ID = 2
                                                  ) AS BIT);
         DECLARE @configShowBlockedInfo BIT= CAST(
                                                 (
                                                     SELECT TOP 1 value
                                                     FROM [Bpr].[Bpr_Configuration]
                                                     WHERE ID = 3
                                                 ) AS BIT);
         DECLARE @configShowResourceContent BIT= CAST(
                                                     (
                                                         SELECT TOP 1 value
                                                         FROM [Bpr].[Bpr_Configuration]
                                                         WHERE ID = 4
                                                     ) AS BIT);
         DECLARE @configShowQueryPlan BIT= CAST(
                                               (
                                                   SELECT TOP 1 value
                                                   FROM [Bpr].[Bpr_Configuration]
                                                   WHERE ID = 5
                                               ) AS BIT);
         DECLARE @configShowMessage BIT= CAST(
                                             (
                                                 SELECT TOP 1 value
                                                 FROM [Bpr].[Bpr_Configuration]
                                                 WHERE ID = 11
                                             ) AS BIT);
         DECLARE @configDisplayName NVARCHAR(35)= CAST(
                                                      (
                                                          SELECT TOP 1 value
                                                          FROM [Bpr].[Bpr_Configuration]
                                                          WHERE ID = 12
                                                      ) AS NVARCHAR(35));
         DECLARE @configUseSQLCLR BIT= CAST(
                                           (
                                               SELECT TOP 1 value
                                               FROM [Bpr].[Bpr_Configuration]
                                               WHERE ID = 13
                                           ) AS BIT);
------------------------------------------------------------------------------
---End configuration
------------------------------------------------------------------------------

-------------------------------------------------------------------
----------------------------------Main loop 
-------------------------------------------------------------------
         WHILE(1 = 1)
             BEGIN
                 BEGIN TRANSACTION;
                 WAITFOR(
                 RECEIVE TOP (1) -- only one message
                 @message_type = message_type_id, --message type ( pass by framework )
                 @messageTypeName = message_type_name,
                 @message_body = CAST(message_body AS XML), -- pass by framework
                 @dialog = conversation_handle -- pass by framework
                 FROM dbo.BPRQueue), TIMEOUT 1000;
-- wait one second
                 IF(@@ROWCOUNT = 0)
                     BEGIN
                         ROLLBACK TRANSACTION;
                         BREAK;
                 END;
--IF @messageTypeName = 'http://schemas.microsoft.com/SQL/Notifications/EventNotification'
                 BEGIN TRY
--BEGIN
                     SET @T1 = GETDATE();
                     SET @innerBody = @message_body.query('(/EVENT_INSTANCE/TextData/blocked-process-report/.)[1]');
                     SET @blocked = @innerBody.query('(/blocked-process-report/blocked-process/process/.)[1]');
                     SET @blocking = @innerBody.query('(/blocked-process-report/blocking-process/process/.)[1]');
                     SET @waitResource =
                     (
                         SELECT xc.value('@waitresource', 'nvarchar(128)')
                         FROM @blocked.nodes('/process') AS XT(XC)
                     );
                     SET @lastBachStarted =
                     (
                         SELECT xc.value('@lastbatchstarted', 'datetime')
                         FROM @blocked.nodes('/process') AS XT(XC)
                     );
                     SET @lastBachStarted = ISNULL(@lastBachStarted, GETDATE());
                     SET @waitSec =
                     (
                         SELECT xc.value('@waittime', 'bigint')
                         FROM @blocked.nodes('/process') AS XT(XC)
                     );
                     SET @waitSec = @waitSec / 1000;
                     SET @blockedSpid =
                     (
                         SELECT xc.value('@spid', 'int')
                         FROM @blocked.nodes('/process') AS XT(XC)
                     );
                     SET @blockedEcid =
                     (
                         SELECT xc.value('@ecid', 'int')
                         FROM @blocked.nodes('/process') AS XT(XC)
                     );
                     SET @blockingSpid =
                     (
                         SELECT xc.value('@spid', 'int')
                         FROM @blocking.nodes('/process') AS XT(XC)
                     );
                     SET @blockingEcid =
                     (
                         SELECT xc.value('@ecid', 'int')
                         FROM @blocking.nodes('/process') AS XT(XC)
                     );
                     SET @blockedIsolationLevel =
                     (
                         SELECT xc.value('@isolationlevel', 'nvarchar(50)')
                         FROM @blocked.nodes('/process') AS XT(XC)
                     );
                     SET @blockingisolationLevel =
                     (
                         SELECT xc.value('@isolationlevel', 'nvarchar(50)')
                         FROM @blocking.nodes('/process') AS XT(XC)
                     );
                     SET @sessionsKey = CAST(@blockedSpid AS NVARCHAR(10))+'!'+CAST(@blockedEcid AS NVARCHAR(10))+'#'+CAST(@blockingSpid AS NVARCHAR(10))+'!'+CAST(@blockingEcid AS NVARCHAR(10));
                     SET @blockingKey = SUBSTRING(@waitResource, CHARINDEX(':', @waitResource)+1, LEN(@waitResource)-CHARINDEX(':', @waitResource));
                     SET @blockingType = RTRIM(SUBSTRING(@waitResource, 1, CHARINDEX(':', @waitResource)-1));
                     SET @dbId = SUBSTRING(@blockingKey, 1, CHARINDEX(':', @blockingKey)-1);
                     IF @configUseSQLCLR = 0
                         BEGIN
                             SET @sql = Bpr.GetResourceName(@waitResource, '@tableName');
                             EXEC sp_executesql
                                  @sql,
                                  N'@tableName nvarchar(max) output',
                                  @tableName OUTPUT;
                     END;
                         ELSE
                         BEGIN
                             IF @blockingType != 'PAGE'
                                 SET @tableName = BPR.GetResourceNameCLR(@waitResource);
                                 ELSE
                                 BEGIN
                                     SET @sql = BPR.GetResourceNameCLR(@waitResource);
                                     EXEC sp_executesql
                                          @sql,
                                          N'@tableName nvarchar(max) output',
                                          @tableName OUTPUT;
                             END;
                     END;
                     IF @configShowResourceContent = 1
                         BEGIN
                             IF @configUseSQLCLR = 0
                                AND (@blockingType = 'KEY'
                                     OR @blockingType = 'PAGE')
                                 BEGIN
                                     SET @sql = Bpr.GetResourceContent
                                     (@waitResource,
                                      CASE
                                          WHEN CHARINDEX('(', @tableName) > 0
                                          THEN SUBSTRING(@tableName, 1, CHARINDEX('(', @tableName)-1)
                                          ELSE @tableName
                                      END, '@resourceContent'
                                     );
							  --There is a problem with CLR types. FOR XML AUTO does not work with XML types. 
							  BEGIN TRY
                                     EXEC sys.sp_executesql
                                          @sql,
                                          N'@resourceContent nvarchar(max) output',
                                          @resourceContent OUTPUT;
						       END TRY
							  BEGIN CATCH
							  END CATCH

                             END;
                                 ELSE
                             IF @configUseSQLCLR = 1
                                AND (@blockingType = 'KEY'
                                     OR @blockingType = 'PAGE')
                                 BEGIN
                                     SET @resourceContent = BPR.GetResourceContentCLR
                                     (@waitResource,
                                      CASE
                                          WHEN CHARINDEX('(', @tableName) > 0
                                          THEN SUBSTRING(@tableName, 1, CHARINDEX('(', @tableName)-1)
                                          ELSE @tableName
                                      END
                                     );
                             END;
                     END;
--Check if exists
                     SET @counter =
                     (
                         SELECT TOP 1 ID
                         FROM [Bpr].[Bpr_Header]
                         WHERE [BlockingKey] = @sessionsKey
                               AND [StartTime] = @lastBachStarted
                     );
                     IF @counter IS NULL
                         BEGIN
                             INSERT INTO [Bpr].[Bpr_Header]
                             ([DataBaseName],
                              [WaitTimeInSec],
                              [BlockingKey],
                              [StartTime]
                             )
	--OUTPUT INSERTED.ID
	--,      INSERTED.Counter
	--INTO @newid

                                    SELECT DB_NAME(@dbId),
                                           @waitSec,
                                           @sessionsKey,
                                           @lastBachStarted;
                             SET @addedId =
                             (
                                 SELECT IDENT_CURRENT('[Bpr].[Bpr_Header]')
                             );
                             SET @addedCounter = 0;
                     END;
                         ELSE
                         BEGIN
                             UPDATE [Bpr].[Bpr_Header]
                               SET
                                   COUNTER = COUNTER + 1,
                                   [WaitTimeInSec] = @waitSec
--OUTPUT INSERTED.Id
--,      INSERTED.Counter
--INTO @newid
                             WHERE ID = @counter;
                             SET @addedId = @counter;
                             SET @addedCounter =
                             (
                                 SELECT TOP 1 COUNTER
                                 FROM [Bpr].[Bpr_Header]
                                 WHERE ID = @counter
                             );
                     END;
                     IF @Counter IS NULL
                         BEGIN
                             IF @configShowMessage = 1
                                 BEGIN
                                     INSERT INTO [Bpr].[Bpr_Message]
                                     ([HEADER_ID],
                                      [BPR_INNER_BODY]
                                     )
                                            SELECT @addedId,
                                                   @innerBody;
                             END;
                             INSERT INTO [Bpr].[Bpr_Details]
                             ([HEADER_ID],
                              [Level],
                              [VictemProgramName],
                              [VictemHostName],
                              [VictemSessionId],
                              [VictemSessionEcid],
                              [VictemDruationSec],
                              [VictemWaitType],
                              [VictemWaitDescription],
                              [VictemWaitResource],
                              [VictemStartTime],
                              [VictemCommand],
                              [VictemCommandText],
                              [VictemStatus],
                              [VictemIsolationLevel],
                              [BLOCKED_BY],
                              [BlockingSessionId],
                              [BlockingEcid],
                              [BlockingProgramName],
                              [BlockingHostName],
                              [BlockingLastCommandText],
                              [BlockingStatus],
                              [BlockingIsolationLevel],
                              [Resource_Name]
                             )
                                    SELECT @addedId,
                                           [Level],
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
                                           @blockedIsolationLevel [VictemIsolationLevel],
                                           [BLOCKED_BY],
                                           [BlockingSessionId],
                                           [BlockingEcid],
                                           [BlockingProgramName],
                                           [BlockingHostName],
                                           BlockingLastCommandText,
                                           [BlockingStatus],
                                           @blockingIsolationLevel [BlockingIsolationLevel],
                                           CASE
                                               WHEN LEVEL = 0
                                               THEN @tableName
                                               ELSE NULL
                                           END
                                    FROM Bpr.GetWaitInfo(@blockingSpid, @blockedSpid, @blockingEcid, @blockedEcid)
                                    ORDER BY LEVEL;
                             IF @configShowQueryPlan = 1
                                 BEGIN
                                     INSERT INTO [Bpr].[Bpr_Plans]
                                     ([HEADER_ID],
                                      [Level],
                                      [BPR_QUERY_PLAN]
                                     )
                                            SELECT @addedId,
                                                   Level,
                                                   QueryPlan
                                            FROM Bpr.GetWaitInfo(@blockingSpid, @blockedSpid, @blockingEcid, @blockedEcid)
                                            ORDER BY LEVEL;
                             END;
                             IF @configShowResourceContent = 1
                                 BEGIN
                                     IF @resourceContent IS NOT NULL
                                        AND RTRIM(@resourceContent) != ''
                                         BEGIN
                                             INSERT INTO [Bpr].[Bpr_Resources]
                                             ([HEADER_ID],
                                              [Level],
                                              [ResourceContent]
                                             )
                                                    SELECT @addedId,
                                                           0,
                                                           @resourceContent;
                                     END;
                             END;

--How many lock? 
                             IF @configShowBlockingInfo = 1
                                 BEGIN
                                     INSERT INTO [Bpr].[Bpr_LockInfoBlocking]
                                     ([HEADER_ID],
                                      [Level],
                                      [Spid],
                                      [ParentObject],
                                      [resource_associated_entity_id],
                                      [resource],
                                      [description],
                                      [mode],
                                      [status],
                                      [request_owner_type],
                                      [request_owner_id],
                                      [name],
                                      [transaction_begin_time],
                                      [transaction_type],
                                      [transaction_state]
                                     )
                                            SELECT TOP (@configNumberOfBlockingLocks + 1) @addedId,
                                                                                          0,
                                                                                          @blockingSpid,
                                                                                          [ParentObject],
                                                                                          [resource_associated_entity_id],
                                                                                          [resource],
                                                                                          [description],
                                                                                          [mode],
                                                                                          [status],
                                                                                          [request_owner_type],
                                                                                          [request_owner_id],
                                                                                          [name],
                                                                                          [transaction_begin_time],
                                                                                          [transaction_type],
                                                                                          [transaction_state]
                                            FROM Bpr.GetLockInfo(@blockingSpid);
                                     SET @rowCounterBlocking = @@ROWCOUNT;
                             END;
                             IF @configShowBlockedInfo = 1
                                 BEGIN
                                     INSERT INTO [Bpr].[Bpr_LockInfoBlocked]
                                     ([HEADER_ID],
                                      [Level],
                                      [Spid],
                                      [ParentObject],
                                      [resource_associated_entity_id],
                                      [resource],
                                      [description],
                                      [mode],
                                      [status],
                                      [request_owner_type],
                                      [request_owner_id],
                                      [name],
                                      [transaction_begin_time],
                                      [transaction_type],
                                      [transaction_state]
                                     )
                                            SELECT TOP (@configNumberOfBlockedLocks + 1) @addedId,
                                                                                         0,
                                                                                         @blockedSpid,
                                                                                         [ParentObject],
                                                                                         [resource_associated_entity_id],
                                                                                         [resource],
                                                                                         [description],
                                                                                         [mode],
                                                                                         [status],
                                                                                         [request_owner_type],
                                                                                         [request_owner_id],
                                                                                         [name],
                                                                                         [transaction_begin_time],
                                                                                         [transaction_type],
                                                                                         [transaction_state]
                                            FROM Bpr.GetLockInfo(@blockedSpid);
                                     SET @rowCounterBlocked = @@ROWCOUNT;
                             END;

				-----------------------------------------------------------
				--Build report
				-----------------------------------------------------------
                             IF @sessionsKey IS NOT NULL
                                 BEGIN
--Main information
                                     SET @body = EMAIL.QueryToHtml('
					SELECT      [Level]
					   ,DB_NAME('+CAST(@dbId AS NVARCHAR(10))+') [DataBase Name]
					   ,[VictemProgramName] + '' on host '' +  [VictemHostName] [Blodked Info]
					   ,Cast([VictemSessionId] as NVarChar(10)) + ''('' + Cast([VictemSessionEcid] as Nvarchar(10)) + '')'' [Blocked Spid_Ecid]
					   ,[VictemWaitType] [Blocked Wait Type]
					   ,[VictemWaitDescription] [Blocked Wait Description]
					   ,[VictemWaitResource] [Blocked Wait Resource]
					   ,[VictemStartTime] [Blocked Start Time]
					 ,[VictemStatus] + '' IsolationLevel '' + Cast([VictemIsolationLevel] as nvarchar(60)) [Blocked Status]
					   ,[VictemCommand] [Blocked command]
					   ,[VictemCommandText] [Blocked Command Text]
					   ,[BLOCKED_BY]
					   ,Cast([BlockingSessionId] as nvarchar(10)) + ''('' + Cast([BlockingEcid] as nvarchar(10)) + '')'' [Blocking Spid_Ecid]
					 ,[BlockingStatus] + '' IsolationLevel '' + Cast([BlockingIsolationLevel] as nvarchar(60)) [Blocking Status]
					   ,[BlockingProgramName] + '' on host '' + [BlockingHostName] [Blocking Info]
					 ,BlockingLastCommandText [Blocking Last CommandText]
                  FROM [Bpr].[Bpr_Details] 
				  WHERE HEADER_ID = '+CAST(@addedId AS NVARCHAR(10))+' ORDER BY Level', '', @tableName+'-Waiting '+CAST(@waitSec AS NVARCHAR(10))+' (sec)', '', 1, 0, 'ST_SIMPLE');

				--Lock info-blocked
                                     IF @configShowBlockedInfo = 1
                                         BEGIN
                                             SET @body = (EMAIL.ConCatHtml
                                                         (@body, (EMAIL.QueryToHtml
                                                                 ('
					 SELECT '+CASE
                                       WHEN @rowCounterBlocked > @configNumberOfBlockedLocks
                                       THEN ' TOP '+CAST(@configNumberOfBlockedLocks AS NVARCHAR(3))
                                       ELSE ' '
                                   END+'[Spid] 
						,[ParentObject]
						,[resource_associated_entity_id]
						,[resource]
						,[description]
						,[mode]
						,[status]
						,[request_owner_type]
						,[request_owner_id]
						,[name]
						,[transaction_begin_time]
						,[transaction_type]
						,[transaction_state] 
					FROM [Bpr].[Bpr_LockInfoBlocked] WHERE HEADER_ID='+CAST(@addedId AS NVARCHAR(10))+'', '', 'Lock info-blocked',
                                                                                                                   CASE
                                                                                                                       WHEN @rowCounterBlocked > @configNumberOfBlockedLocks
                                                                                                                       THEN ' Attention! Total number of locks is greater then @configNumberOfBlockedLocks !'
                                                                                                                       ELSE '#'
                                                                                                                   END, 0, 0, 'ST_SIMPLE'
                                                                 ))
                                                         ));
                                     END;


				 --Lock info-blocking
                                     IF @configShowBlockingInfo = 1
                                         BEGIN
                                             SET @body = (EMAIL.ConCatHtml
                                                         (@body, (EMAIL.QueryToHtml
                                                                 ('
					 SELECT '+CASE
                                       WHEN @rowCounterBlocking > @configNumberOfBlockingLocks
                                       THEN ' TOP  '+CAST(@configNumberOfBlockingLocks AS NVARCHAR(3))
                                       ELSE ' '
                                   END+'[Spid] 
						,[ParentObject]
						,[resource_associated_entity_id]
						,[resource]
						,[description]
						,[mode]
						,[status]
						,[request_owner_type]
						,[request_owner_id]
						,[name]
						,[transaction_begin_time]
						,[transaction_type]
						,[transaction_state] 
					FROM [Bpr].[Bpr_LockInfoBlocking] WHERE HEADER_ID='+CAST(@addedId AS NVARCHAR(10))+'', '', 'Lock info-blocking',
                                                                                                                    CASE
                                                                                                                        WHEN @rowCounterBlocking > @configNumberOfBlockingLocks
                                                                                                                        THEN ' Attention! Total number of locks is greater then @configNumberOfBlockingLocks !'
                                                                                                                        ELSE '#'
                                                                                                                    END, 0, 0, 'ST_SIMPLE'
                                                                 ))
                                                         ));
                                     END;
                                     IF @configShowResourceContent = 1
                                         BEGIN
				 --Lock resource content
                                             IF @blockingType = 'KEY'
                                                OR @blockingType = 'PAGE'
                                                 BEGIN
                                                     SET @body = (EMAIL.ConCatHtml(@body, (EMAIL.QueryToHtml('
						SELECT
							ResourceContent
						FROM bpr.Bpr_Resources 
						WHERE HEADER_ID = '+CAST(@addedId AS NVARCHAR(10))+' AND Level = 0', '', 'Resource content', '', 0, 0, 'ST_SIMPLE'))));
                                             END;
                                     END;
                                     IF @configShowMessage = 1
                                         BEGIN
                                             SET @body = (EMAIL.ConCatHtml(@body, (EMAIL.QueryToHtml('
														SELECT
															BPR_INNER_BODY
														FROM BPR.Bpr_Message 
														WHERE HEADER_ID = '+CAST(@addedId AS NVARCHAR(10)), '', 'Blocked process report', '', 0, 0, 'ST_SIMPLE'))));
                                     END;
                                     IF @configShowQueryPlan = 1
                                         BEGIN
                                             SET @body = (EMAIL.ConCatHtml(@body, (EMAIL.QueryToHtml('
								SELECT
									BPR_QUERY_PLAN
								FROM BPR.Bpr_Plans 
								WHERE HEADER_ID = '+CAST(@addedId AS NVARCHAR(10)), '', 'Query plan', '', 0, 0, 'ST_SIMPLE'))));
                                     END;
                                     SET @T2 = GETDATE();
                                     SET @subject = @@SERVERNAME+'- BlockProcess Notification. Customer name '+@configCustomerName+'. More info querying for id : '+CAST(@addedId AS NVARCHAR(10))+'. Events occures : '+CAST((@addedCounter + 1) AS NVARCHAR(10))+'; Processed in : '+CAST(DATEDIFF(MILLISECOND, @t1, @t2) AS NVARCHAR(10))+' miliseconds';
                                     EXEC [EMAIL].[CLRSendMail]
                                          @profileName = @configProfileName,
                                          @mailTo = @configEmailAddress,
                                          @mailSubject = @subject,
                                          @mailBody = @body,
                                          @displayName = @configDisplayName;
                             END;
                     END;
                         ELSE
                         BEGIN
                             IF @addedCounter >= @configNumberOfEvents
                                AND @addedCounter % @configNumberOfEvents = 0
                                 BEGIN
                                     SET @T2 = GETDATE();
                                     SET @subject = @@SERVERNAME+'- BlockProcess Notification. Customer name '+@configCustomerName+'. More info querying for id : '+CAST(@addedId AS NVARCHAR(10))+'. Events occures : '+CAST(@addedCounter AS NVARCHAR(10))+'; Processed in : '+CAST(DATEDIFF(MILLISECOND, @t1, @t2) AS NVARCHAR(10))+' miliseconds';
                                     SET @body = '<b>'+@tableName+'</b><br><b>Waiting '+CAST(@waitSec AS NVARCHAR(10))+' (sec)</b>'+CHAR(10)+'<br><b> Blocking spid : </b>'+CAST(ISNULL(@blockingSpid, 0) AS NVARCHAR(10))+CHAR(10)+'<br><b> Blocked spid : </b>'+CAST(ISNULL(@blockedSpid, 0) AS NVARCHAR(10));
                                     EXEC [EMAIL].[CLRSendMail]
                                          @profileName = @configProfileName,
                                          @mailTo = @configEmailAddress,
                                          @mailSubject = @subject,
                                          @mailBody = @body,
                                          @displayName = @configDisplayName;
                             END;
                     END;
                 END TRY
                 BEGIN CATCH
                     BEGIN
                         DECLARE @errorMess AS NVARCHAR(MAX)=
                         (
                             SELECT ERROR_MESSAGE()
                         );
                         INSERT INTO [Bpr].[Bpr_BadMessage]
                         ([BPR_INNER_BODY],
                          [ERROR_MESSAGE]
                         )
                                SELECT @innerBody,
                                       @errorMess;
                         SET @subject = @@SERVERNAME+'- Error in BlockProcess Notification. Customer name '+@configCustomerName;
                         SET @body = 'Error message : '+CHAR(13)+CHAR(10)+'<b>'+@errorMess+'</b>';
                         EXEC [EMAIL].[CLRSendMail]
                              @profileName = @configProfileName,
                              @mailTo = @configEmailAddress,
                              @mailSubject = @subject,
                              @mailBody = @body,
                              @displayName = @configDisplayName;
                     END;
                 END CATCH;
                 COMMIT TRANSACTION;
             END;
     END;
GO
ADD SIGNATURE TO OBJECT::[Bpr].[HandleBPR] BY CERTIFICATE [PBR] WITH PASSWORD = '$tr0ngp@$$w0rd';
GO

--Add custom action on queue 
--In order to automatically process the queue, we are using activation.
--Activation requires an activation stored procedure that is executed when new messages are added to the queue. 
--The activation procedure is a standard stored procedure that works off the queue instead 
--of tables in the database. 
ALTER QUEUE BPRQueue WITH ACTIVATION(STATUS = ON, PROCEDURE_NAME = [BPR].[HandleBPR], MAX_QUEUE_READERS = 1, EXECUTE AS OWNER);