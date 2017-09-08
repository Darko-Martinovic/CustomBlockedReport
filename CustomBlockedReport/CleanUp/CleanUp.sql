--Clean up script
--
--

/* Blocked process
*/

--1. Drop event notification if exists
IF EXISTS (SELECT
		*
	FROM sys.server_event_notifications
	WHERE name = 'BPRNotification')
BEGIN
DROP EVENT NOTIFICATION BPRNotification ON SERVER;
END;
GO

--2. Drop route if exists
IF EXISTS (SELECT
		*
	FROM sys.routes
	WHERE name = 'BPRRoute')
BEGIN
DROP ROUTE BPRRoute;
END;
GO
--3. Drop service if exists
IF EXISTS (SELECT
		*
	FROM sys.services
	WHERE name = 'BPRService')
BEGIN
DROP SERVICE BPRService;
END;
GO
--4. Drop queue
IF EXISTS (SELECT
		*
	FROM sys.service_queues
	WHERE name = 'BPRQueue')
BEGIN
DROP QUEUE BPRQueue;
END;



--Drop relations
--- Header to message
IF EXISTS (SELECT
		*
	FROM sys.foreign_keys
	WHERE object_id = OBJECT_ID(N'[Bpr].[FK_Bpr_Message_Bpr_Header]')
	AND parent_object_id = OBJECT_ID(N'[Bpr].[Bpr_Message]'))
BEGIN
	ALTER TABLE [Bpr].[Bpr_Message] DROP CONSTRAINT [FK_Bpr_Message_Bpr_Header];
END

--- Header to blocking
IF EXISTS (SELECT
		*
	FROM sys.foreign_keys
	WHERE object_id = OBJECT_ID(N'[Bpr].[FK_Bpr_Blocking_Bpr_Header]')
	AND parent_object_id = OBJECT_ID(N'[Bpr].[Bpr_LockInfoBlocking]'))
BEGIN
	ALTER TABLE [Bpr].[Bpr_LockInfoBlocking] DROP CONSTRAINT [FK_Bpr_Blocking_Bpr_Header];
END
--- End Header to blocking


--- Header to blocked
IF EXISTS (SELECT
		*
	FROM sys.foreign_keys
	WHERE object_id = OBJECT_ID(N'[Bpr].[FK_Bpr_Blocked_Bpr_Header]')
	AND parent_object_id = OBJECT_ID(N'[Bpr].[Bpr_LockInfoBlocked]'))
BEGIN
	ALTER TABLE [Bpr].[Bpr_LockInfoBlocked] DROP CONSTRAINT [FK_Bpr_Blocked_Bpr_Header];
END
--- End Header to blocked


--- Header to details
IF EXISTS (SELECT
		*
	FROM sys.foreign_keys
	WHERE object_id = OBJECT_ID(N'[Bpr].[FK_Bpr_Details_Bpr_Header]')
	AND parent_object_id = OBJECT_ID(N'[Bpr].[Bpr_Details]'))
BEGIN
	ALTER TABLE [Bpr].[Bpr_Details] DROP CONSTRAINT [FK_Bpr_Details_Bpr_Header];
END
--- End Header to details



--- Header to plans
IF EXISTS (SELECT
		*
	FROM sys.foreign_keys
	WHERE object_id = OBJECT_ID(N'[Bpr].[FK_Bpr_Plans_Bpr_Header]')
	AND parent_object_id = OBJECT_ID(N'[Bpr].[Bpr_Plans]'))
BEGIN
	ALTER TABLE [Bpr].[Bpr_Plans] DROP CONSTRAINT [FK_Bpr_Plans_Bpr_Header];
END


--- Header to resources
IF EXISTS (SELECT
		*
	FROM sys.foreign_keys
	WHERE object_id = OBJECT_ID(N'[Bpr].[FK_Bpr_Resources_Bpr_Header]')
	AND parent_object_id = OBJECT_ID(N'[Bpr].[Bpr_Resources]'))
BEGIN
	ALTER TABLE [Bpr].[Bpr_Resources] DROP CONSTRAINT [FK_Bpr_Resources_Bpr_Header];
END
GO

--- End Header to resources



--Drop indexes 
IF EXISTS (SELECT
		*
	FROM sys.indexes
	WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_Header]')
	AND name = N'IX_Bpr_BlockedProcessReporter_Header')
BEGIN
	DROP INDEX [IX_Bpr_BlockedProcessReporter_Header] ON [Bpr].[Bpr_Header];
END
GO


--Indexes on Bpr_Messages
IF EXISTS (SELECT
		*
	FROM sys.indexes
	WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_Message]')
	AND name = N'IX_Brp_Message')
BEGIN
	DROP INDEX [IX_Brp_Message] ON [Bpr].[Bpr_Message];
END
GO

--Indexes on Bpr_LockInfoBlocking
IF EXISTS (SELECT
		*
	FROM sys.indexes
	WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_LockInfoBlocking]')
	AND name = N'IX_Brp_LockInfoBlocking')
