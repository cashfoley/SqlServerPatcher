################################################################################################################
################################################################################################################
################################################################################################################
class DacPacUtil
{
    [PatchContext]$PatchContext
    [Microsoft.SqlServer.Dac.DacServices]$DacSvcs
    [Microsoft.SqlServer.Dac.DacDeployOptions]$DacProfile

    DacPacUtil($patchContext)
    {
        #$connectionString = 'Data Source={0}; Initial Catalog={1}; Integrated Security=True;MultipleActiveResultSets=False;Application Name="SQL Management"' -f $TestSqlServer,$TestDatabase

        $this.PatchContext = $patchContext

        $this.DacSvcs = new-object Microsoft.SqlServer.Dac.DacServices $this.PatchContext.Connection.ConnectionString
        $this.DacProfile =[Microsoft.SqlServer.Dac.DacDeployOptions]::new()
    }

    [void] ExtractDacPac($TargetDacPacFile)
    {
        $this.DacSvcs.Extract($TargetDacPacFile, $this.PatchContext.Connection.Database, $this.PatchContext.Connection.Database, '0.0.0.0', 'Extracted DacPac', $null, $null, $null) 
    }

    [string] GenerateXmlDeployReport($TargetDacPacFile)
    {
        $DacPac = [Microsoft.SqlServer.Dac.DacPackage]::Load($TargetDacPacFile) 

        return $this.DacSvcs.GenerateDeployReport($DacPac, $this.PatchContext.Connection.Database, $this.DacProfile, $null) 
    }
}

function DacPacUtilFactory($patchContext)
{
    [DacPacUtil]::new($patchContext)
}

Export-ModuleMember -Function DacPacUtilFactory
