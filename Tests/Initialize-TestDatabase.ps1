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
    Write-Verbose $SqlCmd.CommandText
    [void]($SqlCmd.ExecuteNonQuery())

    $SqlCmd.CommandText = ($CreateDatabaseScript -f $TestDatabase)
    Write-Verbose $SqlCmd.CommandText
    [void]($SqlCmd.ExecuteNonQuery())

    $Connection.ChangeDatabase($TestDatabase)

    $Connection
}
Catch
{
    Write-Error ('Error while Re-Creating Datbase {0}.{1} - {2}' -f $ServerName,$DatabaseName,$_)
}

