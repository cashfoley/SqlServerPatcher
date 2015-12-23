@{

############################################################################################################################

    AssurePsDbDeployQuery = @"
-- Adds PsDbDeploy Objects if they don't exist
--    SCHEMA [PsDbDeploy]
--    TABLE [PsDbDeploy].[FilePatches]
--    PROCEDURE #MarkPatchExecuted

BEGIN TRANSACTION;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'PsDbDeploy')
EXEC sys.sp_executesql N'CREATE SCHEMA [PsDbDeploy] AUTHORIZATION [dbo]'
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PsDbDeploy].[FilePatches]') AND type in (N'U'))
BEGIN
CREATE TABLE [PsDbDeploy].[FilePatches](
    [OID]        [bigint]   IDENTITY(1,1) NOT NULL,
    [FilePath]   [nvarchar] (450) NOT NULL,
    [Applied]    [datetime] NOT NULL,
    [CheckSum]   [nvarchar] (512) NOT NULL,
    [Content]    [nvarchar] (MAX),
    [LogOutput]  [nvarchar] (MAX)
) ON [PRIMARY]
    
CREATE UNIQUE NONCLUSTERED INDEX [UIDX_PsDbDeployFilePatches_FilePath] ON [PsDbDeploy].[FilePatches]
(
    [FilePath] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

END
GO

IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'#MarkPatchExecuted') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
    CREATE PROCEDURE #MarkPatchExecuted     
        @FilePath [nvarchar](450),
        @CheckSum [nvarchar](100),
        @Content  [nvarchar](4000)
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @OID bigint

        SELECT @OID=OID
            FROM [PsDbDeploy].[FilePatches]
            WHERE FilePath = @FilePath

        IF  (@@ROWCOUNT = 0)
        BEGIN
            INSERT 
                INTO [PsDbDeploy].[FilePatches]
                    ( [FilePath]
                    , [Applied]
                    , [CheckSum]
                    , [Content])
            VALUES (@FilePath
                    , GetDate()
                    , @CheckSum
                    , @Content)
        END
        ELSE BEGIN
            UPDATE [PsDbDeploy].[FilePatches]
                SET CheckSum=@CheckSum
                    , Applied=GetDate()
                    , Content=@Content
                WHERE OID=@OID
                AND CheckSum<>@CheckSum
        END
    END
' 
END
GO

COMMIT TRANSACTION;
"@

############################################################################################################################

    GetPsDbDeployVersion = @"
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PsDbDeploy].[FilePatches]') AND type in (N'U'))
BEGIN
    SELECT 1
END
ELSE BEGIN
    SELECT 0
END
"@

############################################################################################################################
    ChecksumForPatchQuery = @"
SELECT CheckSum
    FROM [PsDbDeploy].[FilePatches]
    WHERE FilePath = @FilePath
"@

############################################################################################################################

    MarkPatchAsExecutedQuery = "EXEC #MarkPatchExecuted N'{0}',N'{1}',N'{2}'"

}