BEGIN
	DROP INDEX [IX_Brp_LockInfoBlocking] ON [Bpr].[Bpr_LockInfoBlocking];
END
GO

--Indexes on Bpr_LockInfoBlocked
IF EXISTS (SELECT
		*
	FROM sys.indexes
	WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_LockInfoBlocked]')
	AND name = N'IX_Brp_LockInfoBlocked')
BEGIN
	DROP INDEX [IX_Brp_LockInfoBlocking] ON [Bpr].[Bpr_LockInfoBlocked];
END
GO

--Index on query plans
IF EXISTS (SELECT
		*
	FROM sys.indexes
	WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_Plans]')
	AND name = N'IX_Brp_Plans')
BEGIN
	DROP INDEX [IX_Brp_Plans] ON [Bpr].[Bpr_Plans];
END
GO

--Index on resources
IF EXISTS (SELECT
		*
	FROM sys.indexes
	WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_Resources]')
	AND name = N'IX_Brp_Resources')
BEGIN
	DROP INDEX [IX_Brp_Resources] ON [Bpr].[Bpr_Resources];
END
GO

--Index on details
IF EXISTS (SELECT
		*
	FROM sys.indexes
	WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_Details]')
	AND name = N'IX_Bpr_Details')
BEGIN
	DROP INDEX [IX_Bpr_Details] ON [Bpr].[Bpr_Details];
END
GO



--Drop all tables if exists

--Drop messages
IF EXISTS (SELECT
		*
	FROM sys.objects
	WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_Message]')
	AND type IN (N'U'))
BEGIN
DROP TABLE [Bpr].[Bpr_Message];
END
GO

--Drop bad messages
IF EXISTS (SELECT
		*
	FROM sys.objects
	WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_BadMessage]')
	AND type IN (N'U'))
BEGIN
DROP TABLE [Bpr].[Bpr_BadMessage];
END
GO

--Drop details

IF EXISTS (SELECT
		*
	FROM sys.objects
	WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_Details]')
	AND type IN (N'U'))
BEGIN
	DROP TABLE [Bpr].[Bpr_Details];
END
GO
--Drop query plans
IF EXISTS (SELECT
		*
	FROM sys.objects
	WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_Plans]')
	AND type IN (N'U'))
BEGIN
	DROP TABLE [Bpr].[Bpr_Plans];
END
GO


--Drop query resources
IF EXISTS (SELECT
		*
	FROM sys.objects
	WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_Resources]')
	AND type IN (N'U'))
BEGIN
	DROP TABLE [Bpr].[Bpr_Resources];
END
GO

--Drop lock info blocking
IF EXISTS (SELECT
		*
	FROM sys.objects
	WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_LockInfoBlocking]')
	AND type IN (N'U'))
BEGIN
	DROP TABLE [Bpr].[Bpr_LockInfoBlocking];
END
GO

--Drop lock info blocked
IF EXISTS (SELECT
		*
	FROM sys.objects
	WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_LockInfoBlocked]')
	AND type IN (N'U'))
BEGIN
	DROP TABLE [Bpr].[Bpr_LockInfoBlocked];
END
GO



--Drop header
IF EXISTS (SELECT
		*
	FROM sys.objects
	WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_Header]')
	AND type IN (N'U'))
BEGIN
	DROP TABLE [Bpr].[Bpr_Header];
END
GO



--Drop configuration
IF EXISTS (SELECT
		*
	FROM sys.objects
	WHERE object_id = OBJECT_ID(N'[Bpr].[Bpr_Configuration]')
	AND type IN (N'U'))
BEGIN
	DROP TABLE [Bpr].[Bpr_Configuration];
END
GO



--Drop function
IF EXISTS (SELECT
		*
	FROM sys.objects
	WHERE object_id = OBJECT_ID(N'[Bpr].[GetLockInfo]')
	AND type IN (N'FN', N'IF', N'TF', N'FS', N'FT'))
	DROP FUNCTION [Bpr].[GetLockInfo];
GO


IF  EXISTS (SELECT
		*
	FROM sys.objects
	WHERE object_id = OBJECT_ID(N'[Bpr].[GetWaitInfo]')
	AND type IN (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [Bpr].[GetWaitInfo]

GO

IF EXISTS (SELECT
		*
	FROM sys.objects
	WHERE object_id = OBJECT_ID(N'[Bpr].[GetResourceName]')
	AND type IN (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
DROP FUNCTION [Bpr].[GetResourceName]
END;
GO

--Drop if exists
IF EXISTS (SELECT
		*
	FROM sys.objects
	WHERE object_id = OBJECT_ID(N'[Bpr].[GetResourceContent]')
	AND type IN (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
DROP FUNCTION [Bpr].[GetResourceContent]
END
GO

IF EXISTS (SELECT
		*
	FROM sys.schemas
	WHERE name = N'BPR')
EXEC ('DROP SCHEMA [BPR] ');
GO
