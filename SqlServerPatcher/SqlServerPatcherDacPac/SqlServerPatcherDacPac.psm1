
$DacSvcs
$DacProfile
$Connection

function Get-SqlServerMajoreVersion
{
     param
     (
         [string] $sqlServerVersion
     )

    switch($sqlserverVersion)
    {
        '2008-R2'
        {
            $majorVersion = 100
        }
        '2012'
        {
            $majorVersion = 110
        }
        '2014'
        {
            $majorVersion = 120
        }
    }

    return $majorVersion
}
function Initialize-SqlServerPatcherDacPac
{
     param
     (
        [Object] $Connection,

        [Parameter(Mandatory=$True,ParameterSetName='ByVersion')]
        [String]$sqlserverVersion,

        [Parameter(Mandatory=$True,ParameterSetName='ByPath')]
        [String]$sqlServerDacDllPath
    )

    if ($sqlserverVersion -ne '')
    {
        $majorVersion = Get-SqlServerMajoreVersion -sqlServerVersion $sqlserverVersion
        $sqlServerDacDllPath = "${env:ProgramFiles(x86)}\Microsoft SQL Server\$majorVersion\DAC\bin\Microsoft.SqlServer.Dac.dll"
    }

    try
    {  
        [System.Reflection.Assembly]::LoadFrom($sqlServerDacDllPath) | Out-Null
    }
    catch
    {
        Throw "Loading DacDll Failed - '$sqlServerDacDllPath'"
    }

    $Script:Connection = $Connection

    $script:DacSvcs = [Microsoft.SqlServer.Dac.DacServices]::new($Connection.ConnectionString)
        
    $script:DacProfile = [Microsoft.SqlServer.Dac.DacDeployOptions]::new()
    $script:DacProfile.BlockOnPossibleDataLoss = $false
    $script:DacProfile.DropObjectsNotInSource = $true
}

function Get-DacPac
{
     param
     (
         [string]$DacpacFilename
     )

    $script:DacSvcs.Extract($DacpacFilename, $Script:Connection.Database, $Script:Connection.Database, '0.0.0.0', 'Extracted DacPac', $null, $null, $null) 
}

function Get-XmlDeployReport
{
     param
     (
         [string] $TargetDacPacFile
     )

    $DacPac = [Microsoft.SqlServer.Dac.DacPackage]::Load($TargetDacPacFile) 

    return $script:DacSvcs.GenerateDeployReport($DacPac, $Script:Connection.Database, $script:DacProfile, $null) 
}

function Get-DacPacDeploymentActions
{
     param
     (
         [Object]
         $TargetDacPacFile
     )

    $results = @()
    [xml]$DeploymentDoc = Get-XmlDeployReport $TargetDacPacFile

    foreach ($operation in $DeploymentDoc.DeploymentReport.Operations.Operation) 
    {
        $ActionName = $operation.Name
        foreach ($operationItem in $operation.ChildNodes)
        {
            $ActionObject = $operationItem.Value
            $ActionObjectType = $operationItem.Type
            $Action = [PSCustomObject]@{Action=$ActionName; ObjectType=$ActionObjectType; ObjectName=$ActionObject}
            $results += $Action
        }
    }
    return $results
}

function Get-DacpacActions
{
    param
    (
        [string] $DacpacFilename
      , [switch] $GetXmlReport
    )

    if ($GetXmlReport)
    {
        return Get-XmlDeployReport $DacpacFilename
    }
    else
    {
        return Get-DacPacDeploymentActions $DacpacFilename
    } 
}

Export-ModuleMember -Function * 


# function Construct-ConnectionString([string]$sqlServer, [System.Management.Automation.PSCredential]$credentials)
# {
#     $uid = $credentials.UserName
#     $pwd = $credentials.GetNetworkCredential().Password
#     $server = "Server=$sqlServer;"
# 
#     if($PSBoundParameters.ContainsKey('credentials'))
#     {
#         $integratedSecurity = "Integrated Security=False;"
#         $userName = "uid=$uid;pwd=$pwd;"
#     }
#     else
#     {
#         $integratedSecurity = "Integrated Security=SSPI;"
#     }
# 
#     $connectionString = "$server$userName$integratedSecurity"
# 
#     return $connectionString
# }



