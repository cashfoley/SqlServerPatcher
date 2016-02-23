Set-Location $PSScriptRoot
break;

.\Initialize-LocalDatabase.ps1
.\Initialize-LocalDatabase.ps1 -DatabaseName NorthwindDev

.\Initialize-Patches.ps1
.\Initialize-Patches.ps1 -DatabaseName NorthwindDev

PatchInfo

Publish-Patches

PatchHistory

RollbackPatch 2

PatchHistory

