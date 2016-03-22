#region License

$LicenseMessage = @"
SqlServerPatcher - Powershell Database Deployment for SQL Server Database Updates with coordinated Software releases. 
Copyright (C) 2013-16 Cash Foley Software Consulting LLC
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 https://SqlServerPatcher.codeplex.com/license
"@
#endregion


################################################################################################################
################################################################################################################
################################################################################################################
class PatchInfo
{
    [PatchContext]       $PatchContext
    [System.IO.FileInfo] $PatchFile
    [string]             $PatchName
    [string]             $CheckSum
    [string]             $DatabaseCheckSum
    [string]             $PatchContent    = ''
    [string]             $RollbackContent = ''
    [bool]               $Force
    [bool]               $ReExecuteOnChange
    [bool]               $Executed

    $PatchAttributes = @{}

    # ----------------------------------------------------------------------------------

    PatchInfo ([PatchContext]$PatchContext,[System.IO.FileInfo]$PatchFile,$Force,$ReExecuteOnChange)
    {
        $this.PatchContext = $PatchContext
        $this.PatchFile = $PatchFile
        $this.PatchAttributes = @{}

        $fullname = $Patchfile.FullName
        if (! $fullname.StartsWith($this.PatchContext.RootFolderPath))
        {
            Throw ("Patchfile '{0}' not under RootFolder '{1}'" -f $PatchFile,$this.RootFolderPath)
        }
        
        $RootPatchName = $fullName.Replace($this.PatchContext.RootFolderPath, '')

        if ($RootPatchName -notmatch '(?<name>.*?)(?<r>.rollback)?.sql')
        {
            Throw ("Invalid Patch Name '{0'}" -f $RootPatchName)
        }

        $this.PatchName = $Matches['name'] + '.sql'
        if ($Matches['r'] -eq '.rollback')
        {
            $this.RollbackContent = $this.PatchContext.TokenList.ReplaceTokens((Get-Content $this.PatchFile | Out-String))
        }
        else
        {
            $this.Force = $Force
            $this.ReExecuteOnChange = $ReExecuteOnChange

            $this.CheckSum = $This.GetFileChecksum($PatchFile)
            $this.DatabaseCheckSum = [string]($this.PatchContext.GetChecksumForPatch($this.PatchName))

            $this.PatchContent = $this.PatchContext.TokenList.ReplaceTokens((Get-Content $this.PatchFile | Out-String))
        }

     }

    # ----------------------------------------------------------------------------------

    [string] GetPatchScript()
    {
        $PatchScript = ($this.GoScript($this.PatchContext.SqlConstants.BeginTransctionScript)) + 
                       ($this.GoScript($this.PatchContent)) + 
                       ($this.GoScript($this.PatchContext.GetInsertFilePatchString($this.PatchName, $this.Checksum, $this.PatchContent, $this.RollbackContent,''))) +
                       ($this.GoScript($this.PatchContext.SqlConstants.EndTransactionScript))
        
        return $PatchScript
    }

    # ----------------------------------------------------------------------------------
    
    [void] MergePatch([PatchInfo]$NewPatch)
    {
        if ($NewPatch.RollbackContent -ne '')
        {
            $this.RollbackContent = $NewPatch.RollbackContent
        }
            
        if ($NewPatch.PatchContent -ne '')
        {
            $this.Force             = $NewPatch.Force
            $this.ReExecuteOnChange = $NewPatch.ReExecuteOnChange
            $this.CheckSum          = $NewPatch.CheckSum
            $this.DatabaseCheckSum  = $NewPatch.DatabaseCheckSum
            $this.PatchContent      = $NewPatch.PatchContent
            $this.PatchName         = $NewPatch.PatchName
            $this.PatchFile         = $NewPatch.PatchFile
        }
    }
    
    # ----------------------------------------------------------------------------------
    [string] GetFileChecksum ([System.IO.FileInfo] $fileInfo)
    {
        $ShaProvider = (New-Object 'System.Security.Cryptography.SHA256CryptoServiceProvider')
        $file = New-Object 'system.io.FileStream' ($fileInfo, [system.io.filemode]::Open, [system.IO.FileAccess]::Read)
        try
        {
            $shaHash = [system.Convert]::ToBase64String($ShaProvider.ComputeHash($file))  
            #  To Do - combine read file with compute checksum
            return '{0} {1:d7}' -f $shaHash,$fileInfo.Length
        }
        finally 
        {
            $file.Close()
        }
    }

    hidden [string] GoScript([string]$script)
    {
        if ($script)
        {
            return ($script + "`nGO`n")
        }
        else
        {
            return ''
        }
    }

    hidden [void] SetPatchContent()
    {
    }

     [bool] ShouldExecute()
     {
        if (! ($this.PatchContext.TestEnvironment($this.PatchName) ) )
        {
            # Write-Verbose "`$($this.PatchName) ignored because it is the wrong target environment"
            return $false
        }

        if ($this.Force)
        {
            return $true
        }
        
        if ($this.Checksum -ne $this.DatabaseCheckSum)
        {
            if (!$this.ReExecuteOnChange -and ($this.DatabaseCheckSum -ne '') -and !$this.Executed)
            {
                #Write-Warning "Patch $($this.PatchName) has changed but will be ignored"
                return $false
            }
            else
            {
                return $true
            }
        }
        else
        {
            #Write-Verbose "Patch $($this.PatchName) current" 
            return $false
        }
    }
}

