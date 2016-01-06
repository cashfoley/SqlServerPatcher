# SqlServerPatcher

This PowerShell Module contains CmdLets for execting SQL Patches with Microsoft SQL Server

With SqlServerPatcher you can easily manage pipeline deployments of Sql Patches through multiple environments.

For example, if you have a directory where you put scripts that should only be executed once in each environment, you create a folder
for containing them, and put the '.sql' files in the folder.  They will be executed alphabetically so the easiest way to manage 
order is to put numbers in front of each Patch File.

- PatchFolder
  - 01_InitialSchema.sql
  - 02_CreateIndexes.sql

To deploy these scripts to a local server in a database named _TestDB_, you would execute the following code.

```powershell
Import-Module SqlServerPatcher

$rootFolder = Join-Path $PSScriptRoot 'PatchFolder'
Initialize-SqlServerSafePatch -ServerName '.' -DatabaseName 'TestDB' -RootFolderPath $rootFolderPath

Get-ChildItem $rootFolderPath -recurse -Filter *.sql | Add-SqlServerPatch 

Publish-Patches
```

The first time you execute the script, it would execute both files.  If you were to execute it again, they would not be executed.

If you were to add another file '03_AddColumnToMasterTable.sql' then the next time you performed the script it would execute just the 
third script.

If you were to configure another Database, it would execute all three scripts.

## Major Features

1. Execute scripts once in an environment.
2. Execute scripts everytime they change.  This is great for Stored Procedures and Views.
3. Execute scripts everytime you have deployments.
3. Environment Specific Scripts.
4. Token Replacement in scripts.
5. WhatIf Deployments shows scripts that need to be performed.

As a native PowerShell module, it works intuitively with your PowerShell deployment scripts.  It does not have complicated configuration files and hardcoded rules and folders.  By simply piping filesystem items into Add-SqlServerPatch, you control the order of patches and the actions associated with them.




