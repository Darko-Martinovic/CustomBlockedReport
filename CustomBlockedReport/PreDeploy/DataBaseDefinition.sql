---! ENABLE BROKER 
---!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


--Create queue
--which is a storage area for the data that gets received from the event notification servise. 
--And queues are implemented as internal tables inside of SQL Server and have a specific way that you would access 
--them to be able to process the messages for each of the services.
--We can view user defined queues by quering system view, as shoed bellow. 
--SELECT
--	*
--FROM sys.service_queues
--WHERE is_ms_shipped = 0;
IF NOT EXISTS
(
    SELECT *
    FROM sys.service_queues
    WHERE name = 'BPRQueue'
)
    BEGIN
        CREATE QUEUE BPRQueue;
END;

--Create servis--
--which are used to receive messages from the event notification servise
--by using contract [http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]
--We can view contract by quering system view
--SELECT *
--FROM sys.service_contracts
IF NOT EXISTS
(
    SELECT *
    FROM sys.services
    WHERE name = 'BPRService'
)
    BEGIN
        CREATE SERVICE BPRService ON QUEUE BPRQueue([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]);
END;

--Create route 
--When a route specifies 'LOCAL' for the next_hop_address, the message is delivered to a service within the current instance of SQL Server
IF NOT EXISTS
(
    SELECT *
    FROM sys.routes
    WHERE name = 'BPRRoute'
)
    BEGIN
--Create route
        CREATE ROUTE BPRRoute
        WITH SERVICE_NAME = 'BPRService',
             ADDRESS = 'LOCAL';
END;
 
 
--Create event notification
IF NOT EXISTS
(
    SELECT *
    FROM sys.server_event_notifications
    WHERE name = 'BPRNotification'
)
    BEGIN
        CREATE EVENT NOTIFICATION BPRNotification ON SERVER WITH FAN_IN FOR BLOCKED_PROCESS_REPORT TO SERVICE 'BPRService', 'current database';
END; 


--
--------!!!Create schema if not exists
--
IF NOT EXISTS
(
    SELECT schema_name
    FROM information_schema.schemata
    WHERE schema_name = 'BPR'
)
    BEGIN
        EXEC sp_executesql
             N'CREATE SCHEMA BPR';
END;



---Create tables

-- Create header
IF NOT EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_Header]')
          AND type IN(N'U')
)
    BEGIN
        CREATE TABLE [Bpr].[Bpr_Header]
        ([ID]            [BIGINT] IDENTITY(1, 1) NOT NULL,
         [DataBaseName]  [NVARCHAR](128) NOT NULL
                                         DEFAULT DB_NAME(),
         [Counter]       [BIGINT] NOT NULL
                                  DEFAULT 0,
         [WaitTimeInSec] [DECIMAL](10, 2) NOT NULL
                                          DEFAULT 0,
         [BlockingKey]   [NVARCHAR](50) NULL,
         [StartTime]     [DATETIME] NOT NULL
                                    DEFAULT GETDATE(),
         CONSTRAINT [PK_Bpr_Header] PRIMARY KEY CLUSTERED([ID] ASC)
         WITH(PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
        )
        ON [PRIMARY];
END;
GO

--Create messages
IF NOT EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_Message]')
          AND type IN(N'U')
)
    BEGIN
        CREATE TABLE [Bpr].[Bpr_Message]
        ([ID]             [BIGINT] IDENTITY(1, 1) NOT NULL,
         [HEADER_ID]      [BIGINT] NOT NULL,
         [BPR_INNER_BODY] [XML] NULL,
         CONSTRAINT [PK_Bpr_Message] PRIMARY KEY CLUSTERED([ID] ASC)
         WITH(PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
        )
        ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
END;
GO

--Create bad messages
IF NOT EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_BadMessage]')
          AND type IN(N'U')
)
    BEGIN
        CREATE TABLE [Bpr].[Bpr_BadMessage]
        ([ID]             [BIGINT] IDENTITY(1, 1) NOT NULL,
         [BPR_INNER_BODY] [XML] NULL,
         [DATETIME]       SMALLDATETIME NOT NULL
                                        DEFAULT GETDATE(),
         [ERROR_MESSAGE]  NVARCHAR(MAX),
         CONSTRAINT [PK_Bpr_BprMessage] PRIMARY KEY CLUSTERED([ID] ASC)
         WITH(PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
        )
        ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
END;
GO


--Create plans
IF NOT EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_Plans]')
          AND type IN(N'U')
)
    BEGIN
        CREATE TABLE [Bpr].[Bpr_Plans]
        ([ID]             [BIGINT] IDENTITY(1, 1) NOT NULL,
         [HEADER_ID]      [BIGINT] NOT NULL,
         [Level]          [INT] NOT NULL,
         [BPR_QUERY_PLAN] [XML] NULL,
         CONSTRAINT [PK_Bpr_PLANS] PRIMARY KEY CLUSTERED([ID] ASC)
         WITH(PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
        )
        ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
END;
GO

--Create resources
IF NOT EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_Resources]')
          AND type IN(N'U')
)
    BEGIN
        CREATE TABLE [Bpr].[Bpr_Resources]
        ([ID]              [BIGINT] IDENTITY(1, 1) NOT NULL,
         [HEADER_ID]       [BIGINT] NOT NULL,
         [Level]           [INT] NOT NULL,
         [ResourceContent] [XML] NULL,
         CONSTRAINT [PK_Bpr_Resources] PRIMARY KEY CLUSTERED([ID] ASC)
         WITH(PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
        )
        ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
END;
GO



--Create details
IF NOT EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_Details]')
          AND type IN(N'U')
)
 BEGIN
        CREATE TABLE [Bpr].[Bpr_Details]
        ([ID]                      [BIGINT] IDENTITY(1, 1) NOT NULL,
         [HEADER_ID]               [BIGINT] NOT NULL,
         [Level]                   [INT] NOT NULL,
         [VictemProgramName]       [NVARCHAR](128) NULL,
         [VictemHostName]          [NVARCHAR](128) NULL,
         [VictemSessionId]         [SMALLINT] NULL,
         [VictemSessionEcid]       [INT] NULL,
         [VictemDruationSec]       [BIGINT] NULL,
         [VictemWaitType]          [NVARCHAR](60) NULL,
         [VictemWaitDescription]   [NVARCHAR](3072) NULL,
         [VictemWaitResource]      [NVARCHAR](256) NOT NULL,
         [VictemStartTime]         [DATETIME] NOT NULL,
         [VictemCommand]           [NVARCHAR](32) NOT NULL,
         [VictemCommandText]       [NVARCHAR](MAX) NULL,
         [VictemStatus]            [NVARCHAR](50) NULL,
         [VictemIsolationLevel]    [NVARCHAR](50) NULL,
         [BLOCKED_BY]              [VARCHAR](13) NOT NULL,
         [BlockingSessionId]       [SMALLINT] NULL,
         [BlockingEcid]            [INT] NULL,
         [BlockingProgramName]     [NVARCHAR](128) NULL,
         [BlockingHostName]        [NVARCHAR](128) NULL,
         [BlockingLastCommandText] [NVARCHAR](MAX) NULL,
         [BlockingStatus]          [NVARCHAR](50) NULL,
         [BlockingIsolationLevel]  [NVARCHAR](50) NULL,
         [Resource_Name]           [NVARCHAR](256) NULL,
         CONSTRAINT [PK_Bpr_Details] PRIMARY KEY CLUSTERED([ID] ASC)
         WITH(PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
        )
        ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];
