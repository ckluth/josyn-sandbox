USE [master];
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'josyn-db-local')
BEGIN
    ALTER DATABASE [josyn-db-local] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [josyn-db-local];
END
GO

CREATE DATABASE [josyn-db-local];
GO

IF EXISTS (SELECT name FROM sys.server_principals WHERE name = 'tu.josyn')
    DROP LOGIN [tu.josyn];
GO

CREATE LOGIN [tu.josyn]
    WITH PASSWORD = 'josyn',
         CHECK_POLICY     = OFF,
         CHECK_EXPIRATION = OFF;
GO

USE [josyn-db-local];
GO

CREATE USER [tu.josyn]
    FOR LOGIN [tu.josyn];
GO

ALTER ROLE [db_owner]
    ADD MEMBER [tu.josyn];
GO

CREATE SCHEMA [josyn];
GO

CREATE TABLE [josyn].[SessionStore]
(
    [Id]          INT              NOT NULL IDENTITY(1,1),
    [UID]         UNIQUEIDENTIFIER NOT NULL,
    [JobTypeName] NVARCHAR(256)    NOT NULL,
    [Arguments]   NVARCHAR(MAX)    NOT NULL,
    [Result]      NVARCHAR(MAX)    NOT NULL,

    CONSTRAINT [PK_SessionStore] PRIMARY KEY CLUSTERED ([Id])
);
GO
