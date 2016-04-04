Set-Location $PSScriptRoot
break;

.\Initialize-LocalDatabase.ps1 -DatabaseName NorthwindLocal
.\Initialize-LocalDatabase.ps1 -DatabaseName NorthwindDev


.\Initialize-Patches.ps1 -DatabaseName NorthwindLocal
.\Initialize-Patches.ps1 -DatabaseName NorthwindDev

ShowPatchInfo

ShowDbObjects 

PublishPatches

ShowPatchHistory


Get-SqlServerPatchInfo -PatchesToExecute | Test-SqlServerRollback

Undo-SqlServerPatches 




.\Initialize-Patches.ps1; help Initialize-SqlServerPatcher  -Detailed