END;
GO

--Create lock info blocking
IF NOT EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_LockInfoBlocking]')
          AND type IN(N'U')
)
    BEGIN
        CREATE TABLE [Bpr].[Bpr_LockInfoBlocking]
        ([ID]                            [BIGINT] IDENTITY(1, 1) NOT NULL,
         [HEADER_ID]                     [BIGINT] NOT NULL,
         [Level]                         [INT] NOT NULL,
         [Spid]                          [INT] NOT NULL,
         [ParentObject]                  [VARCHAR](128) NULL,
         [resource_associated_entity_id] [BIGINT] NULL,
         [resource]                      [NVARCHAR](60) NOT NULL,
         [description]                   [NVARCHAR](256) NOT NULL,
         [mode]                          [NVARCHAR](60) NOT NULL,
         [status]                        [NVARCHAR](60) NOT NULL,
         [request_owner_type]            [NVARCHAR](60) NOT NULL,
         [request_owner_id]              [BIGINT] NULL,
         [name]                          [NVARCHAR](32) NULL,
         [transaction_begin_time]        [DATETIME] NULL,
         [transaction_type]              [VARCHAR](60) NULL,
         [transaction_state]             [VARCHAR](60) NULL,
         CONSTRAINT [PK_Bpr_LockInfoBlocking] PRIMARY KEY CLUSTERED([ID] ASC)
         WITH(PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
        )
        ON [PRIMARY];
END;
GO


--Create lock info blocking
IF NOT EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_LockInfoBlocked]')
          AND type IN(N'U')
)
    BEGIN
        CREATE TABLE [Bpr].[Bpr_LockInfoBlocked]
        ([ID]                            [BIGINT] IDENTITY(1, 1) NOT NULL,
         [HEADER_ID]                     [BIGINT] NOT NULL,
         [Level]                         [INT] NOT NULL,
         [Spid]                          [INT] NOT NULL,
         [ParentObject]                  [VARCHAR](128) NULL,
         [resource_associated_entity_id] [BIGINT] NULL,
         [resource]                      [NVARCHAR](60) NOT NULL,
         [description]                   [NVARCHAR](256) NOT NULL,
         [mode]                          [NVARCHAR](60) NOT NULL,
         [status]                        [NVARCHAR](60) NOT NULL,
         [request_owner_type]            [NVARCHAR](60) NOT NULL,
         [request_owner_id]              [BIGINT] NULL,
         [name]                          [NVARCHAR](32) NULL,
         [transaction_begin_time]        [DATETIME] NULL,
         [transaction_type]              [VARCHAR](60) NULL,
         [transaction_state]             [VARCHAR](60) NULL,
         CONSTRAINT [PK_Bpr_LockInfoBlocked] PRIMARY KEY CLUSTERED([ID] ASC)
         WITH(PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
        )
        ON [PRIMARY];
END;
GO


--Create table configuration
IF NOT EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_Configuration]')
          AND type IN(N'U')
)
    BEGIN
        CREATE TABLE [Bpr].[Bpr_Configuration]
        ([ID]          [BIGINT] NOT NULL,
         [Name]        NVARCHAR(35) NOT NULL,
         [Value]       SQL_VARIANT NOT NULL,
         [Description] [NVARCHAR](255) NOT NULL,
         CONSTRAINT [PK_Bpr_Configuration] PRIMARY KEY CLUSTERED([ID] ASC)
         WITH(PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
        )
        ON [PRIMARY];
END;
GO
--There is no records in the table
IF
(
    SELECT COUNT(*)
    FROM [Bpr].[Bpr_Configuration]
) = 0
    BEGIN
        INSERT INTO Bpr.Bpr_Configuration
        (ID,
         Name,
         Value,
         Description
        )
               SELECT 1,
                      'Customer name',
                      CAST('Simple Talk' AS SQL_VARIANT),
                      'Specify customer name'
               UNION ALL
               SELECT 2,
                      'Show blocking info',
                      1,
                      'Report contains information about locks holds by blocking session'
               UNION ALL
               SELECT 3,
                      'Show blocked info',
                      1,
                      'Report contains information about locks holds by blocked session'
               UNION ALL
               SELECT 4,
                      'Show resource content',
                      1,
                      'Report contains information about the resource content'
               UNION ALL
               SELECT 5,
                      'Show query plan',
                      0,
                      'Report contains information about the query plan'
               UNION ALL
               SELECT 6,
                      'Number of maximum lock blocking',
                      30,
                      'How many rows are showed in table that display information about lock in blocking session'
               UNION ALL
               SELECT 7,
                      'Number of maximum lock blocked',
                      30,
                      'How many rows are showed in table that display information about lock in blocked session'
               UNION ALL
               SELECT 8,
                      'Dedicated e-mail address',
                      '<your e-mail address>',
                      'Dedicated e-mail address'
               UNION ALL
               SELECT 9,
                      'Profile name',
                      'SimpleTalk',
                      'Default profile name for sending e-mail'
               UNION ALL
               SELECT 10,
                      'Number of events',
                      20,
                      'After sending first e-mail, how many events should be rised to send additional e-mails'
               UNION ALL
               SELECT 11,
                      'Show messages',
                      0,
                      'Show blocked process report xml message'
               UNION ALL
               SELECT 12,
                      'Display name',
                      'BPR',
                      'Display name'
               UNION ALL
               SELECT 13,
                      'Use SQLCLR',
                      '0',
                      'Using SQLCLR to get resource name and content';
END;



--Indexes
IF NOT EXISTS
(
    SELECT *
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_Header]')
          AND name = N'IX_Bpr_BlockedProcessReporter_Header'
)
    BEGIN
        CREATE UNIQUE NONCLUSTERED INDEX [IX_Bpr_BlockedProcessReporter_Header] ON [Bpr].[Bpr_Header]([BlockingKey] ASC, [StartTime] ASC) INCLUDE([Counter], [WaitTimeInSec]) WITH(PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY];
