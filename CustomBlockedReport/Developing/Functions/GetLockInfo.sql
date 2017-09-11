
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[Bpr].[GetLockInfo]')
          AND type IN(N'FN', N'IF', N'TF', N'FS', N'FT')
)
    DROP FUNCTION [Bpr].[GetLockInfo];
GO
CREATE FUNCTION [Bpr].[GetLockInfo]
(@SessionId INT
)
RETURNS @lockTable TABLE
([spid]                          [INT] NOT NULL,
 [dbname]                        [NVARCHAR](128) NULL,
 [ParentObject]                  [NVARCHAR](128) NULL,
 [resource_associated_entity_id] [BIGINT] NULL,
 [resource]                      [NVARCHAR](60) NOT NULL,
 [description]                   [NVARCHAR](256) NOT NULL,
 [mode]                          [NVARCHAR](60) NOT NULL,
 [status]                        [NVARCHAR](60) NOT NULL,
 [request_owner_type]            [NVARCHAR](60) NOT NULL,
 [request_owner_id]              [BIGINT] NULL,
 [name]                          [NVARCHAR](32) NULL,
 [transaction_begin_time]        [DATETIME] NULL,
 [transaction_type]              [VARCHAR](11) NULL,
 [transaction_state]             [VARCHAR](29) NULL
)
WITH EXECUTE AS OWNER
AS
     BEGIN
         INSERT INTO @lockTable
         ([spid],
          [dbname],
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
                SELECT request_session_id AS spid,
                       DB_NAME(resource_database_id) AS dbname,
                       CASE
                           WHEN t.[resource_type] IN('DATABASE', 'FILE', 'METADATA')
                           THEN t.[resource_type]
                           WHEN t.[resource_type] = 'OBJECT'
                           THEN OBJECT_NAME(t.resource_associated_entity_id, t.resource_database_id)
                           WHEN t.[resource_type] IN('KEY', 'PAGE')
                           THEN
                (
                    SELECT OBJECT_NAME(
                                      (
                                          SELECT TOP 1 [object_id]
                                          FROM sys.partitions
                                          WHERE sys.partitions.[hobt_id] = t.[resource_associated_entity_id]
                                      ), t.resource_database_id)
                )
                           ELSE 'Unidentified'
                       END AS [ParentObject],
                       resource_associated_entity_id,
			--,CASE
			--	WHEN resource_type = 'OBJECT' THEN OBJECT_NAME(resource_associated_entity_id)
			--	WHEN resource_associated_entity_id = 0 THEN 'n/a'
			--	ELSE s.name + '.' + OBJECT_NAME(p.object_id)
			--END AS entity_name
			--,index_id
                       resource_type AS resource,
                       resource_description AS description,
                       request_mode AS mode,
                       request_status AS status,
			--,se.program_name
			--,se.host_name
                       t.request_owner_type,
                       t.request_owner_id,
                       ta.name,
                       ta.transaction_begin_time,
                       CASE ta.transaction_type
                           WHEN 1
                           THEN 'Read/write'
                           WHEN 2
                           THEN 'Read-only'
                           WHEN 3
                           THEN 'System'
                           WHEN 4
                           THEN 'Distributed'
                       END AS transaction_type,
                       CASE ta.transaction_state
                           WHEN 0
                           THEN 'Not fully initialized'
                           WHEN 1
                           THEN 'Initialized, not started'
                           WHEN 2
                           THEN 'Active'
                           WHEN 3
                           THEN 'Ended' -- only applies to read-only transactions
                           WHEN 4
                           THEN 'Commit initiated'-- distributed transactions only
                           WHEN 5
                           THEN 'Prepared, awaiting resolution'
                           WHEN 6
                           THEN 'Committed'
                           WHEN 7
                           THEN 'Rolling back'
                           WHEN 8
                           THEN 'Rolled back'
                       END AS transaction_state
		--,CASE ta.dtc_state
		-- WHEN 1  THEN  'Active'
		-- WHEN 2  THEN  'Prepared'
		-- WHEN 3  THEN  'Committed'
		-- WHEN 4  THEN  'Aborted'
		-- WHEN 5  THEN  'Recovered'
		-- END  AS dtc_state
                FROM sys.dm_tran_locks t WITH (NOLOCK)
                     LEFT JOIN sys.partitions p WITH (NOLOCK) ON p.partition_id = t.resource_associated_entity_id
                     LEFT OUTER JOIN SYS.TABLES TB WITH (NOLOCK) ON P.object_id = TB.OBJECT_ID
                     LEFT OUTER JOIN SYS.SCHEMAS S WITH (NOLOCK) ON S.schema_id = TB.SCHEMA_ID
                     LEFT OUTER JOIN SYS.DM_EXEC_SESSIONs AS SE WITH (NOLOCK) ON t.request_session_id = se.session_id
                     LEFT OUTER JOIN sys.dm_tran_active_transactions ta WITH (NOLOCK) ON t.request_owner_id = ta.transaction_id
                WHERE resource_type != 'DATABASE'
                      AND resource_type != 'METADATA'
                      AND t.request_session_id = @SessionId
                ORDER BY mode DESC;
         RETURN;
     END;
GO
ADD SIGNATURE TO OBJECT::[Bpr].[GetLockInfo] BY CERTIFICATE [PBR] WITH PASSWORD = '$tr0ngp@$$w0rd';
GO


