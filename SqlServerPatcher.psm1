
# ----------------------------------------------------------------------------------
class Patch
{
    hidden $Content

    $PatchContext
    $PatchFile
    $PatchName
    $CheckSum
    $CheckPoint
    $PatchContent
    $PatchAttributes = @{}

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
        $fileContent = Get-Content $this.PatchFile | Out-String
        $this.PatchContent = ($this.GoScript($this.PatchContext.SqlConstants.BeginTransctionScript)) + 
                             ($this.GoScript($this.PatchContext.TokenList.ReplaceTokens($fileContent))) + 
                             ($this.GoScript($this.PatchContext.GetMarkPatchAsExecutedString($this.PatchName, $this.Checksum, ''))) +
                             ($this.GoScript($this.PatchContext.SqlConstants.EndTransactionScript))
    }

    Patch ([PatchContext]$PatchContext,$PatchFile,$PatchName,$CheckPoint)
    {
        $this.PatchContext = $PatchContext
        $this.PatchFile = $PatchFile
        $this.PatchName = $PatchName
        $this.CheckPoint = $CheckPoint
        $this.PatchAttributes = @{}

        $this.CheckSum = $This.GetFileChecksum($PatchFile)
        $this.SetPatchContent()
     }
}

# ----------------------------------------------------------------------------------

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

