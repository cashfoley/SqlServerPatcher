#region License

$LicenseMessage = @"
SqlSafePatch - Powershell Database Deployment for SQL Server Database Updates with coordinated Software releases. 
Copyright (C) 2013-16 Cash Foley Software Consulting LLC
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 https://SqlSafePatch.codeplex.com/license
"@
#endregion

################################################################################################################
################################################################################################################
################################################################################################################
class Patch
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

    Patch ([PatchContext]$PatchContext,[System.IO.FileInfo]$PatchFile,$Force,$ReExecuteOnChange)
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
        $escapedfileContent = $this.PatchContent.Replace("'","''")
        $escapedRollbackPatch = $this.RollbackContent.Replace("'","''")

        $PatchScript = ($this.GoScript($this.PatchContext.SqlConstants.BeginTransctionScript)) + 
                       ($this.GoScript($this.PatchContent)) + 
                       ($this.GoScript($this.PatchContext.GetInsertFilePatchString($this.PatchName, $this.Checksum, $escapedfileContent, $escapedRollbackPatch,''))) +
                       ($this.GoScript($this.PatchContext.SqlConstants.EndTransactionScript))
        
        return $PatchScript
    }

    # ----------------------------------------------------------------------------------
    
    [void] MergePatch([Patch]$NewPatch)
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
    [bool]     $ExecutedByForce
    [bool]     $UpdatedOnChange
    [bool]     $RollBacked
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
        , [bool]     $RollBacked
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
      $this.RollBacked        = $RollBacked
      $this.CheckSum          = $CheckSum
      $this.PatchScript       = $PatchScript
      $this.RollbackScript    = $RollbackScript
      $this.RollbackChecksum  = $RollbackChecksum
      $this.LogOutput         = $LogOutput
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

