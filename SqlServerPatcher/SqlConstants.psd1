@{

############################################################################################################################

    AssureSqlServerPatcherQuery = @"
-- Adds SqlServerPatcher Objects if they don't exist
--    SCHEMA [SqlServerPatcher]
--    TABLE [SqlServerPatcher].[FilePatches]
--    PROCEDURE #MarkPatchExecuted

BEGIN TRANSACTION;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'SqlServerPatcher')
EXEC sys.sp_executesql N'CREATE SCHEMA [SqlServerPatcher] AUTHORIZATION [dbo]'
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[SqlServerPatcher].[FilePatches]') AND type in (N'U'))
BEGIN
    CREATE TABLE [SqlServerPatcher].[FilePatches](
        [OID]               [bigint]   IDENTITY(1,1) NOT NULL,
        [PatchName]         [nvarchar] (450) NOT NULL,
        [Applied]           [datetime] NOT NULL,
	    [ExecutedByForce]   [bit]      NOT NULL,
	    [UpdatedOnChange]   [bit]      NOT NULL,
	    [IsRollback]        [bit]      NOT NULL,
        [RollbackedByOID]   [bigint] NULL,
        [CheckSum]          [nvarchar] (512) NOT NULL,
        [PatchScript]       [nvarchar] (MAX),
        [RollbackScript]    [nvarchar] (max),
        [RollbackChecksum]  [nvarchar] (512),
        [LogOutput]         [nvarchar] (MAX)
    ) ON [PRIMARY]
    
    ALTER TABLE [SqlServerPatcher].[FilePatches] ADD  CONSTRAINT [DF_FilePatches_ExecutedByForce]  DEFAULT ((0)) FOR [ExecutedByForce]

    ALTER TABLE [SqlServerPatcher].[FilePatches] ADD  CONSTRAINT [DF_FilePatches_UpdatedOnChange]  DEFAULT ((0)) FOR [UpdatedOnChange]

    ALTER TABLE [SqlServerPatcher].[FilePatches] ADD  CONSTRAINT [DF_FilePatches_IsRollback]  DEFAULT ((0)) FOR [IsRollback]

END
GO

IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'InsertFilePatch') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
	CREATE PROCEDURE InsertFilePatch     
        @PatchName [nvarchar](450),
        @CheckSum [nvarchar](100),
        @PatchScript  [nvarchar](MAX),
        @RollbackScript  [nvarchar](MAX),
        @RollbackCheckSum [nvarchar](100),
		@ExecutedByForce [bit],
		@UpdatedOnChange [bit]
    AS
    BEGIN
        SET NOCOUNT ON;

        INSERT 
            INTO [SqlServerPatcher].[FilePatches]
                ( [PatchName]
                , [Applied]
                , [CheckSum]
                , [PatchScript]
                , [RollbackScript]
                , [RollbackCheckSum]
				, [ExecutedByForce]
				, [UpdatedOnChange]
                )
         VALUES ( @PatchName
                , GetDate()
                , @CheckSum
                , @PatchScript
                , @RollbackScript
                , @RollbackCheckSum
				, @ExecutedByForce
				, @UpdatedOnChange
				)
    END
' 
END
GO

COMMIT TRANSACTION;
"@

############################################################################################################################

    SelectFilePatchesQuery = @"
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[SqlServerPatcher].[FilePatches]') AND type in (N'U'))
BEGIN
    SELECT [OID]
         , [PatchName]
         , [Applied]
         , [ExecutedByForce]
         , [UpdatedOnChange]
         , [IsRollback]
         , [RollbackedByOID]
         , [CheckSum]
         , [PatchScript]
         , [RollbackScript]
         , [RollbackChecksum]
         , [LogOutput]
      FROM [SqlServerPatcher].[FilePatches] FilePatches
     ORDER BY [OID]
END
"@

############################################################################################################################

    GetSqlServerPatcherVersion = @"
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[SqlServerPatcher].[FilePatches]') AND type in (N'U'))
BEGIN
    SELECT 1
END
ELSE BEGIN
    SELECT 0
END
"@

############################################################################################################################
    ChecksumForPatchQuery = @"
SELECT ChecKSum 
  FROM [SqlServerPatcher].[FilePatches]
 WHERE OID = (SELECT MAX(OID)
                FROM [SqlServerPatcher].[FilePatches]
               WHERE PatchName = @PatchName
             )
"@

############################################################################################################################

    InsertFilePatchSQL = "EXEC InsertFilePatch N'{0}',N'{1}',N'{2}',N'{3}',N'{4}',N'{5}',N'{6}'"

############################################################################################################################
    
    InsertRollback = @"
BEGIN TRANSACTION;
-- Reverse Scripts for Rollback
INSERT 
  INTO [SqlServerPatcher].[FilePatches]
     ( [PatchName]
     , [Applied]
     , [IsRollback]
     , [RollbackedByOID]
     , [CheckSum]
     , [PatchScript]
     , [RollbackChecksum]
     , [RollbackScript]
	 )
SELECT [PatchName]
     , GetDate()
     , ~(IsRollback)
     , NULL
     , [RollbackChecksum]
     , [RollbackScript]
     , [CheckSum]
     , [PatchScript]
  FROM [SqlServerPatcher].[FilePatches]
 WHERE OID = {0};

UPDATE [SqlServerPatcher].[FilePatches]
   SET [RollbackedByOID] = SCOPE_IDENTITY()
 WHERE OID = {0};

COMMIT TRANSACTION;
"@

############################################################################################################################

    GetLastRollback = @"
    SELECT [OID]
         , [PatchName]
         , [Applied]
         , [ExecutedByForce]
         , [UpdatedOnChange]
         , [IsRollback]
         , [RollbackedByOID]
         , [CheckSum]
         , [PatchScript]
         , [RollbackScript]
         , [RollbackChecksum]
         , [LogOutput]
      FROM [SqlServerPatcher].[FilePatches] FilePatches
     WHERE [OID] = SCOPE_IDENTITY()
"@

############################################################################################################################

    BeginTransctionScript = @"
SET XACT_ABORT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
BEGIN TRANSACTION;
"@
# Useful for Debug
# PRINT N'Transaction Count - ' + CAST (@@TRANCOUNT+1 AS varchar) 

############################################################################################################################

    EndTransactionScript = @"
IF @@ERROR <> 0 AND @@TRANCOUNT >  0 WHILE @@TRANCOUNT>0 ROLLBACK TRANSACTION;
WHILE @@TRANCOUNT > 0 COMMIT TRANSACTION;
"@

############################################################################################################################

    RollbackTransactionScript = @"
WHILE @@TRANCOUNT>0 ROLLBACK TRANSACTION;
"@

############################################################################################################################

    SqlObjectsQuery = @"
SELECT [s].[name] Schema_Name
     , [o].[name] Object_Name
	 , [o].[type]
     , [o].[type_desc]
     , [o].[create_date]
     , [o].[modify_date]
  FROM [sys].[objects] o
     , [sys].[schemas] s
 WHERE [o].[schema_id] = [s].[schema_id]
   AND [o].[type] != 'S'
   AND [s].[name] != 'sys'
  ORDER BY Schema_Name,Type,Object_Name
--   AND ([o].[type] in ('V','U','P','FN') OR 
--        ('ALL' = '{0}' AND [o].[type] != 'S') )
"@

############################################################################################################################

}