END;
GO


--Indexes on Bpr_Messages
IF NOT EXISTS
(
    SELECT *
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_Message]')
          AND name = N'IX_Brp_Message'
)
    BEGIN
        CREATE UNIQUE NONCLUSTERED INDEX [IX_Brp_Message] ON [Bpr].[Bpr_Message]([HEADER_ID] ASC) WITH(PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY];
END;
GO
--End indexes on Bpr_Messages


--Indexes on Bpr_LockInfoBlocking
IF NOT EXISTS
(
    SELECT *
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_LockInfoBlocking]')
          AND name = N'IX_Brp_LockInfoBlocking'
)
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Brp_LockInfoBlocking] ON [Bpr].[Bpr_LockInfoBlocking]([HEADER_ID] ASC) INCLUDE([Level], [Spid], [ParentObject], [resource_associated_entity_id], [resource], [description], [mode], [status], [request_owner_type], [request_owner_id], [name], [transaction_begin_time], [transaction_type], [transaction_state]) WITH(PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY];
END;
GO
--End indexes on Bpr_LockInfoBlocking



--Indexes on Bpr_LockInfoBlocked
IF NOT EXISTS
(
    SELECT *
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_LockInfoBlocked]')
          AND name = N'IX_Brp_LockInfoBlocked'
)
    BEGIN
--Create cover index
        CREATE NONCLUSTERED INDEX [IX_Brp_LockInfoBlocked] ON [Bpr].[Bpr_LockInfoBlocked]
        ([HEADER_ID] ASC
        ) INCLUDE([Level], [Spid], [ParentObject], [resource_associated_entity_id], [resource], [description], [mode], [status], [request_owner_type], [request_owner_id], [name], [transaction_begin_time], [transaction_type], [transaction_state]) WITH(PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY];
