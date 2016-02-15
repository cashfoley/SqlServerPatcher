@{

############################################################################################################################

    AssureSqlServerSafePatchQuery = @"
-- Adds SqlServerSafePatch Objects if they don't exist
--    SCHEMA [SqlServerSafePatch]
--    TABLE [SqlServerSafePatch].[FilePatches]
--    PROCEDURE #MarkPatchExecuted

BEGIN TRANSACTION;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'SqlServerSafePatch')
EXEC sys.sp_executesql N'CREATE SCHEMA [SqlServerSafePatch] AUTHORIZATION [dbo]'
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[SqlServerSafePatch].[FilePatches]') AND type in (N'U'))
BEGIN
CREATE TABLE [SqlServerSafePatch].[FilePatches](
    [OID]             [bigint]   IDENTITY(1,1) NOT NULL,
    [FilePath]        [nvarchar] (450) NOT NULL,
    [Applied]         [datetime] NOT NULL,
	[ExecutedByForce] [bit] NULL,
	[UpdatedOnChange] [bit] NULL,
	[RollBacked]      [bit] NULL,
    [CheckSum]        [nvarchar] (512) NOT NULL,
    [PatchScript]     [nvarchar] (MAX),
    [LogOutput]       [nvarchar] (MAX)
) ON [PRIMARY]
    
END
GO

IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'#MarkPatchExecuted') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
	CREATE PROCEDURE #MarkPatchExecuted     
        @FilePath [nvarchar](450),
        @CheckSum [nvarchar](100),
        @PatchScript  [nvarchar](MAX),
		@ExecutedByForce [bit],
		@UpdatedOnChange [bit]
    AS
    BEGIN
        SET NOCOUNT ON;

        INSERT 
            INTO [SqlServerSafePatch].[FilePatches]
                ( [FilePath]
                , [Applied]
                , [CheckSum]
                , [PatchScript]
				, [ExecutedByForce]
				, [UpdatedOnChange]
                )
         VALUES ( @FilePath
                , GetDate()
                , @CheckSum
                , @PatchScript
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

    GetSqlServerSafePatchVersion = @"
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[SqlServerSafePatch].[FilePatches]') AND type in (N'U'))
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
  FROM [SqlServerSafePatch].[FilePatches]
 WHERE OID = (SELECT MAX(OID)
                FROM [SqlServerSafePatch].[FilePatches]
               WHERE FilePath = @FilePath)
"@

############################################################################################################################

    MarkPatchAsExecutedQuery = "EXEC #MarkPatchExecuted N'{0}',N'{1}',N'{2}',N'{3}',N'{4}'"

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