################################################################################################################
################################################################################################################
################################################################################################################

class ExecutedPatch
{
    [int]      $OID
    [string]   $PatchName
    [datetime] $Applied
    [string]   $RollbackStatus
    [bool]     $ExecutedByForce
    [bool]     $UpdatedOnChange
    [bool]     $IsRollback
    [int]      $RollbackedByOID
    [string]   $CheckSum
    [string]   $PatchScript
    [string]   $RollbackScript
    [string]   $RollbackChecksum
    [string]   $LogOutput

    ExecutedPatch(
          [int]      $OID
        , [string]   $PatchName
        , [datetime] $Applied
        , [bool]     $ExecutedByForce
        , [bool]     $UpdatedOnChange
        , [bool]     $IsRollback
        , [int]      $RollbackedByOID
        , [string]   $CheckSum
        , [string]   $PatchScript
        , [string]   $RollbackScript
        , [string]   $RollbackChecksum
        , [string]   $LogOutput
        )
    {

        $this.OID               = $OID
        $this.PatchName         = $PatchName
        $this.Applied           = $Applied
        $this.ExecutedByForce   = $ExecutedByForce
        $this.UpdatedOnChange   = $UpdatedOnChange
        $this.IsRollback        = $IsRollback
        $this.RollbackedByOID   = $RollbackedByOID
        $this.CheckSum          = $CheckSum
        $this.PatchScript       = $PatchScript
        $this.RollbackScript    = $RollbackScript
        $this.RollbackChecksum  = $RollbackChecksum
        $this.LogOutput         = $LogOutput

        $this.RollbackStatus = 'Not Available'
        if ($this.RollbackScript)
        {
            $this.RollbackStatus = 'Available'
        }
    }

}

###############################################################################################################
################################################################################################################
################################################################################################################

class TokenList
{
    hidden [array] $Tokens
    
    [string] ReplaceTokens([string]$str)
    {
        foreach ($Token in $this.Tokens)
        {
            $str = $str.Replace($Token.TokenValue,$Token.ReplacementValue)
        }
        return $str
    }

    [void] AddTokenPair([string]$TokenValue,[string]$ReplacementValue)
    {
        $this.Tokens += @{
            TokenValue       = $TokenValue
            ReplacementValue = $ReplacementValue
            }
    }
}

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
        $this.PatchContext = $patchContext

        $this.DacSvcs = new-object Microsoft.SqlServer.Dac.DacServices $this.PatchContext.Connection.ConnectionString
        
        $this.DacProfile =[Microsoft.SqlServer.Dac.DacDeployOptions]::new()
        $this.DacProfile.BlockOnPossibleDataLoss = $false
        $this.DacProfile.DropObjectsNotInSource = $true
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

    [psobject[]] GetDeploymentActions($TargetDacPacFile)
    {
        $results = @()
        [xml]$DeploymentDoc = ([xml]$this.GenerateXmlDeployReport($TargetDacPacFile))
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
}

function Set-Dacpac
{
    param
    (
        [string] $DacpacFilename
    )

    $PatchContext.DacPacUtil.ExtractDacPac($DacpacFilename)
}

Export-ModuleMember -Function Set-Dacpac

function Get-DacpacActions
{
    param
    (
        [string] $DacpacFilename
      , [switch] $GetXmlReport
    )

    if ($GetXmlReport)
    {
        return $PatchContext.DacPacUtil.GenerateXmlDeployReport($DacpacFilename)
    }
    else
    {
        return $PatchContext.DacPacUtil.GetDeploymentActions($DacpacFilename)
    } 
}

Export-ModuleMember -Function Get-DacpacActions

################################################################################################################
################################################################################################################
################################################################################################################

