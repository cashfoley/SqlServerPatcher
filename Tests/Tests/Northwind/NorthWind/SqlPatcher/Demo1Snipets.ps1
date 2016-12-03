Initialize-SqlServerPatcher `
  -ServerName '.' `
  -DatabaseName 'NorthwindLocal' `
  -OutFolderPath (Join-Path $PSScriptRoot 'Output') `
  -RootFolderPath (Join-Path $PSScriptRoot 'Patches') `
  -PatchFileInitializationScript  `
    {Get-ChildItem -recurse -Filter *.sql | Add-SqlDbPatches}

break;

explorer .

Get-SqlServerPatchInfo
# ShowPatchInfo is alias

Publish-SqlServerPatches 
# PublishPatches

Get-SqlServerPatchHistory 
# ShowPatchHistory

Get-SqlServerPatcherDbObjects
# ShowDbObjects

ShowDbObjects -Functions
ShowDbObjects -All

ShowPatchHistory
Undo-SqlServerPatches 4
# RollbackPatch
ShowDbObjects -Functions

ShowPatchHistory
ShowPatchHistory -ShowRollbacks

ShowPatchInfo

PublishPatches
ShowDbObjects -Functions

ShowPatchHistory

RollbackPatch 1
ShowDbObjects

ShowPatchInfo
PublishPatches -PatchName 010_InitialSchema\010_CreateTables.sql
ShowPatchInfo
ShowPatchHistory
ShowDbObjects

PublishPatches
ShowPatchHistory

RollbackPatch 14
ShowPatchInfo
ShowPatchInfo -PatchesToExecute

ShowPatchInfo -PatchesToExecute | Test-SqlServerRollback

# 1) Creates .dacpac of the Database before patch is executed
# 2) Executes Patch
# 3) Creates .dacpac after patch is executed
# 4) Executes Rollback
# 5) Compares current Database to dacpac from step 1
# 6) Rexecutes Patch (Step 2)
# 7) Compares current Database to dacpac from step 3

ShowPatchHistory
ShowPatchInfo

RollbackPatch 11
ShowPatchHistory
ShowPatchInfo

ShowPatchInfo -PatchesToExecute | Test-SqlServerRollback
ShowPatchHistory
ShowPatchInfo
ShowDbObjects

#############################################################################
#  
#  Tons More!
#  
#  Transaction Management so if a script fails you do not have a 
#      partially executed Patch
#
#  Environment specific Scripts
#      xxx_InitializeReplication.(Prod).sql
#
#  Token Replacement
#      Replaces tokens in scripts so you can have Environment Specific values
#
#  Execute When Script Changes (Does not support Rollbacks)
#  Execute Everytime Scripts   (Does not support Rollbacks)
#
#  Supports -WhatIf execution 
#      The Output Folder contains scripts that 'would have been' executed
#
#  Coming Soon
#     Available in Powershell Gallery
#     DSC component
#     Data Loading for Lookup Tables
#
