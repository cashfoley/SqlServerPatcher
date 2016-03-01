Set-Location $PSScriptRoot

$testFolder = $PSScriptRoot
#break

.\Initialize-TestDatabase.ps1

.\Initialize-TestPatches.ps1

PatchInfo

Publish-Patches

PatchHistory

break

$workDir = Join-Path $testFolder 'DacpacTemp'

if (Test-Path $workDir)
{
    Get-ChildItem $workDir -Recurse | Remove-Item -Force
}

New-Item $workDir -ItemType Directory

$PatchHistory = [system.collections.ArrayList]::new( (PatchHistory) )
$PatchHistory.Reverse()

foreach ($HistoryItem in $PatchHistory)
{
    $DacpacName = "{0}.{1}.dacpac" -f $QueuedPatches.PatchContext.DatabaseName,$HistoryItem.OID
    $DacpacFileName = Join-Path $workDir $DacpacName
    Write-Host "Creating Dacpac '$DacpacFileName'"
    Set-Dacpac $DacpacFileName
    RollbackPatch $HistoryItem.OID -OnlyOne -Force
}

break

RollbackPatch 4 -OnlyOne -Force

Set-Dacpac 'C:\Git\SqlServerPatcher\Tests\A.dacpac'

RollbackPatch 5 -OnlyOne -Force
RollbackPatch 2 -OnlyOne -Force

Get-DacpacActions 'C:\Git\SqlServerPatcher\Tests\A.dacpac'