END;
GO
--End indexes on Bpr_LockInfoBlocked





--Index on query plans
IF NOT EXISTS
(
    SELECT *
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_Plans]')
          AND name = N'IX_Brp_Plans'
)
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Brp_Plans] ON [Bpr].[Bpr_Plans]([HEADER_ID] ASC, Level ASC) WITH(PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY];
END;
GO


--Index on resources
IF NOT EXISTS
(
    SELECT *
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_Resources]')
          AND name = N'IX_Brp_Resources'
)
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Brp_Resources] ON [Bpr].[Bpr_Resources]([HEADER_ID] ASC, Level ASC) WITH(PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY];
END;
GO


--Index on details
IF NOT EXISTS
(
    SELECT *
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_Details]')
          AND name = N'IX_Bpr_Details'
)
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_Bpr_Details] ON [Bpr].[Bpr_Details]([HEADER_ID] ASC) WITH(PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY];
END;
GO



--Create relations
--- Header to message
IF NOT EXISTS
(
    SELECT *
    FROM sys.foreign_keys
    WHERE object_id = OBJECT_ID(N'[Bpr].[FK_Bpr_Message_Bpr_Header]')
          AND parent_object_id = OBJECT_ID(N'[Bpr].[Bpr_Message]')
)
    BEGIN
        ALTER TABLE [Bpr].[Bpr_Message]
        WITH CHECK
        ADD CONSTRAINT [FK_Bpr_Message_Bpr_Header] FOREIGN KEY([HEADER_ID]) REFERENCES [Bpr].[Bpr_Header]([ID]);
END;
GO
IF EXISTS
(
    SELECT *
    FROM sys.foreign_keys
    WHERE object_id = OBJECT_ID(N'[Bpr].[FK_Bpr_Message_Bpr_Header]')
          AND parent_object_id = OBJECT_ID(N'[Bpr].[Bpr_Message]')
)
    ALTER TABLE [Bpr].[Bpr_Message] CHECK CONSTRAINT [FK_Bpr_Message_Bpr_Header];
GO
--- End Header to message



--- Header to blocking
IF NOT EXISTS
(
    SELECT *
    FROM sys.foreign_keys
    WHERE object_id = OBJECT_ID(N'[Bpr].[FK_Bpr_Blocking_Bpr_Header]')
          AND parent_object_id = OBJECT_ID(N'[Bpr].[Bpr_LockInfoBlocking]')
)
    BEGIN
        ALTER TABLE [Bpr].[Bpr_LockInfoBlocking]
        WITH CHECK
        ADD CONSTRAINT [FK_Bpr_Blocking_Bpr_Header] FOREIGN KEY([HEADER_ID]) REFERENCES [Bpr].[Bpr_Header]([ID]);
END;
IF EXISTS
(
    SELECT *
    FROM sys.foreign_keys
    WHERE object_id = OBJECT_ID(N'[Bpr].[FK_Bpr_Blocking_Bpr_Header]')
          AND parent_object_id = OBJECT_ID(N'[Bpr].[Bpr_LockInfoBlocking]')
)
    ALTER TABLE [Bpr].[Bpr_LockInfoBlocking] CHECK CONSTRAINT [FK_Bpr_Blocking_Bpr_Header];
GO
--- End Header to blocking



--- Header to blocked
IF NOT EXISTS
(
    SELECT *
    FROM sys.foreign_keys
    WHERE object_id = OBJECT_ID(N'[Bpr].[FK_Bpr_Blocked_Bpr_Header]')
          AND parent_object_id = OBJECT_ID(N'[Bpr].[Bpr_LockInfoBlocked]')
)
    BEGIN
        ALTER TABLE [Bpr].[Bpr_LockInfoBlocked]
        WITH CHECK
        ADD CONSTRAINT [FK_Bpr_Blocked_Bpr_Header] FOREIGN KEY([HEADER_ID]) REFERENCES [Bpr].[Bpr_Header]([ID]);
END;
GO
IF EXISTS
(
    SELECT *
    FROM sys.foreign_keys
    WHERE object_id = OBJECT_ID(N'[Bpr].[FK_Bpr_Blocked_Bpr_Header]')
          AND parent_object_id = OBJECT_ID(N'[Bpr].[Bpr_LockInfoBlocked]')
)
    ALTER TABLE [Bpr].[Bpr_LockInfoBlocked] CHECK CONSTRAINT [FK_Bpr_Blocked_Bpr_Header];
GO
--- End Header to blocked




--Create relations
--- Header to details
IF NOT EXISTS
(
    SELECT *
    FROM sys.foreign_keys
    WHERE object_id = OBJECT_ID(N'[Bpr].[FK_Bpr_Details_Bpr_Header]')
          AND parent_object_id = OBJECT_ID(N'[Bpr].[Bpr_Details]')
)
    BEGIN
        ALTER TABLE [Bpr].[Bpr_Details]
        WITH CHECK
        ADD CONSTRAINT [FK_Bpr_Details_Bpr_Header] FOREIGN KEY([HEADER_ID]) REFERENCES [Bpr].[Bpr_Header]([ID]);
