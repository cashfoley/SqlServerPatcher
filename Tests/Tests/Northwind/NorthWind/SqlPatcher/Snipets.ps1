Set-Location $PSScriptRoot
break;

.\Initialize-LocalDatabase.ps1
.\Initialize-Patches.ps1

.\Initialize-LocalDatabase.ps1 -DatabaseName NorthwindDev
.\Initialize-Patches.ps1 -DatabaseName NorthwindDev

Get-SqlServerPatchInfo

Publish-SqlServerPatches

Get-SqlServerPatchHistory


Get-SqlServerPatchInfo -PatchesToExecute | Test-SqlServerRollback

Undo-SqlServerPatches 1

Undo-SqlServerPatches 2

.\Initialize-Patches.ps1; help Initialize-SqlServerPatcher  -Detailed

#foreach ($HistoryItem in $PatchHistory)
#{
#    $DacpacName = "{0}.{1}.dacpac" -f $QueuedPatches.PatchContext.DatabaseName,$HistoryItem.OID
#    $DacpacFileName = Join-Path $workDir $DacpacName
#    Write-Host "Creating Dacpac '$DacpacFileName'"
#    Set-Dacpac $DacpacFileName
#    $ExecutedRollback = Undo-SqlServerPatch $HistoryItem.OID -OnlyOne -Force
#    Add-Member -InputObject $HistoryItem -NotePropertyName ExecutedRollback -NotePropertyValue $ExecutedRollback
#}
#
#$PatchHistory.Reverse()
#foreach ($HistoryItem in $PatchHistory)
#{
#    $ExecutedRollback = Undo-SqlServerPatch $HistoryItem.ExecutedRollback.OID -OnlyOne -Force
#
#    $DacpacName = "{0}.{1}.dacpac" -f $QueuedPatches.PatchContext.DatabaseName,$HistoryItem.OID
#    $DacpacFileName = Join-Path $workDir $DacpacName
#    Write-Host "Comparing Dacpac results after Rollback '$DacpacFileName'"
#    $RollbackIssues = Get-DacpacActions $DacpacFileName
#    if ($RollbackIssues)
#    {
#        Throw 'Houston, we have a problem here.'
#    }
#}