# ----------------------------------------------------------------------------------
Class PatchContext
{
    [TokenList] $TokenList

    [bool]      $DisplayCallStack
    [hashtable] $SqlConstants

    $OutPatchCount = 0
    
    $ThisSqlServerSafePatchVersion = 1
    $SqlServerSafePatchVersion

    [switch] $LogSqlOutScreen = $false
    [string] $SqlLogFile = $null
    [switch] $PublishWhatif = $false
    [string] $Environment = $EnvironmentParm

    [string] $QueriesRegexOptions = 'IgnorePatternWhitespace,Singleline,IgnoreCase,Multiline,Compiled'
    [string] $QueriesExpression = "((?'Query'(?:(?:/\*.*?\*/)|.)*?)(?:^\s*go\s*$))*(?'Query'.*)"

    [System.Text.RegularExpressions.Regex] $QueriesRegex  = `
        ( New-Object System.Text.RegularExpressions.Regex `
                     -ArgumentList ($this.QueriesExpression, [System.Text.RegularExpressions.RegexOptions]$this.QueriesRegexOptions))

    [string] $DBServerName
    [string] $DatabaseName
    [int]    $DefaultCommandTimeout
    [string] $RootFolderPath
    $Connection
    $SqlCommand

    [string] $OutFolderPath

    PatchContext( $DBServerName
        , $DatabaseName
        , $RootFolderPath
        , $OutFolderPathParm
        , $EnvironmentParm
        )
    {
        $this.Environment = $EnvironmentParm

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

        $this.SqlServerSafePatchVersion = $this.GetSqlServerSafePatchVersion()
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
    [void] AssureSqlServerSafePatch()
    {
        if ($this.SqlServerSafePatchVersion -lt $this.ThisSqlServerSafePatchVersion)
        {
            $this.NewSqlCommand()
            $this.ExecuteNonQuery($this.SqlConstants.AssureSqlServerSafePatchQuery)
            $this.SqlServerSafePatchVersion = $this.GetSqlServerSafePatchVersion
        }
    }

    # ----------------------------------------------------------------------------------
    [int] GetSqlServerSafePatchVersion()
    {
        $this.NewSqlCommand($this.SqlConstants.GetSqlServerSafePatchVersion)
        return $this.SqlCommand.ExecuteScalar()
    }

    # ----------------------------------------------------------------------------------
    [string] GetChecksumForPatch($filePath)
    {
        if ($this.SqlServerSafePatchVersion -gt 0)
        {
            $this.NewSqlCommand($this.SqlConstants.ChecksumForPatchQuery)
            ($this.SqlCommand.Parameters.Add('@FilePath',$null)).value = $filePath
            return $this.SqlCommand.ExecuteScalar()
        }
        else
        {
            return ''
        }
    }
    # ----------------------------------------------------------------------------------
    [string] GetPatchName( [string]$PatchFile )
    {
        if (! $Patchfile.StartsWith($this.RootFolderPath))
        {
            Throw ("Patchfile '{0}' not under RootFolder '{1}'" -f $PatchFile,$this.RootFolderPath)
        }
        return $PatchFile.Replace($this.RootFolderPath, '')
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
    [string] GetMarkPatchAsExecutedString($filePath, $Checksum, $Content)
    {
        return $this.SqlConstants.MarkPatchAsExecutedQuery -f $filePath.Replace("'","''"),$Checksum.Replace("'","''"),$Content.Replace("'","''")
    }

    # ----------------------------------------------------------------------------------
    [void] MarkPatchAsExecuted($filePath, $Checksum, $Content)
    {
        $this.ExecuteNonQuery($this.GetMarkPatchAsExecutedString($filePath,$Checksum, $Content))
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

# ----------------------------------------------------------------------------------

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

    [void] AddPatch([patch] $Patch)
    {
        $this.Add($Patch)
    }

    [patch] GetTopPatch()
    {
        return $this[0]
    }

    [void] RemoveTopPatch()
    {
        $this.RemoveAt(0)    
    }

    [void] PerformPatches()
    {
            if ($this.Count -eq 0)
        {
            Write-Host -Object '    No Patches to Apply'
            return
        }
        try
        {
            $this.PatchContext.AssureSqlServerSafePatch()
            while ($this.Count -gt 0)
            {
                $Patch = $this.GetTopPatch()
                
                $this.PatchContext.NewSqlCommand()
                if ($Patch.CheckPoint)
                {
                    #if ($PSCmdlet.ShouldProcess($Patch.PatchName,'Checkpoint Patch')) 
                    #{
                        # Write-Host "Checkpoint (mark as executed) - $($Patch.PatchName)"
                        $this.PatchContext.MarkPatchAsExecuted($Patch.PatchName, $Patch.Checksum, '')
                    #}
                }
                else
                {
                    #$WhatIfExecute = $TRUE
                    #if ($PSCmdlet.ShouldProcess($Patch.PatchName,'Publish Patch')) 
                    #{
                    #    $WhatIfExecute = $false
                    #}
                    #PerformPatches -Patches $Patch -PatchContext $this.PatchContext -WhatIfExecute:$WhatIfExecute
                    PerformPatches -Patches $Patch -PatchContext $this.PatchContext -WhatIfExecute:$false
                }
                $this.RemoveTopPatch()
            }
        }
        Catch
        {
            TerminalError $_
        }
        $this.PatchContext.Connection.Close()
    }


}

# ----------------------------------------------------------------------------------
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
function PerformPatches
{
    param
    ( [parameter(Mandatory=$True,ValueFromPipeline=$True,Position=0)]
      $Patches
	, $PatchContext
    , $WhatIfExecute = $True
    )
    process
    {
        foreach ($Patch in $Patches)
        {
            Write-Host $Patch.PatchName
                
            $PatchContext.OutPatchFile($Patch.PatchName, $Patch.patchContent)

            if (!$WhatIfExecute)
            {
                $PatchContext.NewSqlCommand()
                try
                {
                    $PatchContext.ExecuteNonQuery( $Patch.patchContent )
                }
                Catch
                {
                    $PatchContext.ExecuteNonQuery($PatchContext.SqlConstants.RollbackTransactionScript)
                    throw $_
                }
            }
        }
    }
}

Export-ModuleMember -Function PerformPatches

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
    , [switch]$CheckPoint
    , [switch]$Force
    )
 
    Process 
    {
        try
        {
            foreach ($PatchFile in $PatchFiles)
            {
                $PatchFile = $PatchFile.Fullname
                Write-Verbose "`$PatchFile: $PatchFile"

                $PatchName = $PatchContext.GetPatchName($PatchFile)
                Write-Verbose "`$PatchName: $PatchName"
            
                if (! ($PatchContext.TestEnvironment($PatchFile) ) )
                {
                    Write-Verbose "`$PatchName ignored because it is the wrong target environment"
                }
                elseif ($script:QueuedPatches.Where({$_.PatchName -eq $PatchName}))
                {
                    Write-Verbose "`$PatchName ignored because it is already queued"
                }
                else
                {
                    $Patch = [Patch]::new($PatchContext,$PatchFile,$PatchName,$CheckPoint)
                    
                    $PatchCheckSum = [string]($PatchContext.GetChecksumForPatch($PatchName))
            
                    if ($Patch.Checksum -ne $PatchCheckSum -or $Force)
                    {
                        if (!$ReExecuteOnChange -and ($PatchCheckSum -ne ''))
                        {
                            Write-Warning "Patch $PatchName has changed but will be ignored"
                        }
                        else
                        {
                            [void]$script:QueuedPatches.Add($Patch)
                        }
                    }
                    else
                    {
                        Write-Verbose "Patch $PatchName current" 
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

Export-ModuleMember -Function Add-SqlDbPatches

#region License

$LicenseMessage = @"
SqlServerSafePatch - Powershell Database Deployment for SQL Server Database Updates with coordinated Software releases. 
Copyright (C) 2013-16 Cash Foley Software Consulting LLC
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 https://SqlServerSafePatch.codeplex.com/license
"@
#endregion

# ----------------------------------------------------------------------------------

function ExecuteValidators
{
     param
     (
         [array]
         $RegExValidators,

         [Object]
         $SqlContent
     )
 
    if ($RegExValidators -ne $null)
    {
        $errorFound = $false
        foreach ($RegExValidator in $RegExValidators)
        {
            $ValidatorMatches = $SqlContent -match $RegExValidators
            if ($ValidatorMatches)
            {
                #Need Validator Hash Table
                Log-Error $validator.message
                $errorFound = $TRUE
            }
        }
        if ($errorFound)
        {
            Throw 'Validators Failed'
        }
    }
}

function ExecutePatchBatch
{
     param
     (
         [Object]
         $PatchBatch
     )


}
function Publish-Patches
{
    [CmdletBinding(
            SupportsShouldProcess = $TRUE,ConfirmImpact = 'Medium'
    )]
 
    param () 
    $script:QueuedPatches.PerformPatches()

}

Export-ModuleMember -Function Publish-Patches

# ----------------------------------------------------------------------------------

function Add-TokenReplacement
{
     param
     (
         [string]
         $TokenValue,

         [string]
         $ReplacementValue
     )

    $PatchContext.TokenList.AddTokenPair($TokenValue,$ReplacementValue)
}

Export-ModuleMember -Function Add-TokenReplacemen

# ----------------------------------------------------------------------------------

$PatchContext = $null

function Initialize-SqlServerSafePatch
{
    [CmdletBinding(
            SupportsShouldProcess = $TRUE,ConfirmImpact = 'Medium'
    )]

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
    
    $script:PatchContext = [PatchContext]::new($ServerName,$DatabaseName,$RootFolderPath,$OutFolderPath,$Environment)
    
    $PatchContext.DisplayCallstack = $DisplayCallStack
    $PatchContext.LogSqlOutScreen = $EchoSql
    $PatchContext.SqlLogFile = $SqlLogFile
    $PatchContext.PublishWhatIf = $PublishWhatIf

    $script:QueuedPatches = [QueuedPatches]::New()

    $script:QueuedPatches.SetPatchContext($script:PatchContext)

    # AssureSqlServerSafePatch
}

Export-ModuleMember -Function Initialize-SqlServerSafePatch -Verbose

$PublishWhatIf = $false

[QueuedPatches]$QueuedPatches = [QueuedPatches]::New()

Export-ModuleMember -Variable QueuedPatches

