﻿Set-Location $PSScriptRoot

Import-Module Pester

$TestSqlServer = '.'
$TestDatabase = 'ScriptTest'

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


##############################################################################################################################

function Test-EnvironmentPatches
{
     param([string] $Environment)

    .\Initialize-TestPatches.ps1 -Environment $Environment

    Test-ForPatches -Description "Test Environment Patches for '$Environment'"  -TestPatchNames @(
        "20_OneTime\00_Initialize.($Environment).sql"
        '20_OneTime\01_SampleItems.sql'
        '20_OneTime\02_ScriptsRun.sql'
        '20_OneTime\03_ScriptsRunErrors.sql'
        '20_OneTime\04_Version.sql'
    )
}

##############################################################################################################################

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2

##############################################################################################################################

$Connection = .\Initialize-TestDatabase $TestSqlServer

Test-EnvironmentPatches -Environment 'Dev' 
Test-EnvironmentPatches -Environment 'Test'
Test-EnvironmentPatches -Environment 'Prod'

##############################################################################################################################
#  Verfify Checkpoint 

# $Connection = .\Initialize-TestDatabase $TestSqlServer

.\Initialize-TestPatches.ps1 -Checkpoint

Test-ForPatches -TestPatchNames @(
    '20_OneTime\01_SampleItems.sql'
    '20_OneTime\02_ScriptsRun.sql'
    '20_OneTime\03_ScriptsRunErrors.sql'
    '20_OneTime\04_Version.sql'
)

Test-ForSqlObjects -TestDoesntExist -ObjectNames @('dbo.SampleItems','dbo.ScriptsRun','dbo.ScriptsRunErrors','dbo.Version') -Description 'Tables are not created'

Publish-SqlServerPatches

Test-ForSqlObjects -TestDoesntExist -ObjectNames @('dbo.SampleItems','dbo.ScriptsRun','dbo.ScriptsRunErrors','dbo.Version') -Description 'Tables are not created during Checkpoint'

.\Initialize-TestPatches.ps1 

Describe 'Verify No Patches to be run after Checkpoint' {
    It 'Should contain 0 Patches' {
        Get-ExecutablePatches | Should be $null
    }
}

Publish-SqlServerPatches

Test-ForSqlObjects -TestDoesntExist -ObjectNames @('dbo.SampleItems','dbo.ScriptsRun','dbo.ScriptsRunErrors','dbo.Version') -Description 'Tables are not created after Checkpoint'


##############################################################################################################################
#  Test Patches get executed

$Connection = .\Initialize-TestDatabase $TestSqlServer

.\Initialize-TestPatches.ps1 

Test-ForPatches -TestPatchNames @(
    '20_OneTime\01_SampleItems.sql'
    '20_OneTime\02_ScriptsRun.sql'
    '20_OneTime\03_ScriptsRunErrors.sql'
    '20_OneTime\04_Version.sql'
)

Test-ForSqlObjects -TestDoesntExist -ObjectNames @('dbo.SampleItems','dbo.ScriptsRun','dbo.ScriptsRunErrors','dbo.Version') -Description 'Tables are not created'

Publish-SqlServerPatches

Test-ForSqlObjects -ObjectNames @('dbo.SampleItems','dbo.ScriptsRun','dbo.ScriptsRunErrors','dbo.Version') -Description 'Tables got created'

# ------------------------------------

.\Initialize-TestPatches.ps1

Describe 'Verify No Patches to be run after publish' {
    It 'Should contain 0 Patches' {
        (Get-ExecutablePatches) | Should be $null
    }
}

Publish-SqlServerPatches
.\Initialize-TestPatches.ps1

##############################################################################################################################


# TODO:  Close SQL Connection after every command

