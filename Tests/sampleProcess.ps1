Set-Location $PSScriptRoot
#break

.\Initialize-TestDatabase.ps1

.\Initialize-TestPatches.ps1

PatchInfo

Publish-Patches

PatchHistory

RollbackPatch 4 -OnlyOne -Force

# dir .\Tests\SqlScripts -Recurse

$QueuedPatches.PatchContext.DacPacUtil.ExtractDacPac('C:\Git\SqlServerPatcher\Tests\A.dacpac')

RollbackPatch 5 -OnlyOne -Force
RollbackPatch 2 -OnlyOne -Force

$DeployReportXml = $QueuedPatches.PatchContext.DacPacUtil.GetDeploymentActions('C:\Git\SqlServerPatcher\Tests\A.dacpac')
<#
$DeployReportXml
$DeployReportDoc = [xml]$DeployReportXml

$DeployReportDoc.DeploymentReport.Alerts
$DeployReportDoc.DeploymentReport.Operations.Operation
$DeployReportDoc.DeploymentReport.Operations.Operation[1].FirstChild.Type
#>
