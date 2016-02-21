Set-Location $PSScriptRoot

Import-Module Pester
Import-Module (Join-Path $PSScriptRoot '..\SqlServerPatcher') -Force


#cls
function Test-ForPatches
{
     param
     (
         [Array] $TestPatchNames,

         [switch] $PartialList,

         [string] $Description='Verify Patches Included'
     )

    $PatchNames = (Get-ExecutablePatches) | %{$_.PatchName}
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

function Test-ForSqlObjects
{
     param
     (
         [Array] $ObjectNames,
         [string] $objectType = 'U',
         [switch] $TestDoesntExist,

         [string] $Description='Verify Sql Objects'
     )
    $ObjectIdForObjectSql = "SELECT OBJECT_ID(N'{0}', N'{1}')"

    $SqlCmd = $Connection.CreateCommand()
    $SqlCmd.CommandType = [System.Data.CommandType]::Text

    if ($TestDoesntExist)
    {
        $TestMessage = 'Verify {0} does not exist'
    }
    else
    {
        $TestMessage = 'Verify {0} exists'
    }

    Describe $Description {
        foreach ($ObjectName in $ObjectNames)
        {
            $SqlCmd.CommandText = ($ObjectIdForObjectSql -f $objectName,$objectType)
            $ObjectId = $SqlCmd.ExecuteScalar()
            $ObjectDoesNotExist = $ObjectId -is [System.DBNull]
            It ($TestMessage -f $ObjectName) {
                $ObjectDoesNotExist | Should be $TestDoesntExist
            }
        }
    }
}

function InitDbPatches
{
     param
     (
         [string] $Environment = ''
       , [switch] $Checkpoint
     )

    Initialize-SqlSafePatch -ServerName $TestSqlServer `
                          -DatabaseName $TestDatabase `
                          -RootFolderPath $rootFolderPath `
                          -OutFolderPath $outFolderPath `
                          -Environment $Environment `
                          -Checkpoint:$Checkpoint
}


##############################################################################################################################

function Test-EnvironmentPatches
{
     param([string] $Environment)


    InitDbPatches -Environment $Environment

    Get-ChildItem $rootFolderPath -recurse -Filter *.sql | Add-SqlDbPatches #-Verbose   

    Test-ForPatches -Description "Test Environment Patches for '$Environment'"  -TestPatchNames @(
        "BeforeOneTime\00_Initialize.($Environment).sql"
        'BeforeOneTime\01_SampleItems.sql'
        'BeforeOneTime\02_ScriptsRun.sql'
        'BeforeOneTime\03_ScriptsRunErrors.sql'
        'BeforeOneTime\04_Version.sql'
    )
}

##############################################################################################################################

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

$outFolderPath = Join-Path $PSScriptRoot 'TestOutput'
$rootFolderPath = Join-Path $PSScriptRoot 'Tests\SqlScripts'

##############################################################################################################################

$Connection = .\Initialize-TestDatabase $TestSqlServer

Test-EnvironmentPatches -Environment 'Dev' 
Test-EnvironmentPatches -Environment 'Test'
Test-EnvironmentPatches -Environment 'Prod'

##############################################################################################################################
#  Verfify Checkpoint 

# $Connection = .\Initialize-TestDatabase $TestSqlServer

InitDbPatches -Checkpoint

Get-ChildItem $rootFolderPath -recurse -Filter *.sql | Add-SqlDbPatches #-Verbose   

# Attempt to add Patches again.  should be ignored
Get-ChildItem $rootFolderPath -recurse -Filter *.sql | Add-SqlDbPatches #-Verbose   

Test-ForPatches -TestPatchNames @(
    'BeforeOneTime\01_SampleItems.sql'
    'BeforeOneTime\02_ScriptsRun.sql'
    'BeforeOneTime\03_ScriptsRunErrors.sql'
    'BeforeOneTime\04_Version.sql'
)

Test-ForSqlObjects -TestDoesntExist -ObjectNames @('dbo.SampleItems','dbo.ScriptsRun','dbo.ScriptsRunErrors','dbo.Version') -Description 'Tables are not created'

Publish-Patches

Test-ForSqlObjects -TestDoesntExist -ObjectNames @('dbo.SampleItems','dbo.ScriptsRun','dbo.ScriptsRunErrors','dbo.Version') -Description 'Tables are not created during Checkpoint'

InitDbPatches 

Get-ChildItem $rootFolderPath -recurse -Filter *.sql | Add-SqlDbPatches #-Verbose   

Describe 'Verify No Patches to be run after Checkpoint' {
    It 'Should contain 0 Patches' {
        Get-ExecutablePatches | Should be $null
    }
}

Publish-Patches

Test-ForSqlObjects -TestDoesntExist -ObjectNames @('dbo.SampleItems','dbo.ScriptsRun','dbo.ScriptsRunErrors','dbo.Version') -Description 'Tables are not created after Checkpoint'


##############################################################################################################################
#  Test Patches get executed

$Connection = .\Initialize-TestDatabase $TestSqlServer

InitDbPatches 

Get-ChildItem $rootFolderPath -recurse -Filter *.sql | Add-SqlDbPatches #-Verbose   

Test-ForPatches -TestPatchNames @(
    'BeforeOneTime\01_SampleItems.sql'
    'BeforeOneTime\02_ScriptsRun.sql'
    'BeforeOneTime\03_ScriptsRunErrors.sql'
    'BeforeOneTime\04_Version.sql'
)

Test-ForSqlObjects -TestDoesntExist -ObjectNames @('dbo.SampleItems','dbo.ScriptsRun','dbo.ScriptsRunErrors','dbo.Version') -Description 'Tables are not created'

Publish-Patches

Test-ForSqlObjects -ObjectNames @('dbo.SampleItems','dbo.ScriptsRun','dbo.ScriptsRunErrors','dbo.Version') -Description 'Tables got created'

# ------------------------------------

InitDbPatches
Get-ChildItem $rootFolderPath -recurse -Filter *.sql | Add-SqlDbPatches 

Describe 'Verify No Patches to be run after publish' {
    It 'Should contain 0 Patches' {
        (Get-ExecutablePatches) | Should be $null
    }
}

Publish-Patches
InitDbPatches

Get-ChildItem $rootFolderPath -recurse -Filter *.sql | Add-SqlDbPatches -Force

Test-ForPatches -TestPatchNames @(
    'BeforeOneTime\01_SampleItems.sql'
    'BeforeOneTime\02_ScriptsRun.sql'
    'BeforeOneTime\03_ScriptsRunErrors.sql'
    'BeforeOneTime\04_Version.sql'
)

#InitDbPatches

##############################################################################################################################


