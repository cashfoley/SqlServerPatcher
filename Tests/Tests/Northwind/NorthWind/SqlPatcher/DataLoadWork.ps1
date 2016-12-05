$TargetDatabaseName = 'NorthwindLocal'
$TargetServerName = '.'
$OutputFile = 'C:\temp\TestDataLoad.sql'

Set-Location $PSScriptRoot

Import-Module C:\Git\SqlServerPatcher\SqlServerPatcher\XmlLoader.psm1 -Force

$BeginTransaction =  @"
SET XACT_ABORT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;

BEGIN TRANSACTION;

GO

"@

$EndTransaction = @"
IF @@ERROR <> 0 AND @@TRANCOUNT >  0 WHILE @@TRANCOUNT>0 
BEGIN
    PRINT N'ROLLBACK'
    ROLLBACK TRANSACTION;
END
WHILE @@TRANCOUNT > 0
BEGIN
    PRINT N'DATA LOAD COMMITTED'
    COMMIT TRANSACTION;
END
GO
"@


$IntegratedConnectString = 'Data Source={0}; Initial Catalog={1}; Integrated Security=True;MultipleActiveResultSets=False;Application Name="SQL Management"'

$connectionString = $IntegratedConnectString -f $TargetServerName,$TargetDatabaseName
$connection = [System.Data.SqlClient.SqlConnection]::new($connectionString)
$connection.Open()

try
{
    $DataLoadFiles = Get-ChildItem -Path ".\DataFiles" 

    $output = @()
    $output += $BeginTransaction
    $output += Get-FKSql -connection $connection -XmlDataFiles $DataLoadFiles -Disable
    $output += get-XmlInsertSql -connection $connection -XmlDataFiles $DataLoadFiles -IncludTimestamps
    $output += Get-FKSql -connection $connection -XmlDataFiles $DataLoadFiles 
    $output += $EndTransaction

    $output | Set-Content $OutputFile
}
finally
{
    $connection.Close()
}

