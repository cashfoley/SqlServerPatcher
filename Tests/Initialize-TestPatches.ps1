
param
( [string] $Environment = ''
, [string] $TestSqlServer = '.'
, [string] $TestDatabase = 'ScriptTest'
, [switch] $Checkpoint
, [scriptblock] $PatchFileInitializationScript = {
                    Get-ChildItem -recurse -Filter *.sql | Add-SqlDbPatches
                }
)

Import-Module (Join-Path $PSScriptRoot '..\SqlServerPatcher') -Force


$outFolderPath  = Join-Path $PSScriptRoot 'TestOutput'
$rootFolderPath = Join-Path $PSScriptRoot 'Tests\SqlScripts'


Initialize-SqlServerPatcher -ServerName $TestSqlServer `
                            -DatabaseName $TestDatabase `
                            -RootFolderPath $rootFolderPath `
                            -OutFolderPath $outFolderPath `
                            -Environment $Environment `
                            -Checkpoint:$Checkpoint `
                            -PatchFileInitializationScript:$PatchFileInitializationScript