END;
GO
IF EXISTS
(
    SELECT *
    FROM sys.foreign_keys
    WHERE object_id = OBJECT_ID(N'[Bpr].[FK_Bpr_Details_Bpr_Header]')
          AND parent_object_id = OBJECT_ID(N'[Bpr].[Bpr_Details]')
)
    ALTER TABLE [Bpr].[Bpr_Details] CHECK CONSTRAINT [FK_Bpr_Details_Bpr_Header];
GO
--- End Header to details


--Create relations
--- Header to plans
IF NOT EXISTS
(
    SELECT *
    FROM sys.foreign_keys
    WHERE object_id = OBJECT_ID(N'[Bpr].[FK_Bpr_Plans_Bpr_Header]')
          AND parent_object_id = OBJECT_ID(N'[Bpr].[Bpr_Plans]')
)
    BEGIN
        ALTER TABLE [Bpr].[Bpr_Plans]
        WITH CHECK
        ADD CONSTRAINT [FK_Bpr_Plans_Bpr_Header] FOREIGN KEY([HEADER_ID]) REFERENCES [Bpr].[Bpr_Header]([ID]);
END;
GO
IF EXISTS
(
    SELECT *
    FROM sys.foreign_keys
    WHERE object_id = OBJECT_ID(N'[Bpr].[FK_Bpr_Plans_Bpr_Header]')
          AND parent_object_id = OBJECT_ID(N'[Bpr].[Bpr_Plans]')
)
    ALTER TABLE [Bpr].[Bpr_Plans] CHECK CONSTRAINT [FK_Bpr_Plans_Bpr_Header];
GO
--- End Header to plans



--Create relations
--- Header to resources
IF NOT EXISTS
(
    SELECT *
    FROM sys.foreign_keys
    WHERE object_id = OBJECT_ID(N'[Bpr].[FK_Bpr_Resources_Bpr_Header]')
          AND parent_object_id = OBJECT_ID(N'[Bpr].[Bpr_Resources]')
)
    BEGIN
        ALTER TABLE [Bpr].[Bpr_Resources]
        WITH CHECK
        ADD CONSTRAINT [FK_Bpr_Resources_Bpr_Header] FOREIGN KEY([HEADER_ID]) REFERENCES [Bpr].[Bpr_Header]([ID]);
END;
IF EXISTS
(
    SELECT *
    FROM sys.foreign_keys
    WHERE object_id = OBJECT_ID(N'[Bpr].[FK_Bpr_Resources_Bpr_Header]')
          AND parent_object_id = OBJECT_ID(N'[Bpr].[Bpr_Resources]')
)
    ALTER TABLE [Bpr].[Bpr_Resources] CHECK CONSTRAINT [FK_Bpr_Resources_Bpr_Header];
GO
--- End Header to resources



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
                           WHEN t.[resource_type] IN('KEY', 'PAGE', 'RID')
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
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[Bpr].[GetWaitInfo]')
          AND type IN(N'FN', N'IF', N'TF', N'FS', N'FT')
)
    DROP FUNCTION [Bpr].[GetWaitInfo];
