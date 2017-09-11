--Your database name

USE AdventureWorks2014;
GO
CREATE CERTIFICATE [PBR] ENCRYPTION BY PASSWORD = '$tr0ngp@$$w0rd' WITH SUBJECT = 'Proces blocked report';
GO

-- Backup certificate so it can be create in master database

BACKUP CERTIFICATE [PBR] TO FILE = 'C:\TMP\PBR.CER';
GO
USE MASTER;
GO

-- Add Certificate to Master Database

CREATE CERTIFICATE [PBR] FROM FILE = 'C:\TMP\PBR.CER';
GO
-- Create a login from the certificate

CREATE LOGIN [PBR] FROM CERTIFICATE [PBR];
GO
GRANT AUTHENTICATE SERVER TO [PBR];
GO
GRANT VIEW SERVER STATE TO [PBR];
GO
USE AdventureWorks2014;
GO
CREATE USER [PBR] FROM LOGIN [PBR];
GO

--ALTER ROLE DB_OWNER ADD MEMBER PBR

 
-- Sign the procedure with the certificate's private key

ADD SIGNATURE TO OBJECT::[Bpr].[GetWaitInfo] BY CERTIFICATE [PBR] WITH PASSWORD = '$tr0ngp@$$w0rd';
GO
ADD SIGNATURE TO OBJECT::[Bpr].[GetLockInfo] BY CERTIFICATE [PBR] WITH PASSWORD = '$tr0ngp@$$w0rd';
GO
ADD SIGNATURE TO OBJECT::[Bpr].[HandleBPR] BY CERTIFICATE [PBR] WITH PASSWORD = '$tr0ngp@$$w0rd';
GO
