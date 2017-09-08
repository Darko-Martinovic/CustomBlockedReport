--Configure blocked process threshold 
sp_configure 'show advanced options'
,            1 ;
GO
RECONFIGURE;
GO
sp_configure 'blocked process threshold'
,            10;
GO
RECONFIGURE;
GO

--login/user userBlocking
CREATE LOGIN [userBlocking] 
    WITH PASSWORD=N'myTestPass',
         DEFAULT_DATABASE=[master], 
	    DEFAULT_LANGUAGE=[us_english], 
	    CHECK_EXPIRATION=OFF, 
	    CHECK_POLICY=OFF;
GO
CREATE USER [userBlocking] 
    FOR LOGIN [userBlocking] 
    WITH DEFAULT_SCHEMA=[dbo];
GO
GRANT 
    SELECT, INSERT, UPDATE,DELETE, EXECUTE 
    ON SCHEMA::Person 
    TO userBlocking;
GO
--login/user userBlocked
CREATE LOGIN [userBlocked] 
    WITH PASSWORD=N'myTestPass',
         DEFAULT_DATABASE=[master], 
	    DEFAULT_LANGUAGE=[us_english], 
	    CHECK_EXPIRATION=OFF, 
	    CHECK_POLICY=OFF;

GO
CREATE USER [userBlocked] 
    FOR LOGIN [userBlocked] 
    WITH DEFAULT_SCHEMA=[dbo]
GO
GRANT 
    SELECT, INSERT, UPDATE,DELETE, EXECUTE 
    ON SCHEMA::Person 
    TO userBlocked
GO