GO
CREATE FUNCTION [Bpr].[GetWaitInfo]
(@blockingSessionId INT,
 @blockedSessionId  INT,
 @blockingEcid      INT = 0,
 @blockedEcid       INT = 0
)
RETURNS @waitInfo TABLE
([Level]                        [INT] NULL,
 [DataBaseName]                 [NVARCHAR](128) NULL,
 [VictemProgramName]            [NVARCHAR](128) NULL,
 [VictemHostName]               [NVARCHAR](128) NULL,
 [VictemSessionId]              [SMALLINT] NULL,
 [VictemSessionEcid]            [INT] NULL,
 [VictemDruationSec]            [BIGINT] NULL,
 [VictemWaitType]               [NVARCHAR](60) NULL,
 [VictemDescription]            [NVARCHAR](3072) NULL,
 [VictemWaitResource]           [NVARCHAR](256) NOT NULL,
 [VictemStartTime]              [DATETIME] NOT NULL,
 [Command]                      [NVARCHAR](32) NOT NULL,
 [CommandText]                  [NVARCHAR](MAX) NULL,
 [QueryPlan]                    [XML] NULL,
 [VictemStatus]                 [NVARCHAR](30) NOT NULL,
 [VictemIsolationLevel]         [SMALLINT] NOT NULL,
 [BLOCKED_BY]                   [VARCHAR](13) NOT NULL,
 [BlockingSessionId]            [SMALLINT] NULL,
 [BlockingEcid]                 [INT] NULL,
 [BlockingProgramName]          [NVARCHAR](128) NULL,
 [BlockingHostName]             [NVARCHAR](128) NULL,
 [BlockingLastRequestStartTime] [DATETIME] NOT NULL,
 [BlockingLastCommandText]      [NVARCHAR](MAX) NULL,
 [BlockingStatus]               [NVARCHAR](30) NOT NULL,
 [BlockingIsolationLevel]       [SMALLINT] NOT NULL
)
WITH EXECUTE AS OWNER
AS
     BEGIN
         WITH Blocking(BlockedId,
                       Ecid,
                       BlockingId,
                       BlockingEcid,
                       LevelId)
              AS (
	--Anchor 

              SELECT session_id,
                     ISNULL(exec_context_id, 0) exec_context_id,
                     blocking_session_id,
                     ISNULL(blocking_exec_context_id, 0) blocking_exec_context_id,
                     0 Level
              FROM sys.dm_os_waiting_tasks
              WHERE blocking_session_id IS NOT NULL
                    AND blocking_session_id = @blockingSessionId
                    AND session_id = @blockedSessionId
                    AND ISNULL(exec_context_id, 0) = @blockedEcid
                    AND ISNULL(blocking_exec_context_id, 0) = @blockingEcid
              UNION ALL
	--Recursive

              SELECT session_id,
                     ISNULL(exec_context_id, 0) exec_context_id,
                     blocking_session_id,
                     ISNULL(blocking_exec_context_id, 0) blocking_exec_context_id,
                     LevelId + 1 LevelId
              FROM sys.dm_os_waiting_tasks r
                   INNER JOIN blocking b ON r.session_id = b.BlockingId
                                            AND r.exec_context_id = b.BlockingEcid)
              INSERT INTO @waitInfo
              ([Level],
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
               [QueryPlan],
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
                     SELECT bl.levelid Level,
                            DB_NAME(er.database_id) DataBaseName,
                            es.program_name VictemProgramName,
                            es.host_name VictemHostName,
                            bl.BlockedId VictemSessionId,
                            bl.Ecid VictemSessionEcid,
                            wt.wait_duration_ms / 1000 VictemDruationSec,
                            wt.wait_type VictemWaitType,
                            wt.resource_description VictemDescription,
                            er.wait_resource VictemWaitResource,
                            es.last_request_start_time VictemStartTime,
                            er.command Command,
                            est.text CommandText,
                            eqp.query_plan QueryPlan,
                            es.status VictemStatus,
                            es.transaction_isolation_level VictemIsolationLevel,
                            'BLOCKED BY-->' AS BLOCKED_BY,
                            bl.BlockIngId BlockingSessionId,
                            bl.BlockingEcid BlockingEcid,
                            esBlocking.program_name BlockingProgramName,
                            esBlocking.host_name BlockingHostName,
                            esBlocking.last_request_start_time BlockingLastRequestStartTime,
                            estBlocking.text BlockingLastCommandText,
                            esBlocking.status BlockingStatus,
                            esBlocking.transaction_isolation_level BlockingIsolationLevel
	--,DTL.[resource_type] AS [resource type]
	--,CASE
	--	WHEN DTL.[resource_type] IN ('DATABASE', 'FILE', 'METADATA') THEN DTL.[resource_type]
	--	WHEN DTL.[resource_type] = 'OBJECT' THEN OBJECT_NAME(DTL.resource_associated_entity_id)
	--	WHEN DTL.[resource_type] IN ('KEY', 'PAGE', 'RID') THEN (SELECT
	--				( CASE WHEN s.name IS NOT NULL THEN s.name  +'.' ELSE '' END ) + OBJECT_NAME(p.[object_id])
	--			FROM sys.partitions p
	--			INNER JOIN sys.objects o on o.object_id = p.object_id
	--			INNER JOIN sys.schemas s on o.schema_id = s.schema_id
	--			WHERE p.[hobt_id] = DTL.[resource_associated_entity_id])
	--	ELSE 'Unidentified'
	--END AS [Parent Object]
	--,DTL.[request_mode] AS [Lock Type]
	--,DTL.[request_status] AS [Request Status]
                     FROM blocking bl WITH (NOLOCK)
                          LEFT OUTER JOIN sys.dm_os_waiting_tasks wt WITH (NOLOCK) ON bl.BlockedId = wt.session_id
                                                                                      AND bl.Ecid = wt.exec_context_id
	--INNER JOIN sys.dm_tran_locks DTL
	--	ON DTL.lock_owner_address = WT.resource_address
                          LEFT OUTER JOIN sys.dm_exec_sessions es WITH (NOLOCK) ON bl.BlockedId = es.session_id
                          LEFT OUTER JOIN sys.dm_exec_sessions esBlocking WITH (NOLOCK) ON bl.BlockingId = esBlocking.session_id
                          LEFT OUTER JOIN sys.dm_exec_requests er WITH (NOLOCK) ON es.session_id = er.session_id
                          LEFT OUTER JOIN sys.dm_exec_connections ec WITH (NOLOCK) ON bl.BlockIngId = ec.session_id
                          OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) est
                          OUTER APPLY sys.dm_exec_sql_text(ec.most_recent_sql_handle) estBlocking
                          OUTER APPLY sys.dm_exec_query_plan(er.plan_handle) eqp
                     WHERE es.is_user_process = 1;
         RETURN;
     END;
GO
ADD SIGNATURE TO OBJECT::[Bpr].[GetWaitInfo] BY CERTIFICATE [PBR] WITH PASSWORD = '$tr0ngp@$$w0rd';
GO 



