Set-Location $PSScriptRoot


.\Initialize-LocalDatabase.ps1 -DatabaseName NorthwindLocal

.\Initialize-Patches.ps1 -DatabaseName NorthwindLocal -Release '1.0.0'
PublishPatches -PatchName '010_InitialSchema\010_CreateTables.sql'

.\Initialize-Patches.ps1 -DatabaseName NorthwindLocal -Release '1.1.0'
PublishPatches -PatchName '010_InitialSchema\020_CreateViews.sql'
PublishPatches -PatchName '010_InitialSchema\030_CreateStoredProcedures.sql'

.\Initialize-Patches.ps1 -DatabaseName NorthwindLocal -Release '1.2.0'
PublishPatches -PatchName '010_InitialSchema\040_CreateFunctions.sql'

ShowPatchHistory | ft


RollbackPatch -ToRelease '1.1.0' 

ShowPatchHistory -ShowRollbacks

RollbackPatch -OID 4 -RollbackRollback

# Add logic to prevent new release of used release

<#
ShowPatchInfo

ShowDbObjects 

Get-SqlServerPatchInfo -PatchesToExecute | Test-SqlServerRollback

Undo-SqlServerPatches 




.\Initialize-Patches.ps1; help Initialize-SqlServerPatcher  -Detailed
#>

