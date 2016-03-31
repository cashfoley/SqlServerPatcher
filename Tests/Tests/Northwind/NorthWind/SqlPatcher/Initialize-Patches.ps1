
param
( [string] $Environment = ''
, [string] $ServerName = '.'
, [string] $DatabaseName = 'NorthwindLocal'
, [switch] $Checkpoint
, [scriptblock] $PatchFileInitializationScript = {
                    Get-ChildItem -recurse -Filter *.sql | Add-SqlDbPatches
                }
)

$ErrorActionPreference = 'Stop'

### Find root Folder
$RootFolder = $PSScriptRoot
while (!(Test-Path (Join-Path $RootFolder 'Readme.md')))
{
    $RootFolder = split-Path $RootFolder 
}

$MicrosoftSqlDbDac = Join-Path $RootFolder '..\Microsoft.SqlDb.DAC.12' -Resolve
Import-Module $MicrosoftSqlDbDac -Force 


$SqlServerPatcherModule = Join-Path $RootFolder 'SqlServerPatcher'
Import-Module $SqlServerPatcherModule -Force 

$outFolderPath  = Join-Path $PSScriptRoot '..\bin\TestOutput'
$rootFolderPath = Join-Path $PSScriptRoot 'Patches'


Initialize-SqlServerPatcher -ServerName $ServerName `
                            -DatabaseName $DatabaseName `
                            -RootFolderPath $rootFolderPath `
                            -OutFolderPath $outFolderPath `
                            -Environment $Environment `
                            -Checkpoint:$Checkpoint `
                            -PatchFileInitializationScript:$PatchFileInitializationScript

