.\Initialize-LocalDatabase.ps1
.\Initialize-Patches.ps1


$patches = Get-SqlServerPatchInfo | Where-Object{$_.ShouldExecute()}
$QueuedPatches.PatchContext.AssureSqlServerPatcher()
foreach ($Patchinfo in $Patches)
{
    Test-SqlServerRollback $Patchinfo.PatchName

    Write-Host 'Redo patch'
    Publish-SqlServerPatches -PatchName $Patchinfo.PatchName
}
