Set-Location $PSScriptRoot

$testFolder = $PSScriptRoot
#break

.\Initialize-TestDatabase.ps1

.\Initialize-TestPatches.ps1

Get-SqlServerPatchInfo

Publish-SqlServerPatches

Get-SqlServerPatchHistory

#break

$workDir = Join-Path $testFolder 'DacpacTemp'

if (Test-Path $workDir)
{
    Get-ChildItem $workDir -Recurse | Remove-Item -Force
}

New-Item $workDir -ItemType Directory

$PatchHistory = [system.collections.ArrayList]::new( (Get-SqlServerPatchHistory) )
$PatchHistory.Reverse()

foreach ($HistoryItem in $PatchHistory)
{
    $DacpacName = "{0}.{1}.dacpac" -f $QueuedPatches.PatchContext.DatabaseName,$HistoryItem.OID
    $DacpacFileName = Join-Path $workDir $DacpacName
    Write-Host "Creating Dacpac '$DacpacFileName'"
    Set-Dacpac $DacpacFileName
    $ExecutedRollback = Undo-SqlServerPatch $HistoryItem.OID -OnlyOne -Force
    Add-Member -InputObject $HistoryItem -NotePropertyName ExecutedRollback -NotePropertyValue $ExecutedRollback
}

$PatchHistory.Reverse()
foreach ($HistoryItem in $PatchHistory)
{
    $ExecutedRollback = Undo-SqlServerPatch $HistoryItem.ExecutedRollback.OID -OnlyOne -Force

    $DacpacName = "{0}.{1}.dacpac" -f $QueuedPatches.PatchContext.DatabaseName,$HistoryItem.OID
    $DacpacFileName = Join-Path $workDir $DacpacName
    Write-Host "Comparing Dacpac results after Rollback '$DacpacFileName'"
    $RollbackIssues = Get-DacpacActions $DacpacFileName
    if ($RollbackIssues)
    {
        Throw 'Houston, we have a problem here.'
    }
}


break
<#

RollbackPatch 4 -OnlyOne -Force

Set-Dacpac 'C:\Git\SqlServerPatcher\Tests\A.dacpac'

RollbackPatch 5 -OnlyOne -Force
RollbackPatch 2 -OnlyOne -Force

Get-DacpacActions 'C:\Git\SqlServerPatcher\Tests\A.dacpac'

#>
