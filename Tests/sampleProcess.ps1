Set-Location $PSScriptRoot
break

.\Initialize-TestDatabase.ps1

.\Initialize-TestPatches.ps1

PatchInfo

Publish-Patches

PatchHistory

RollbackPatch 5 -OnlyOne -Force

dir .\Tests\SqlScripts -Recurse

$QueuedPatches.PatchContext.DacPacUtil.ExtractDacPac('C:\Git\SqlServerPatcher\Tests\A.dacpac')
$QueuedPatches.PatchContext.DacPacUtil.GenerateXmlDeployReport('C:\Git\SqlServerPatcher\Tests\A.dacpac')