--Drop if exists
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
         SET @retValue = '';
         SET @blockingType = RTRIM(SUBSTRING(@waitResource, 1, CHARINDEX(':', @waitResource)-1));
         SET @blockingKey = SUBSTRING(@waitResource, CHARINDEX(':', @waitResource)+1, LEN(@waitResource)-CHARINDEX(':', @waitResource));
         SET @dbId = SUBSTRING(@blockingKey, 1, CHARINDEX(':', @blockingKey)-1);
         IF @blockingType != 'KEY'
            AND @blockingType != 'PAGE'
             RETURN @retValue;
         IF @paramName IS NOT NULL
             BEGIN
                 SET @retValue = 'SET '+@paramName+' = (';
         END;
	--Blocking type is KEY
         IF @blockingType = 'KEY'
             BEGIN
                 SET @lockRes = LTRIM(SUBSTRING(@blockingKey, CHARINDEX('(', @blockingKey)-1, CHARINDEX(')', @blockingKey)-CHARINDEX('(', @blockingKey)+2));
                 SET @retValue = @retValue+'SELECT *
	                    FROM '+DB_NAME(@dbId)+'.'+@tableName+' (NOLOCK) 
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
                 SET @retValue = @retValue+'SELECT *
				     FROM '+DB_NAME(@dbId)+'.'+@tableName+' (NOLOCK) 
					WHERE sys.fn_PhysLocFormatter(%%physloc%%) like  '''+@lockRes+''''+' FOR XML AUTO';
         END;
         IF @paramName IS NOT NULL
             BEGIN
                 SET @retValue = @retValue+')';
         END;
         RETURN @retvalue;
     END;
GO
IF EXISTS
(
    SELECT *
    FROM sys.objects
    WHERE object_id = OBJECT_ID(N'[Bpr].[GetResourceName]')
          AND type IN(N'FN', N'IF', N'TF', N'FS', N'FT')
)
    BEGIN
        DROP FUNCTION [Bpr].[GetResourceName];
END;
GO

-- =============================================
-- Get resource name from wait info
-- KEY: 6:72057594041991168 (ce52f92a058c)
-- OBJECT: 10:1730105204:0 databaseId + objectId + lockPartition
-- PAGE: 7:1:422000 databaseId + fileId + pageId
-- FILE: 8:0
-- =============================================
CREATE FUNCTION [Bpr].[GetResourceName]
(@waitResource AS NVARCHAR(128),
 @paramName AS    SYSNAME       = NULL
)
RETURNS NVARCHAR(MAX) --we will return t-sql
AS
     BEGIN
         DECLARE @blockingType AS NVARCHAR(20);
	--type of blockin KEY,OBJECT,PAGE
         DECLARE @retValue AS NVARCHAR(MAX);
         DECLARE @dbId BIGINT;
         DECLARE @blockingKey AS NVARCHAR(256);
         SET @retValue = '';
         SET @blockingType = RTRIM(SUBSTRING(@waitResource, 1, CHARINDEX(':', @waitResource)-1));
         SET @blockingKey = SUBSTRING(@waitResource, CHARINDEX(':', @waitResource)+1, LEN(@waitResource)-CHARINDEX(':', @waitResource));
         SET @dbId = SUBSTRING(@blockingKey, 1, CHARINDEX(':', @blockingKey)-1);
         IF @blockingType = 'KEY'
             BEGIN
                 DECLARE @hobId AS BIGINT;
                 SET @hobId = RTRIM(SUBSTRING(@blockingKey, CHARINDEX(':', @blockingKey)+1, CHARINDEX('(', @blockingKey)-CHARINDEX(':', @blockingKey)-1));
                 IF @paramName IS NOT NULL
                     BEGIN
                         SET @retValue = 'SET '+@paramName+' = (';
                 END;
                 SET @retValue = @retValue+'SELECT sc.name + ''.'' +so.name +  ''('' + si.name + '')''
                           FROM '+DB_NAME(@dbId)+'.sys.partitions AS p
                           JOIN '+DB_NAME(@dbId)+'.sys.objects AS so
	                          ON p.object_id = so.object_id
                           JOIN '+DB_NAME(@dbId)+'.sys.indexes AS si
	                          ON p.index_id = si.index_id
	                          AND p.object_id = si.object_id
                           JOIN '+DB_NAME(@dbId)+'.sys.schemas AS sc
	                          ON so.schema_id = sc.schema_id
                           WHERE p.hobt_id = '+CAST(@hobId AS NVARCHAR(MAX));
                 IF @paramName IS NOT NULL
                     BEGIN
                         SET @retValue = @retValue+')';
                 END;
         END;
             ELSE
         IF @blockingType = 'OBJECT'
             BEGIN
                 DECLARE @pos AS INT;
                 DECLARE @helper AS NVARCHAR(50);
                 DECLARE @objectId AS BIGINT;
                 SET @pos = CHARINDEX(':', @blockingKey)+1;
                 SET @helper = SUBSTRING(@blockingKey, @pos, 100);
                 SET @objectId = SUBSTRING(@helper, 1, CHARINDEX(':', @helper)-1);
