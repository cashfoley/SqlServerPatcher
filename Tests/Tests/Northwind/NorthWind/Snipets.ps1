Set-Location $PSScriptRoot
break;

.\Initialize-LocalDatabase.ps1
.\Initialize-Patches.ps1

.\Initialize-LocalDatabase.ps1 -DatabaseName NorthwindDev
.\Initialize-Patches.ps1 -DatabaseName NorthwindDev

Get-SqlServerPatchInfo

Publish-Patches

Get-SqlServerPatchHistory

Undo-SqlServerPatch 1

