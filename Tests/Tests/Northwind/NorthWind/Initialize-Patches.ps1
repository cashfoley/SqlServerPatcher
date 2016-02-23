
param
( [string] $Environment = ''
, [string] $TestSqlServer = '.'
, [string] $TestDatabase = 'NorthwindLocal'
, [switch] $Checkpoint
, [scriptblock] $PatchFileInitializationScript = {
                    Get-ChildItem -recurse -Filter *.sql | Add-SqlDbPatches
                }
)

$SqlServerPatcherModule = Join-Path $PSScriptRoot '..\..\..\..\SqlServerPatcher'
Import-Module $SqlServerPatcherModule -Force


$outFolderPath  = Join-Path $PSScriptRoot 'bin\TestOutput'
$rootFolderPath = Join-Path $PSScriptRoot 'Patches'


Initialize-SqlServerPatcher -ServerName $TestSqlServer `
                            -DatabaseName $TestDatabase `
                            -RootFolderPath $rootFolderPath `
                            -OutFolderPath $outFolderPath `
                            -Environment $Environment `
                            -Checkpoint:$Checkpoint `
                            -PatchFileInitializationScript:$PatchFileInitializationScript