--SET @retValue = N'USE ' + DB_NAME(@dbId) + CHAR(13) + CHAR(10);
                 SET @retValue = N'';
                 IF @paramName IS NOT NULL
                     BEGIN
                         SET @retValue = 'SET '+@paramName+' = (';
                 END;
                 SET @retValue = @retValue+'SELECT TOP 1 s.name + ''.'' + o.name 
FROM '+DB_NAME(@dbid)+' .sys.objects o 
INNER JOIN '+DB_NAME(@dbid)+'.sys.partitions p 
    ON p.object_id = o.object_id
INNER JOIN '+DB_NAME(@dbid)+'.sys.schemas s 
    ON s.schema_id = o.schema_id
WHERE p.OBJECT_ID = '+CAST(@objectId AS NVARCHAR(MAX));
                 IF @paramName IS NOT NULL
                     BEGIN
                         SET @retValue = @retValue+')';
                 END;
         END;
             ELSE
         IF @blockingType = 'PAGE'
             BEGIN
--PAGE 7:1:422000
                 DECLARE @pos1 AS INT;
                 DECLARE @helper1 AS NVARCHAR(50);
                 DECLARE @fileId AS BIGINT;
                 DECLARE @pageId AS BIGINT;
                 SET @pos1 = CHARINDEX(':', @blockingKey)+1;
                 SET @helper1 = SUBSTRING(@blockingKey, @pos1, 100);
                 SET @fileId = SUBSTRING(@helper1, 1, CHARINDEX(':', @helper1)-1);
                 SET @pageId = CAST(SUBSTRING(@helper1, CHARINDEX(':', @helper1)+1, LEN(@helper1)-CHARINDEX(':', @helper1)) AS BIGINT);
                 SET @retValue = 'DECLARE @objectId as bigint

IF OBJECT_ID(''tempdb..#pagedata'') IS NOT NULL
BEGIN
DROP TABLE #pagedata
END;

CREATE TABLE #pagedata
( 
			 ParentObject varchar(1000) NULL, Object varchar(4000) NULL, Field varchar(1000) NULL, ObjectValue varchar(max) NULL
);

 '+'DBCC traceon (3604); '+CHAR(13)+CHAR(10)+'SET NOCOUNT ON ;'+CHAR(13)+CHAR(10)+'INSERT INTO #pagedata( ParentObject, Object, Field, ObjectValue )'+CHAR(13)+CHAR(10)+'EXEC (''DBCC page ('+CAST(@dbId AS NVARCHAR(20))+', '+CAST(@fileId AS NVARCHAR(10))+', '+CAST(@pageId AS NVARCHAR(MAX))+') WITH TABLERESULTS '')
SELECT @objectId=objectvalue
FROM #pagedata
WHERE field LIKE ''Metadata: ObjectId%'';';
                 IF @paramName IS NOT NULL
                     BEGIN
                         SET @retValue = @retValue+'SET '+@paramName+' = (';
                 END;
                 SET @retValue = @retValue+'SELECT TOP 1 s.name + ''.'' + o.name 
FROM '+DB_NAME(@dbid)+' .sys.objects o 
INNER JOIN '+DB_NAME(@dbid)+'.sys.partitions p 
    ON p.object_id = o.object_id
INNER JOIN '+DB_NAME(@dbid)+'.sys.schemas s 
    ON s.schema_id = o.schema_id
WHERE p.OBJECT_ID = @objectId ';
                 IF @paramName IS NOT NULL
                     BEGIN
                         SET @retValue = @retValue+')';
                 END;
         END;
         RETURN @retvalue;
     END;
GO
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
                                     EXEC sys.sp_executesql
                                          @sql,
                                          N'@resourceContent nvarchar(max) output',
                                          @resourceContent OUTPUT;
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

---------------------------------------------
---Create ShowBlocking 
---------------------------------------------
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

---------------------UNCOMMENT this part if you are installing on SQL Server 2017
--------------------CLR part required if you are installing on 2017 version 
--USE MASTER
--GO
----Copy snk from VS solution to path visible for your sql server instance
----Replace this path value, you password as you want
--IF NOT EXISTS (SELECT * FROM sys.asymmetric_keys WHERE name = N'keyPBR')
--BEGIN
--	CREATE ASYMMETRIC KEY keyPBR
--	FROM FILE = $(keyPath)
--	ENCRYPTION BY PASSWORD = '@Str0ngP@$$w0rd'
--END
--GO

----Use database where your installed the assembly
--USE [$(DatabaseName)];
--GO

----Create login if not exists
--IF NOT EXISTS (SELECT loginname
--	FROM master.dbo.syslogins
--	WHERE name = 'SqlClrPBRLogin')
--BEGIN
--	CREATE LOGIN SqlClrPBRLogin FROM ASYMMETRIC KEY keyPBR
--END
--GO

--USE MASTER
--GO
----Grant rights to newly create login
--GRANT UNSAFE ASSEMBLY TO SqlClrPBRLogin;

--USE [$(DatabaseName)];
--GO 
