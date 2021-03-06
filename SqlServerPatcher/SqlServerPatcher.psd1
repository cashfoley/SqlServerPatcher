@{
ModuleVersion = '0.1.1'
GUID = '80d8761c-a785-4d2f-aec8-421236afd257'
Author = 'Cash Foley'
CompanyName = 'Cash Foley Software Consultant LLC'
Copyright = '(c) 2016 Cash Foley. All rights reserved.'
Description = @'
SqlServerPatcher provides a set of cmdlets for publishing database patches to Sql Server.  
It supports Rollback scripts and verifications with SSDT.  It is desinged to work with
Visual Studio Database Projects.
'@
PowerShellVersion = '5.0'
#Tags = @('DevOps', 'Sql Server', 'Deployment', 'Database')
#ProjectUri = 'https://github.com/cashfoley/SqlServerPatcher'

RootModule = 'SqlServerPatcher.psm1'
ScriptsToProcess = @('LoadDllLibraries.ps1')
FormatsToProcess = @('SqlServerPatcherViews.ps1xml')

FunctionsToExport = '*'
CmdletsToExport = '*'
VariablesToExport = '*'
AliasesToExport = '*'

}

