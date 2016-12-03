Set-Location $PSScriptRoot

<#

.\Initialize-LocalDatabase.ps1 -DatabaseName NorthwindLocal

.\Initialize-Patches.ps1 -DatabaseName NorthwindLocal -Release '1.0.0'

Get-SqlServerPatchInfo
# ShowPatchInfo is alias

Publish-SqlServerPatches 
# PublishPatches

Get-SqlServerPatchHistory 
# ShowPatchHistory

ShowDbObjects
#>

Import-Module C:\Git\SqlServerPatcher\SqlServerPatcher\XmlLoader.psm1 -Force

$connection = get-SqlServerPatcherConnection

$DataLoadFiles = Get-ChildItem -Path ".\DataFiles" 


#$command = $connection.CreateCommand()
$command = New-Object System.Data.SqlClient.sqlCommand
$command.Connection = $connection 

$testFile = 'C:\temp\TestDataLoad.sql'

$output = @()

$output +=  @"
SET XACT_ABORT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;

BEGIN TRANSACTION;

GO

"@

$output += Get-FKSql -command $command -XmlDataFiles $DataLoadFiles -Disable
$output += get-XmlInsertSql -command $command -XmlDataFiles $DataLoadFiles -IncludTimestamps
$output += Get-FKSql -command $command -XmlDataFiles $DataLoadFiles 

$output += @"
IF @@ERROR <> 0 AND @@TRANCOUNT >  0 WHILE @@TRANCOUNT>0 
BEGIN
    PRINT N'ROLLBACK'
    ROLLBACK TRANSACTION;
END
WHILE @@TRANCOUNT > 0
BEGIN
 COMMIT TRANSACTION;
E
GO
"@


$output | Set-Content $testFile
