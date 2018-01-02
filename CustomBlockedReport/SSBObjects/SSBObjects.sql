---! ENABLE BROKER 
USE MASTER
GO
ALTER DATABASE AdventureWorks2014 SET NEW_BROKER;
GO
USE AdventureWorks2014
GO
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

ALTER QUEUE BPRQueue WITH ACTIVATION(STATUS = ON, PROCEDURE_NAME = [BPR].[HandleBPR], MAX_QUEUE_READERS = 1, EXECUTE AS OWNER);