Class PatchContext
{
    [TokenList] $TokenList

    [bool]      $DisplayCallStack
    [hashtable] $SqlConstants

    $OutPatchCount = 0
    
    $ThisSqlSafePatchVersion = 1
    $SqlSafePatchVersion

    [switch] $LogSqlOutScreen = $false
    [string] $SqlLogFile = $null
    [switch] $PublishWhatif = $false
    [string] $Environment = $EnvironmentParm

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
        , [bool]   $Checkpoint
        )
    {
        $this.Environment = $EnvironmentParm
        $this.Checkpoint = $Checkpoint

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

        $this.SqlSafePatchVersion = $this.GetSqlSafePatchVersion()
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

    # ----------------------------------------------------------------------------------
    [void] AssureSqlSafePatch()
    {
        if ($this.SqlSafePatchVersion -lt $this.ThisSqlSafePatchVersion)
        {
            $this.NewSqlCommand()
            $this.ExecuteNonQuery($this.SqlConstants.AssureSqlSafePatchQuery)
            $this.SqlSafePatchVersion = $this.GetSqlSafePatchVersion
        }
    }

    # ----------------------------------------------------------------------------------
    [int] GetSqlSafePatchVersion()
    {
        $this.NewSqlCommand($this.SqlConstants.GetSqlSafePatchVersion)
        return $this.SqlCommand.ExecuteScalar()
    }

    # ----------------------------------------------------------------------------------
    [string] GetChecksumForPatch($PatchName)
    {
        if ($this.SqlSafePatchVersion -gt 0)
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

    # ----------------------------------------------------------------------------------
    [array] GetExecutedPatches()
    {
        $this.NewSqlCommand($this.SqlConstants['SelectFilePatchesQuery'])

        [System.Data.SqlClient.SqlDataReader] $reader = $this.SqlCommand.ExecuteReader()
        $FilePatches = @()
        while ($reader.Read()) 
        {
            $FilePatchHash = @{}
            for ($idx=0; $idx -lt $reader.FieldCount; $idx++)
            {
                $FilePatchHash[$reader.GetName($idx)] = $reader.GetValue($idx)
            }
            $executedPatch = [ExecutedPatch]::new(
                  [int]      $FilePatchHash.OID
                , [string]   $FilePatchHash.PatchName
                , [datetime] $FilePatchHash.Applied
                , [bool]     ($FilePatchHash.ExecutedByForce -eq $true)
                , [bool]     ($FilePatchHash.UpdatedOnChange -eq $true)
                , [bool]     ($FilePatchHash.RollBacked      -eq $true)
                , [string]   $FilePatchHash.CheckSum
                , [string]   $FilePatchHash.PatchScript
                , [string]   $FilePatchHash.RollbackScript
                , [string]   $FilePatchHash.RollbackChecksum
                , [string]   $FilePatchHash.LogOutput
                )

            $FilePatches += $executedPatch
        }
        $reader.Close()
        return $FilePatches
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
        [Patch]$Patch = [Patch]::new($this.PatchContext,$PatchFullName,$Force,$ReExecuteOnChange)
        [Patch]$ExistingPatch = $this | ?{$_.PatchName -eq $Patch.PatchName}
        if (!($ExistingPatch))
        {
            [void]$this.Add($Patch)
        }
        else
        {
            $ExistingPatch.MergePatch($Patch)
        }
    }

    [patch] GetTopPatch()
    {
        return $this[0]
    }

    [void] RemoveTopPatch()
    {
        $this.RemoveAt(0)    
    }

    [Patch[]] GetExecutablePatches()
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
            if ($this.GetPatchCount() -eq 0)
        {
            Write-Host -Object '    No Patches to Apply'
            return
        }
        try
        {
            $this.PatchContext.AssureSqlSafePatch()
            foreach ($Patch in $this.GetExecutablePatches())
            {
                $this.PatchContext.NewSqlCommand()
                if ($this.PatchContext.CheckPoint)
                {
                    #if ($PSCmdlet.ShouldProcess($Patch.PatchName,'Checkpoint Patch')) 
                    #{
                        Write-Host "Checkpoint (mark as executed) - $($Patch.PatchName)"
                        $this.PatchContext.InsertFilePatch($Patch.PatchName, $Patch.Checksum, '', '', '')
                        $Patch.Executed = $True
                    #}
                }
                else
                {
                    Write-Host $Patch.PatchName
                    
                    $WhatifExecute = $false
                    $patchScript = $Patch.GetPatchScript()

                    $this.PatchContext.OutPatchFile($Patch.PatchName, $patchScript)

                    if (!$WhatIfExecute)
                    {
                        $this.PatchContext.NewSqlCommand()
                        try
                        {
                            $this.PatchContext.ExecuteNonQuery( $patchScript )
                            $Patch.Executed = $True
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
        Catch
        {
            TerminalError $_
        }
        $this.PatchContext.Connection.Close()
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
    $host.ui.WriteErrorLine($errorQueryMsg) 
    
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
    Exit
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

function Publish-Patches
{
    [CmdletBinding(SupportsShouldProcess = $TRUE,ConfirmImpact = 'Medium')]
 
    param () 
    $script:QueuedPatches.PerformPatches()
}

Export-ModuleMember -Function Publish-Patches

# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------

function Get-ExecutablePatches
{
    foreach ($patch in $QueuedPatches.GetExecutablePatches())
    {
        $patch
    }
}

Export-ModuleMember -Function Get-ExecutablePatches

# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------

function Get-PatchHistory
{
    param([switch] $ShowAllFields)

    $ExecutedPatches = $QueuedPatches.PatchContext.GetExecutedPatches()

    if ($ShowAllFields)
    {
        $ExecutedPatches
    }
    else
    {
        foreach ($ExecutedPatch in $ExecutedPatches)
        {
            $RollbackStatus = 'Not Available'
            if ($ExecutedPatch.RollBacked)
            {
                $RollbackStatus = 'Completed'
            }
            elseif ($ExecutedPatch.RollbackScript)
            {
                $RollbackStatus = 'Available'
            }
            [PSCustomObject]@{ OID=$ExecutedPatch.OID
                               PatchName=$ExecutedPatch.PatchName
                               Applied=$ExecutedPatch.Applied
                               RollBackStatus = $RollbackStatus
                             }
        }
        #$ExecutedPatches | %{[psobject]::new(@{OID=$_.OID;PatchName=$_.PatchName})}
    }
}

Export-ModuleMember -Function Get-PatchHistory

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

$PatchContext = $null

function Initialize-SqlSafePatch
{
    [CmdletBinding(SupportsShouldProcess = $TRUE,ConfirmImpact = 'Medium')]

    param 
    ( $ServerName
    , $DatabaseName
    , $RootFolderPath
    , $Environment
    , $OutFolderPath = (Join-Path -Path $RootFolderPath -ChildPath 'OutFolder')
    , $SqlLogFile = $null
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
    
    $script:PatchContext = [PatchContext]::new($ServerName,$DatabaseName,$RootFolderPath,$OutFolderPath,$Environment,$Checkpoint)
    
    $PatchContext.DisplayCallstack = $DisplayCallStack
    $PatchContext.LogSqlOutScreen = $EchoSql
    $PatchContext.SqlLogFile = $SqlLogFile
    $PatchContext.PublishWhatIf = $PublishWhatIf

    $script:QueuedPatches = [QueuedPatches]::New()

    $script:QueuedPatches.SetPatchContext($script:PatchContext)

    # AssureSqlSafePatch
}

Export-ModuleMember -Function Initialize-SqlSafePatch

# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------

$PublishWhatIf = $false

[QueuedPatches]$QueuedPatches = [QueuedPatches]::New()

Export-ModuleMember -Variable QueuedPatches

########################################################################################
# 
#  Validate there aren't any Rollbacks without patches
