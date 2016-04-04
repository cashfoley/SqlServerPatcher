
param
( [string] $Environment = ''
, [string] $ServerName = '.'
, [string] $DatabaseName = 'NorthwindLocal'
, [scriptblock] $PatchFileInitializationScript = {
                    Get-ChildItem -recurse -Filter *.sql | Add-SqlDbPatches 
                }
)

$ErrorActionPreference = 'Stop'

#region Find Module Root Folder
### Find root Folder
$ModuleRoot = $PSScriptRoot
while (!(Test-Path (Join-Path $ModuleRoot 'Readme.md')))
{
    $ModuleRoot = split-Path $ModuleRoot 
}
#endregion

$MicrosoftSqlDbDac = Join-Path $ModuleRoot '..\Microsoft.SqlDb.DAC.12' -Resolve
Import-Module $MicrosoftSqlDbDac -Force 

$SqlServerPatcherModule = Join-Path $ModuleRoot 'SqlServerPatcher'
Import-Module $SqlServerPatcherModule -Force 

Initialize-SqlServerPatcher -ServerName $ServerName `
                            -DatabaseName $DatabaseName `
                            -RootFolderPath (Join-Path $PSScriptRoot 'Patches') `
                            -OutFolderPath (Join-Path $PSScriptRoot '..\bin\TestOutput') `
                            -Environment $Environment `
                            -PatchFileInitializationScript:$PatchFileInitializationScript

