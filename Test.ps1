Import-Module Pester

cls

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


. (Join-Path $PSScriptRoot foo2.ps1)


function Test-ForPatches
{
     param
     (
         [Array] $TestPatchNames,

         [switch] $PartialList,

         [string] $Description='Verify Patches Included'
     )

    $PatchNames = $QueuedPatches | %{$_.PatchName}
    Describe $Description {
        if (! $PartialList)
        { 
            It "Should contain $($TestPatchNames.Count) Patches" {
                ($PatchNames.Count) | Should be $TestPatchNames.Count
            }
        }

        foreach ($TestPatchName in $TestPatchNames)
        {
            It "Should contain $TestPatchName" {
                $PatchNames -contains $TestPatchName | Should be $true
            }
        }
    }

}


$outFolderPath = Join-Path $PSScriptRoot 'TestOutput'
$rootFolderPath = Join-Path $PSScriptRoot 'Tests\SqlScripts'

function InitDbPatches
{
     param
     (
         [string] $Environment = ''
     )

    Initialize-PsDbDeploy -ServerName $TestSqlServer `
                          -DatabaseName $TestDatabase `
                          -RootFolderPath $rootFolderPath `
                          -OutFolderPath $outFolderPath `
                          -Environment $Environment 
}


##############################################################################################################################

[void](Initialize-TestDatabase $TestSqlServer)

InitDbPatches

Get-ChildItem $rootFolderPath -recurse -Filter *.sql | Add-SqlDbPatches -ExecuteOnce -Verbose   

Test-ForPatches -TestPatchNames @(
    'BeforeOneTime\01_SampleItems.sql'
    'BeforeOneTime\02_ScriptsRun.sql'
    'BeforeOneTime\03_ScriptsRunErrors.sql'
    'BeforeOneTime\04_Version.sql'
)


Publish-Patches

# ------------------------------------

InitDbPatches
Get-ChildItem $rootFolderPath -recurse -Filter *.sql | Add-SqlDbPatches -ExecuteOnce -Verbose

Describe 'Verify No Patches to be run after publish' {
    It 'Should contain 0 Patches' {
        ($QueuedPatches.Count) | Should be 0
    }
}

Publish-Patches

##############################################################################################################################

[void](Initialize-TestDatabase $TestSqlServer)

InitDbPatches -Environment 'Dev'

Get-ChildItem $rootFolderPath -recurse -Filter *.sql | Add-SqlDbPatches -ExecuteOnce -Verbose   

function Test-EnvironmentPatches
{
     param
     (
         [string] $Environment,
         [int]    $TestPatchCount = 0
     )

    InitDbPatches -Environment $Environment

    Get-ChildItem $rootFolderPath -recurse -Filter *.sql | Add-SqlDbPatches -ExecuteOnce -Verbose   

    Test-ForPatches -Description "Test Environment Patches for '$Environment'"  -TestPatchNames @(
        "BeforeOneTime\00_Initialize.($Environment).sql"
        'BeforeOneTime\01_SampleItems.sql'
        'BeforeOneTime\02_ScriptsRun.sql'
        'BeforeOneTime\03_ScriptsRunErrors.sql'
        'BeforeOneTime\04_Version.sql'
    )
}

# ------------------------------------

Test-EnvironmentPatches -Environment 'Dev' -TestPatchCount 5
Test-EnvironmentPatches -Environment 'Test' -TestPatchCount 5
Test-EnvironmentPatches -Environment 'Prod' -TestPatchCount 5


Get-ChildItem $rootFolderPath -recurse -Filter *.sql | Select-Object -First 5 | Add-SqlDbPatches -ExecuteOnce -Verbose   



<#
Initialize-PsDbDeploy -ServerName $TestSqlServer `
                      -DatabaseName $TestDatabase `
                      -RootFolderPath $rootFolderPath `
                      -OutFolderPath $outFolderPath `
                      #-Environment 'Dev' `
                      #-EchoSql `
                      #-DisplayCallStack

Get-ChildItem $rootFolderPath -recurse -Filter *.sql `
	| Add-SqlDbPatches -ExecuteOnce -Verbose   

Publish-Patches
#>
