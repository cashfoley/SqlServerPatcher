.\Initialize-LocalDatabase.ps1
.\Initialize-Patches.ps1


$patches = Get-SqlServerPatchInfo -PatchesToExecute
$patches | Test-SqlServerRollback 

#PatchHistory

[void](RollbackPatch 12)

# PatchInfo

