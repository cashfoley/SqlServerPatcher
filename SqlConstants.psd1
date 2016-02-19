@{

############################################################################################################################

    AssureSqlSafePatchQuery = @"
-- Adds SqlSafePatch Objects if they don't exist
--    SCHEMA [SqlSafePatch]
--    TABLE [SqlSafePatch].[FilePatches]
--    PROCEDURE #MarkPatchExecuted

BEGIN TRANSACTION;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'SqlSafePatch')
EXEC sys.sp_executesql N'CREATE SCHEMA [SqlSafePatch] AUTHORIZATION [dbo]'
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[SqlSafePatch].[FilePatches]') AND type in (N'U'))
BEGIN
CREATE TABLE [SqlSafePatch].[FilePatches](
    [OID]               [bigint]   IDENTITY(1,1) NOT NULL,
    [PatchName]         [nvarchar] (450) NOT NULL,
    [Applied]           [datetime] NOT NULL,
	[ExecutedByForce]   [bit] NULL,
	[UpdatedOnChange]   [bit] NULL,
	[RollBacked]        [bit] NULL,
    [CheckSum]          [nvarchar] (512) NOT NULL,
    [PatchScript]       [nvarchar] (MAX),
    [RollbackScript]    [nvarchar] (max),
    [RollbackChecksum]  [nvarchar] (512),
    [LogOutput]         [nvarchar] (MAX)
) ON [PRIMARY]
    
END
GO

IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'#InsertFilePatch') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
	CREATE PROCEDURE #InsertFilePatch     
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
            INTO [SqlSafePatch].[FilePatches]
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
SELECT [OID]
      ,[PatchName]
      ,[Applied]
      ,[ExecutedByForce]
      ,[UpdatedOnChange]
      ,[RollBacked]
      ,[CheckSum]
      ,[PatchScript]
      ,[RollbackScript]
      ,[RollbackChecksum]
      ,[LogOutput]
  FROM [SqlSafePatch].[FilePatches]
"@

############################################################################################################################

    GetSqlSafePatchVersion = @"
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[SqlSafePatch].[FilePatches]') AND type in (N'U'))
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
  FROM [SqlSafePatch].[FilePatches]
 WHERE OID = (SELECT MAX(OID)
                FROM [SqlSafePatch].[FilePatches]
               WHERE PatchName = @PatchName)
"@

############################################################################################################################

    InsertFilePatchSQL = "EXEC #InsertFilePatch N'{0}',N'{1}',N'{2}',N'{3}',N'{4}',N'{5}',N'{6}'"

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


}