Class PatchContext
{
    [TokenList] $TokenList

    [bool]      $DisplayCallStack
    [hashtable] $SqlConstants

    $OutPatchCount = 0
    
    $ThisSqlServerPatcherVersion = 1

    [switch] $LogSqlOutScreen = $false
    [string] $SqlLogFile = $null
    [switch] $PublishWhatif = $false
    [string] $Environment = $null
    [scriptblock] $PatchFileInitializationScript

    # Cannot declare a [DacPacUtil] type because it cannot be instanciated until
    # the Microsoft.SqlServer.Dac.dll
    # this initialization will load the dll before executing the Import-Module
    # with the DacPacUtil class.
    $DacPacUtil

    hidden [string] $QueriesRegexOptions = 'IgnorePatternWhitespace,Singleline,IgnoreCase,Multiline,Compiled'
    #hidden [string] $QueriesExpression = "((?'Query'(?:(?:/\*.*?\*/)|.)*?)(?:^\s*go\s*$))*(?'Query'.*)"
    hidden [string] $QueriesExpression = @"
(
 (?'Query'                     # Beginning of Query
 ( 
   (--.*?$)                            
  |(/\*.*?\*/)                 # Scan for /* comments */ - Ignores GO lines in comments
  |('                          # OR - Beginning of a string quote 
    (?>                        # Begin Atomic Group
     (?>''|[^']+)+)            # Another Atomic Group.  Matches a '' or any non '
     '                         # Single Quote ends quoted string.  
     (?!')                     # Lookahead makes sure it's a single quote
   )                           # End of Quoted string group
 | .                           # OR - add a character to the Query.
 )*?)                          # End of 'Query' group.  (GO line is not included)
 (                             #
     (^\s*go\s*$)              # do this until a GO line  
 | (?!.)                       # OR no more characters (end of string)
 )                             # (queries end on a GO or end of string)
)*                             # rinse and repeat for all queries
"@

    [System.Text.RegularExpressions.Regex] $QueriesRegex  = `
        ( New-Object System.Text.RegularExpressions.Regex `
                     -ArgumentList ($this.QueriesExpression, [System.Text.RegularExpressions.RegexOptions]$this.QueriesRegexOptions))

    [string] $DBServerName
    [string] $DatabaseName
    [int]    $DefaultCommandTimeout
    [string] $RootFolderPath
    [bool]   $Checkpoint
    [System.Data.SqlClient.SqlConnection] $Connection
    [System.Data.SqlClient.SqlCommand]$SqlCommand

    [string] $OutFolderPath

    PatchContext( 
          [string] $DBServerName
        , [string] $DatabaseName
        , [string] $RootFolderPath
        , [string] $OutFolderPathParm
        , [string] $EnvironmentParm
        , [scriptblock] $PatchFileInitializationScript
        , [string] $dacpacDllPath
        , [bool]   $Checkpoint
        )
    {
        $this.Environment = $EnvironmentParm
        $this.Checkpoint = $Checkpoint
        $this.PatchFileInitializationScript = $PatchFileInitializationScript

        $this.TokenList = [TokenList]::new()

        $LoadSqlConstants = @()
        Import-LocalizedData -BaseDirectory $PSScriptRoot -FileName SqlConstants.psd1 -BindingVariable LoadSqlConstants
        $this.SqlConstants = $LoadSqlConstants


        $this.DBServerName = $DBServerName
        $this.DatabaseName = $DatabaseName
        $this.DefaultCommandTimeout = 180
        
        if (!(Test-Path $RootFolderPath -PathType Container))
        {
            Throw 'RootFolder is not folder - $RootFolderPathParm'
        }
        
        $this.RootFolderPath = Join-Path $RootFolderPath '\'  # assure consitent \ on root folder name
        
        # Initialize Connection
        $IntegratedConnectionString = 'Data Source={0}; Initial Catalog={1}; Integrated Security=True;MultipleActiveResultSets=False;Application Name="SQL Management"'
        $this.Connection = (New-Object 'System.Data.SqlClient.SqlConnection')
        $this.Connection.ConnectionString = $IntegratedConnectionString -f $DBServerName,$DatabaseName
        $this.Connection.Open()

        ## Attach the InfoMessage Event Handler to the connection to write out the messages 
        $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {
            param($sender, $event) 
            #Write-Host "----------------------------------------------------------------------------------------"
            $event | Format-List
            Write-Host "    >$($event.Message)"
        };
         
        $this.Connection.add_InfoMessage($handler); 
        $this.Connection.FireInfoMessageEventOnUserErrors = $false;

        $this.SqlCommand = $this.NewSqlCommand()

        $this.OutFolderPath = Join-Path $OutFolderPathParm (get-date -Format yyyy-MM-dd-HH.mm.ss.fff)
        if (! (Test-Path $this.OutFolderPath -PathType Container) )
        {
            mkdir $this.OutFolderPath | Out-Null
        }
        $this.OutFolderPath = Resolve-Path $this.OutFolderPath

        $this.DacPacUtil = [DacPacUtil]::new($this)
    }

    # ----------------------------------------------------------------------------------
    # This fuction takes a string or an array of strings and parses SQL blocks
    # Separated by 'GO' statements.   Go Statements must be the only word on
    # the line.  The parser ignores GO statements inside /* ... */ comments.
    hidden [array] ParseSqlStrings ([Object]$SqlStrings)
    {
        $SqlString = $SqlStrings | Out-String

        $SqlQueries = $this.QueriesRegex.Matches($SqlString)
        $ReturnValues = @()
        foreach ($capture in $SqlQueries[0].Groups['Query'].Captures)
        {
            $ReturnValues += $capture.Value | Where-Object{($_).trim().Length -gt 0}  # don't return empty strings
        }
        return $ReturnValues
    }

    # ----------------------------------------------------------------------------------
    hidden [array] LogExecutedSql($SqlString)
    {
        if ($this.LogSqlOutScreen)
        {
            return @($SqlString,'GO')
        }

        if ($this.SqlLogFile)
        {
            $SqlString,'GO' | Add-Content -Path $this.SqlLogFile
        }
        return $null
    }

    [void]PerformPatchFileInitializationScript()
    {
        Push-Location $this.RootFolderPath
        try
        {
            & $this.PatchFileInitializationScript
        }
        finally
        {
            Pop-Location
        }
    }

    # ----------------------------------------------------------------------------------
    [void] AssureSqlServerPatcher()
    {
        #if ($this.GetSqlServerPatcherVersion() -lt $this.ThisSqlServerPatcherVersion)
        #{
            $this.NewSqlCommand()
            $this.ExecuteNonQuery($this.SqlConstants.AssureSqlServerPatcherQuery)
        #}
    }

    # ----------------------------------------------------------------------------------
    [int] GetSqlServerPatcherVersion()
    {
        $this.NewSqlCommand($this.SqlConstants.GetSqlServerPatcherVersion)
        return $this.SqlCommand.ExecuteScalar()
    }

    # ----------------------------------------------------------------------------------
    [string] GetChecksumForPatch($PatchName)
    {
        if ($this.GetSqlServerPatcherVersion() -gt 0)
        {
            $this.NewSqlCommand($this.SqlConstants.ChecksumForPatchQuery)
            ($this.SqlCommand.Parameters.Add('@PatchName',$null)).value = $PatchName
            return $this.SqlCommand.ExecuteScalar()
        }
        else
        {
            return ''
        }
    }
    # ----------------------------------------------------------------------------------
    [void] NewSqlCommand($CommandText='')
    {
        $NewSqlCmd = $this.Connection.CreateCommand()
        $NewSqlCmd.CommandTimeout = $this.DefaultCommandTimeout
        $NewSqlCmd.CommandType = [System.Data.CommandType]::Text
        $NewSqlCmd.CommandText = $CommandText
        $this.SqlCommand = $NewSqlCmd
    }
    
    [void] NewSqlCommand()
    {
        $this.NewSqlCommand('')
    }

    [ExecutedPatch] ReadExecutedPatch([System.Data.SqlClient.SqlDataReader] $reader)
    {
        $FilePatchHash = @{}
        for ($idx=0; $idx -lt $reader.FieldCount; $idx++)
        {
            $FilePatchHash[$reader.GetName($idx)] = $reader.GetValue($idx)
        }
        if ($FilePatchHash.RollbackedByOID -is [System.DBNull])
        {
            $RollbackedByOID = 0
        }
        else
        {
            $RollbackedByOID = [int]$FilePatchHash.RollbackedByOID
        }
        $executedPatch = [ExecutedPatch]::new(
              [int]      $FilePatchHash.OID
            , [string]   $FilePatchHash.PatchName
            , [datetime] $FilePatchHash.Applied
            , [bool]     ($FilePatchHash.ExecutedByForce -eq $true)
            , [bool]     ($FilePatchHash.UpdatedOnChange -eq $true)
            , [bool]     ($FilePatchHash.IsRollback      -eq $true)
            , [int]      $RollbackedByOID
            , [string]   $FilePatchHash.CheckSum
            , [string]   $FilePatchHash.PatchScript
            , [string]   $FilePatchHash.RollbackScript
            , [string]   $FilePatchHash.RollbackChecksum
            , [string]   $FilePatchHash.LogOutput
            )
        return $executedPatch
    }

    # ----------------------------------------------------------------------------------
    [ExecutedPatch] RollbackExecutedPatch([ExecutedPatch]$ExecutedPatch)
    {
        $this.NewSqlCommand()
        $script = $this.GetRollbackScript($ExecutedPatch)
        $this.ExecuteNonQuery( $script )
        
        $this.NewSqlCommand($this.SqlConstants.GetLastRollback)
        [System.Data.SqlClient.SqlDataReader] $reader = $this.SqlCommand.ExecuteReader()
        try
        {
            $reader.Read() 
            return $this.ReadExecutedPatch($reader)
        }
        finally
        {
            $reader.Close()
        }
    }
    
    # ----------------------------------------------------------------------------------
    
    [array] GetExecutedPatches()
    {
        $this.NewSqlCommand($this.SqlConstants['SelectFilePatchesQuery'])

        [System.Data.SqlClient.SqlDataReader] $reader = $this.SqlCommand.ExecuteReader()
        $FilePatches = @()
        try
        {
            while ($reader.Read()) 
            {
                $FilePatches += $this.ReadExecutedPatch($reader)
            }
        }
        finally
        {
            $reader.Close()
        }
        return $FilePatches
    }

    # ----------------------------------------------------------------------------------

    [string] GetRollbackScript([ExecutedPatch]$ExecutedPatch)
    {
        $script = ($this.SqlConstants.BeginTransctionScript + "`nGO`n") + 
                  ($ExecutedPatch.RollbackScript + "`nGO`n") + 
                  ($this.SqlConstants.InsertRollback -f $ExecutedPatch.OID + "`nGO`n") +
                  ($this.SqlConstants.EndTransactionScript)
        
        return $script
    }

    # ----------------------------------------------------------------------------------
    [string] GetDBServerName()
    {
        return $this.DBServerName
    }

    [string] GetDatabaseName()
    {
        return $this.DatabaseName
    }

    # ----------------------------------------------------------------------------------

    [void] ExecuteNonQuery($Query,[switch]$DontLogErrorQuery,[string]$ErrorMessage)
    {
        $ParsedQueries = $this.ParseSqlStrings($Query)
        foreach ($ParsedQuery in $ParsedQueries)
        {
            if ($ParsedQuery.Trim() -ne '')
            {
                $this.LogExecutedSql($ParsedQuery)
                if (! $this.PublishWhatIf)
                {
                    try
                    {
                        $this.SqlCommand.CommandText = $ParsedQuery
                        [void] $this.SqlCommand.ExecuteNonQuery()
                    } 
                    catch
                    {
                        TerminalError $_ $ParsedQuery
                    }
                }
            }
        }
    }

    [void] ExecuteNonQuery($Query)
    {
        $this.ExecuteNonQuery($Query,$false,'')
    }

    # ----------------------------------------------------------------------------------
    [string] GetInsertFilePatchString($PatchName, $Checksum, $Content,$RollbackScript,$RollbackChecksum)
    {
        return $this.SqlConstants.InsertFilePatchSQL -f $PatchName.Replace("'","''"),$Checksum.Replace("'","''"),$Content.Replace("'","''"),$RollbackScript.Replace("'","''"),$RollbackChecksum.Replace("'","''"),'0','0'
    }

    # ----------------------------------------------------------------------------------
    [void] InsertFilePatch($PatchName, $Checksum, $Content,$RollbackScript,$RollbackChecksum)
    {
        $this.ExecuteNonQuery($this.GetInsertFilePatchString($PatchName,$Checksum, $Content,$RollbackScript,$RollbackChecksum))
    }

    # ----------------------------------------------------------------------------------
    [bool] TestEnvironment([System.IO.FileInfo]$file)
    {
        # returns false if the basename ends with '(something)' and something doesn't match $Environment or if it is $null
        if ($file.basename -match ".*?\((?'fileEnv'.*?)\)$")
        {
            return ($Matches['fileEnv'] -eq $this.Environment)
        }
        else
        {
            return $true
        }
    }

    # ----------------------------------------------------------------------------------
    [void] OutPatchFile($Filename,$Content)
    {
        $this.OutPatchCount += 1
        $outFileName = '{0:0000}-{1}' -f $this.OutPatchCount, ($Filename.Replace('\','-').Replace('/','-'))
        $Content | Set-Content -Path (Join-Path $this.OutFolderPath $outFileName)
    }
}

################################################################################################################
################################################################################################################
################################################################################################################

[CmdletBinding(
    SupportsShouldProcess=$True,ConfirmImpact=’Medium’
)]
class QueuedPatches : System.Collections.ArrayList {

    [PatchContext]$PatchContext

    QueuedPatches()
    {
    }

    [void]SetPatchContext($PatchContext)
    {
        $this.PatchContext = $PatchContext
    }

    [void] AddPatch([System.IO.FileInfo] $PatchFile,[bool]$Force,[bool]$ReExecuteOnChange)
    {
        $PatchFullName = $PatchFile.Fullname
        Write-Verbose "`$PatchFullName: $PatchFullName"
        [PatchInfo]$PatchInfo = [PatchInfo]::new($this.PatchContext,$PatchFullName,$Force,$ReExecuteOnChange)
        [PatchInfo]$ExistingPatch = $this | Where-Object{$_.PatchName -eq $PatchInfo.PatchName}
        if (!($ExistingPatch))
        {
            [void]$this.Add($PatchInfo)
        }
        else
        {
            $ExistingPatch.MergePatch($PatchInfo)
        }
    }

    [PatchInfo] GetTopPatch()
    {
        return $this[0]
    }

    [void] RemoveTopPatch()
    {
        $this.RemoveAt(0)    
    }

    [PatchInfo[]] GetExecutablePatches()
    {
        $patches = $this | Where-Object{$_.ShouldExecute()}
        return [array]($patches)
    }

    [int] GetPatchCount()
    {
        return ($this.GetExecutablePatches()).count
    }

    [void] PerformPatches()
    {
        $this.PerformPatches('')
    }

    [void] PerformPatches([string]$PatchName)
    {
        if ($this.GetPatchCount() -eq 0)
        {
            Write-Host -Object '    No Patches to Apply'
            return
        }
        try
        {
            $this.PatchContext.AssureSqlServerPatcher()
            foreach ($PatchInfo in $this.GetExecutablePatches())
            {
                if ($PatchName -eq '' -or $PatchName -eq $PatchInfo.PatchName)
                {
                    $this.PatchContext.NewSqlCommand()
                    if ($this.PatchContext.CheckPoint)
                    {
                        #if ($PSCmdlet.ShouldProcess($PatchInfo.PatchName,'Checkpoint Patch')) 
                        #{
                            Write-Host "Checkpoint (mark as executed) - $($PatchInfo.PatchName)"
                            $this.PatchContext.InsertFilePatch($PatchInfo.PatchName, $PatchInfo.Checksum, '', '', '')
                            $PatchInfo.Executed = $True
                        #}
                    }
                    else
                    {
                        Write-Host $PatchInfo.PatchName
                    
                        $WhatifExecute = $false
                        $patchScript = $PatchInfo.GetPatchScript()

                        $this.PatchContext.OutPatchFile($PatchInfo.PatchName, $patchScript)

                        if (!$WhatIfExecute)
                        {
                            $this.PatchContext.NewSqlCommand()
                            try
                            {
                                $this.PatchContext.ExecuteNonQuery( $patchScript )
                                $PatchInfo.Executed = $True
                            }
                            Catch
                            {
                                $this.PatchContext.ExecuteNonQuery($this.PatchContext.SqlConstants.RollbackTransactionScript)
                                throw $_
                            }
                        }
                    }
                }
            }
        }
        Catch
        {
            TerminalError $_
        }
    }
}

################################################################################################################
################################################################################################################
################################################################################################################

function TerminalError($Exception,$OptionalMsg)
{
    $ExceptionMessage = $Exception.Exception.Message;
    if ($Exception.Exception.InnerException)
    {
        $ExceptionMessage = $Exception.Exception.InnerException.Message;
    }
    $errorQueryMsg = "`n{0}`n{1}" -f $ExceptionMessage,$OptionalMsg
    #$host.ui.WriteErrorLine($errorQueryMsg) 
    
    # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    # Temp 
    $DisplayCallStack = $true

    if ($DisplayCallStack)
    {
        $brkline = '=========================================================================='
        $host.ui.WriteErrorLine($brkline)
        $host.ui.WriteErrorLine('Stack calls')
        $host.ui.WriteErrorLine($brkline)
        $stack = Get-PSCallStack

        $host.ui.WriteErrorLine("Location: $($Exception.InvocationInfo.PositionMessage)")
        $host.ui.WriteErrorLine(" Command: $($stack[1].Command)")
        #$host.ui.WriteErrorLine("Position: $($Exception.InvocationInfo.Line)")
        $host.ui.WriteErrorLine($brkline)

        for ($i = 1; $i -lt $stack.Count; $i++)
        #foreach ($stackItem in $stack)
        {
            $stackItem = $stack[$i]
            $host.ui.WriteErrorLine("Location: $($stackItem.Location)")
            $host.ui.WriteErrorLine(" Command: $($stackItem.Command)")
            $host.ui.WriteErrorLine("Position: $($stackItem.Position)")
            $host.ui.WriteErrorLine($brkline)
        }
    }
    Throw $errorQueryMsg
}

Export-ModuleMember -Function TerminalError

# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------
function Add-SqlDbPatches
{
    [CmdletBinding(
        SupportsShouldProcess=$True,ConfirmImpact=’Medium’
    )]
 
    PARAM
    ( [parameter(Mandatory=$True,ValueFromPipeline=$True,Position=0)]
      [system.IO.FileInfo[]]$PatchFiles
    , [switch]$ReExecuteOnChange
    , [switch]$Force
    )
 
    Process 
    {
        try
        {
            foreach ($PatchFile in $PatchFiles)
            {
                $script:QueuedPatches.AddPatch($PatchFile,$Force,$ReExecuteOnChange)
            }
        }
        Catch
        {
            TerminalError $_
        }
    }
}

Export-ModuleMember -Function Add-SqlDbPatches

# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------

function Publish-SqlServerPatches
{
    [CmdletBinding(SupportsShouldProcess = $TRUE,ConfirmImpact = 'Medium')]
 
    param ([string]$PatchName='') 
    $script:QueuedPatches.PerformPatches($PatchName)
    $script:QueuedPatches.Clear()
    $script:QueuedPatches.PatchContext.PerformPatchFileInitializationScript()
}

New-Alias -Name Publish-Patches -Value Publish-SqlServerPatches
New-Alias -Name PublishPatches -Value Publish-SqlServerPatches

Export-ModuleMember -Function Publish-SqlServerPatches -Alias Publish-Patches,PublishPatches

# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------

function Get-ExecutablePatches
{
    foreach ($PatchInfo in $QueuedPatches.GetExecutablePatches())
    {
        $PatchInfo
    }
}

Export-ModuleMember -Function Get-ExecutablePatches

# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------

function Get-SqlServerPatchHistory
{
    #param([switch] $ShowAllFields,[switch]$ShowRollbacks)
    param([switch]$ShowRollbacks)

    function IndexOfOid($oid)
    {
        $ExecutedPatches.Where({$_.Oid -eq $oid})
    }

    $ExecutedPatches = [System.Collections.ArrayList]::new()
    [void] ($QueuedPatches.PatchContext.GetExecutedPatches() | %{$ExecutedPatches.Add($_)})

    if (!$ShowRollbacks)
    {
        $RollbackPatches = @()
        foreach ($ExecutedPatch in $ExecutedPatches)
        {
            if ($ExecutedPatch.RollbackedByOID -eq 0 -and (!$ExecutedPatch.IsRollback))
            {
                $RollbackPatches += $ExecutedPatch
            }
        }
        $RollbackPatches
        #foreach ($RollbackPatch in $RollbackPatches)
        #{
        #    $ReferencedPatch = $ExecutedPatches.Where({$_.OID -eq $RollbackPatch.RollbackedByOID})
        #    if ($ReferencedPatch -eq $null)
        #    {
        #        throw ('Referenced Patch OID {0} not found.  It is Referenced by OID {1}' -f $RollbackPatch.RollbackedByOID,$RollbackPatch.OID)
        #    }
        #    $ExecutedPatches.Remove((IndexOfOid $RollbackPatch.OID))
        #    $ExecutedPatches.Remove((IndexOfOid $ReferencedPatch.OID))
        #}
    }
    else
    {
        $ExecutedPatches
    }
}

New-Alias -Name PatchHistory -Value Get-SqlServerPatchHistory

Export-ModuleMember -Function Get-SqlServerPatchHistory -Alias PatchHistory

# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------

function Get-SqlServerPatchInfo
{
    param ([switch] $PatchesToExecute)
    if ($PatchesToExecute)
    {
        $QueuedPatches.GetExecutablePatches()
    }
    else
    {
        $QueuedPatches
    }
}

New-Alias -Name PatchInfo -Value Get-SqlServerPatchInfo

Export-ModuleMember -Function Get-SqlServerPatchInfo -Alias PatchInfo

# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------

function Undo-SqlServerPatch
{
    param( [int] $OID
         , [switch] $Force
         , [switch] $OnlyOne
         , [switch] $RollbackRollback
         )

    function ValidateHasRollback($ExecutedPatch,[REF]$RollbackPatches,[REF]$WarningsDetected)
    {
        if ($ExecutedPatch.RollbackStatus -eq 'Not Available')
        {
            if ($Force)
            {
                Write-Warning ("Patch '{0}' - '{1}' cannot be rolled back. Skipping" -f $ExecutedPatch.OID,$ExecutedPatch.PatchName)
                $RollbackPatches.value += $ExecutedPatch
            }
            else
            {
                Write-Warning ("Patch '{0}' - '{1}' cannot be rolled back." -f $ExecutedPatch.OID,$ExecutedPatch.PatchName)
                $WarningsDetected.value++
            }
        }
        else
        {
            $RollbackPatches.value += $ExecutedPatch
        }
    }
    
    $ExecutedPatches = [System.Collections.ArrayList]::new()

    if ($RollbackRollback)
    {
        [void] (Get-SqlServerPatchHistory -ShowRollbacks | Where-Object{$_.IsRollback} | %{$ExecutedPatches.Add($_)})
    }
    else
    {
        [void] (Get-SqlServerPatchHistory | %{$ExecutedPatches.Add($_)})
    }

    $ExecutedPatches.Reverse()

    if ($OID -gt $ExecutedPatches[0].OID)
    {
        Throw "Specified Patch '$OID' is greater than last patch '$($ExecutedPatches[0].OID)'"
    }

    if ($OID -lt 1)
    {
        Throw "Patch '$OID' is less than 1"
    }

    $RollbackPatches = @()
    $WarningsDetected = 0
    if ($OnlyOne)
    {
        $ExecutedPatch = $ExecutedPatches | Where-Object{$OID -eq $_.OID}
        
        ValidateHasRollback $ExecutedPatch ([REF]$RollbackPatches) ([REF]$WarningsDetected)

        if ($OID -ne $ExecutedPatches[0].OID)
        {
            Write-Warning ("Patch '{0}' - '{1}' is not the last patch executed" -f $ExecutedPatch.OID,$ExecutedPatch.PatchName)
            
            if (!$Force)
            {
                $WarningsDetected++
            }
        }
    }
    else
    {
        foreach ($ExecutedPatch in $ExecutedPatches)
        {
            if ($ExecutedPatch.OID -lt $OID)
            {
                break;
            }
            ValidateHasRollback $ExecutedPatch ([REF]$RollbackPatches) ([REF]$WarningsDetected)
        }
    }

    if ($WarningsDetected -gt 0)
    {
        Throw "Detected $WarningsDetected blocking warnings. Use -Force to skip them."
    }

    foreach ($ExecutedPatch in $RollbackPatches)
    {
        #Write-Host ('Rollback {0} - {1}' -f $ExecutedPatch.OID, $ExecutedPatch.PatchName)
        $PatchContext.RollbackExecutedPatch($ExecutedPatch)
    }
    
    $script:QueuedPatches.Clear()
    $script:QueuedPatches.PatchContext.PerformPatchFileInitializationScript()
}

New-Alias -Name RollbackPatch -Value Undo-SqlServerPatch
Export-ModuleMember -Function Undo-SqlServerPatch -Alias RollbackPatch

# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------
function Add-TokenReplacement
{
    param([string]$TokenValue, [string]$ReplacementValue)
    $PatchContext.TokenList.AddTokenPair($TokenValue,$ReplacementValue)
}

Export-ModuleMember -Function Add-TokenReplacemen

# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------

function Test-SqlServerRollback
{
    param 
    ( [parameter(ValueFromPipeline=$True,Position=0)]
      [Patchinfo] $Patchinfo
    )

    begin
    {
        $PatchContext.AssureSqlServerPatcher()

        $DacpacName = 'PreTest.dacpac' 
        Write-Host "Create Pre-deploy DacPac '$DacpacName'"
        $PreDacpacFile = Join-Path $QueuedPatches.PatchContext.OutFolderPath $DacpacName
        Set-Dacpac -DacpacFilename $PreDacpacFile
    }
    process
    {
        if ($patchInfo -ne $null)
        {
            if (!($patchInfo.ShouldExecute()))
            {
                Throw "$PatchName already executed."
            }

            if ($patchInfo.RollbackContent -eq '')
            {
                Throw "$PatchName does not have a rollback script."
            }


            Write-Host '======================================================================================'
            Write-Host ('Verify "{0}"' -f $Patchinfo.PatchName)
            Write-Host '======================================================================================'
            Write-Host 'Perform patch'
            Publish-SqlServerPatches -PatchName $Patchinfo.PatchName

            $DacpacName = 'Post-{0}.dacpac' -f $Patchinfo.PatchName.Replace('\','_')
            Write-Host "Create Post-deploy DacPac '$DacpacName'"
            $PostDacpacFile = Join-Path $QueuedPatches.PatchContext.OutFolderPath $DacpacName
            Set-Dacpac -DacpacFilename $PostDacpacFile

            Write-Host 'Rollback patch'
            $ExecutedPatch = Get-SqlServerPatchHistory | Where-Object{$_.PatchName -eq $Patchinfo.PatchName}
            $UndoPatch = Undo-SqlServerPatch $ExecutedPatch.OID -OnlyOne -Force

            Write-Host 'Comparing Dacpac results after Rollback'
            $DacPacIssues = Get-DacpacActions $PreDacpacFile
            if ($DacPacIssues)
            {
                Write-Host 'Rollback Issues'
                $DacPacIssues | Format-Table *
                Throw 'Houston, we have a problem here.'
            }

            Write-Host 'Redeploy patch'
            Publish-SqlServerPatches -PatchName $Patchinfo.PatchName

            Write-Host 'Comparing Dacpac results after Redeploy'
            $DacPacIssues = Get-DacpacActions $PostDacpacFile
            if ($DacPacIssues)
            {
                Write-Host 'Redeploy Issues'
                $DacPacIssues | Format-Table *
                Throw 'Houston, we have a problem here.'
            }
            $PreDacpacFile = $PostDacpacFile
        }
    }
}

Export-ModuleMember -Function Test-SqlServerRollback

# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------

$PatchContext = $null

function Initialize-SqlServerPatcher
{
    [CmdletBinding(SupportsShouldProcess = $TRUE,ConfirmImpact = 'Medium')]

    param 
    ( [string]$ServerName
    , [string]$DatabaseName
    , [string]$RootFolderPath
    , [string]$Environment
    , [string]$OutFolderPath = (Join-Path -Path $RootFolderPath -ChildPath 'OutFolder')
    , [scriptblock]$PatchFileInitializationScript
    , [string]$SqlLogFile = $null
    , [string]$DacpacDllPath = 'C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\120'
    , [switch]$PublishWhatIf
    , [switch]$EchoSql
    , [switch]$DisplayCallStack
    , [switch]$Checkpoint
    )

    Write-Verbose -Message $LicenseMessage

    Write-Host -Object "Process DB Deployment for $DatabaseName on server $ServerName"
    Write-Host -Object "    RootFolder: $RootFolderPath"


    if ($SqlLogFile -and (Test-Path $SqlLogFile)) 
    {
        Remove-Item -Path $SqlLogFile
    }

    if (! (Test-Path $OutFolderPath -PathType Container) )
    {
        $null = mkdir $OutFolderPath
    }
    
    $script:PatchContext = [PatchContext]::new($ServerName,$DatabaseName,$RootFolderPath,$OutFolderPath,$Environment,$PatchFileInitializationScript,$DacpacDllPath,$Checkpoint)
    
    $PatchContext.DisplayCallstack = $DisplayCallStack
    $PatchContext.LogSqlOutScreen = $EchoSql
    $PatchContext.SqlLogFile = $SqlLogFile
    $PatchContext.PublishWhatIf = $PublishWhatIf

    $script:QueuedPatches = [QueuedPatches]::New()

    $script:QueuedPatches.SetPatchContext($script:PatchContext)

    $PatchContext.PerformPatchFileInitializationScript()

    # AssureSqlServerPatcher
}

Export-ModuleMember -Function Initialize-SqlServerPatcher

# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------

$PublishWhatIf = $false

[QueuedPatches]$QueuedPatches = [QueuedPatches]::New()

Export-ModuleMember -Variable QueuedPatches

########################################################################################
# 
#  Validate there aren't any Rollbacks without patches
