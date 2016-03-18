[CmdletBinding(SupportsShouldProcess = $TRUE,ConfirmImpact = 'Medium')]

param
(
    [string] $ServerName = '.',
    [string] $DatabaseName = 'NorthwindLocal'
)

$DeleteDatabaseScript = @"
IF EXISTS(select * from sys.databases where name='{0}')
BEGIN
    ALTER DATABASE [{0}] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
    DROP DATABASE [{0}]
END
"@

$CreateDatabaseScript = 'CREATE DATABASE [{0}]'

try
{
    $IntegratedConnectionString = 'Data Source={0}; Integrated Security=True;MultipleActiveResultSets=False;Application Name="SQL Management"'
    $Connection = (New-Object 'System.Data.SqlClient.SqlConnection')
    $Connection.ConnectionString = $IntegratedConnectionString -f $ServerName
    $Connection.Open()

    $SqlCmd = $Connection.CreateCommand()
    $SqlCmd.CommandType = [System.Data.CommandType]::Text

    $SqlCmd.CommandText = ($DeleteDatabaseScript -f $DatabaseName)
    Write-Verbose $SqlCmd.CommandText
    [void]($SqlCmd.ExecuteNonQuery())

    $SqlCmd.CommandText = ($CreateDatabaseScript -f $DatabaseName)
    Write-Verbose $SqlCmd.CommandText
    [void]($SqlCmd.ExecuteNonQuery())

    $Connection.ChangeDatabase($DatabaseName)

    $Connection
}
Catch
{
    Write-Error ('Error while Re-Creating Datbase {0}.{1} - {2}' -f $ServerName,$DatabaseName,$_)
}

