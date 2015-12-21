Import-Module Pester

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2

$TestSqlServer = '.'
$TestDatabase = 'ScriptTest'

$DeleteDatabaseScript = @"
IF EXISTS(select * from sys.databases where name='{0}')
BEGIN
    ALTER DATABASE [{0}] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
    DROP DATABASE [{0}]
END
"@

$CreateDatabaseScript = 'CREATE DATABASE [{0}]'

function Initialize-TestDatabase
{
     param
     (
         [string] $ServerName,
         [string] $DatabaseName
     )

    try
    {
        $IntegratedConnectionString = 'Data Source={0}; Integrated Security=True;MultipleActiveResultSets=False;Application Name="SQL Management"'
        $Connection = (New-Object 'System.Data.SqlClient.SqlConnection')
        $Connection.ConnectionString = $IntegratedConnectionString -f $ServerName
        $Connection.Open()

        $SqlCmd = $Connection.CreateCommand()
        $SqlCmd.CommandType = [System.Data.CommandType]::Text

        $SqlCmd.CommandText = ($DeleteDatabaseScript -f $TestDatabase)
        $SqlCmd.CommandText
        [void]($SqlCmd.ExecuteNonQuery())

        $SqlCmd.CommandText = ($CreateDatabaseScript -f $TestDatabase)
        $SqlCmd.CommandText
        [void]($SqlCmd.ExecuteNonQuery())

        $Connection.ChangeDatabase($TestDatabase)

        $Connection
    }
    Catch
    {
        Write-Error ('Error while Re-Creating Datbase {0}.{1} - {2}' -f $ServerName,$DatabaseName,$_)
    }

}


#$Connection = $null
#Describe "Get-SqlConnecti)n" {
#    It 'Connects to our Test SQL Server ' {
#        $script:connection = Get-SqlConnection $TestSqlServer
#        $connection.State | Should Be 'Open'
#    }
#}
#
#$Connection.State

$Connection = Initialize-TestDatabase $TestSqlServer 

