.\Initialize-LocalDatabase.ps1
.\Initialize-Patches.ps1


$patches = Get-SqlServerPatchInfo -PatchesToExecute
$patches | Test-SqlServerRollback -ApplyPatchOnSuccess

PatchHistory

RollbackPatch 12

PatchInfo

$patches = Get-SqlServerPatchInfo -PatchesToExecute
$patches | Test-SqlServerRollback -ApplyPatchOnSuccess
