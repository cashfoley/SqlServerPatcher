
function Get-PatchContext ($ServerName, $DatabaseName, $RootFolderPath, $OutFolderPath, $DefaultConstants, [switch]$DisplayCallStack, $Environment)
{
    New-Module -AsCustomObject -ArgumentList $ServerName, $DatabaseName, $RootFolderPath, $OutFolderPath, $DefaultConstants, $DisplayCallStack, $Environment -ScriptBlock {
        param
        ( $DBServerNameParm
        , $DatabaseNameParm
        , $RootFolderPathParm
        , $OutFolderPathParm
        , $DefaultConstants
        , $DisplayCallStackParm
        , $EnvironmentParm
        )
        $ErrorActionPreference = 'Stop'
        Set-StrictMode -Version 2

        $DisplayCallStack = $DisplayCallStackParm

        #region Private Functions
        # ----------------------------------------------------------------------------------

        $QueriesRegexOptions = 'IgnorePatternWhitespace,Singleline,IgnoreCase,Multiline,Compiled'
        $QueriesExpression = "((?'Query'(?:(?:/\*.*?\*/)|.)*?)(?:^\s*go\s*$))*(?'Query'.*)"
        $QueriesRegex = New-Object System.Text.RegularExpressions.Regex -ArgumentList ($QueriesExpression, [System.Text.RegularExpressions.RegexOptions]$QueriesRegexOptions)

        # ----------------------------------------------------------------------------------
        # This fuction takes a string or an array of strings and parses SQL blocks
        # Separated by 'GO' statements.   Go Statements must be the only word on
        # the line.  The parser ignores GO statements inside /* ... */ comments.
        function ParseSqlStrings ($SqlStrings)
        {
            $SqlString = $SqlStrings | Out-String

            $SqlQueries = $QueriesRegex.Matches($SqlString)
            foreach ($capture in $SqlQueries[0].Groups['Query'].Captures)
            {
                $capture.Value | ?{($_).trim().Length -gt 0}  # don't return empty strings
            }
        }

        # ----------------------------------------------------------------------------------
        function LogExecutedSql($SqlString)
        {
            if ($LogSqlOutScreen)
            {
                $SqlString,'GO' | Write-Output 
            }
            if ($SqlLogFile)
            {
                $SqlString,'GO' | Add-Content -Path $SqlLogFile
            }
        }
        #endregion
        
        #region Exported Functions
$AssurePsDbDeployQuery = @"
-- Adds PsDbDeploy Objects if they don't exist
--    SCHEMA [PsDbDeploy]
--    TABLE [PsDbDeploy].[FilePatches]
--    PROCEDURE #MarkPatchExecuted

BEGIN TRANSACTION;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'PsDbDeploy')
EXEC sys.sp_executesql N'CREATE SCHEMA [PsDbDeploy] AUTHORIZATION [dbo]'
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PsDbDeploy].[FilePatches]') AND type in (N'U'))
BEGIN
CREATE TABLE [PsDbDeploy].[FilePatches](
    [OID]        [bigint]   IDENTITY(1,1) NOT NULL,
    [FilePath]   [nvarchar] (450) NOT NULL,
    [Applied]    [datetime] NOT NULL,
    [CheckSum]   [nvarchar] (512) NOT NULL,
    [Content]    [nvarchar] (MAX),
    [LogOutput]  [nvarchar] (MAX)
) ON [PRIMARY]
    
CREATE UNIQUE NONCLUSTERED INDEX [UIDX_PsDbDeployFilePatches_FilePath] ON [PsDbDeploy].[FilePatches]
(
    [FilePath] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

END
GO

IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'#MarkPatchExecuted') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
    CREATE PROCEDURE #MarkPatchExecuted     
        @FilePath [nvarchar](450),
        @CheckSum [nvarchar](100),
        @Content  [nvarchar](4000)
    AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @OID bigint

        SELECT @OID=OID
            FROM [PsDbDeploy].[FilePatches]
            WHERE FilePath = @FilePath

        IF  (@@ROWCOUNT = 0)
        BEGIN
            INSERT 
                INTO [PsDbDeploy].[FilePatches]
                    ( [FilePath]
                    , [Applied]
                    , [CheckSum]
                    , [Content])
            VALUES (@FilePath
                    , GetDate()
                    , @CheckSum
                    , @Content)
        END
        ELSE BEGIN
            UPDATE [PsDbDeploy].[FilePatches]
                SET CheckSum=@CheckSum
                    , Applied=GetDate()
                    , Content=@Content
                WHERE OID=@OID
                AND CheckSum<>@CheckSum
        END
    END
' 
END
GO

COMMIT TRANSACTION;
"@

#-----------------------------------------------------------------------------------------------
$GetPsDbDeployVersion = @"
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[PsDbDeploy].[FilePatches]') AND type in (N'U'))
BEGIN
    SELECT 1
END
ELSE BEGIN
    SELECT 0
END
"@

#-----------------------------------------------------------------------------------------------
    
$ChecksumForPatchQuery = @"
SELECT CheckSum
    FROM [PsDbDeploy].[FilePatches]
    WHERE FilePath = @FilePath
"@

#-----------------------------------------------------------------------------------------------
$MarkPatchAsExecutedQuery = @"
EXEC #MarkPatchExecuted @FilePath,@CheckSum,@Content
"@

        # ----------------------------------------------------------------------------------
        function AssurePsDbDeploy
        {
            if ($PsDbDeployVersion -lt $ThisPsDbDeployVersion)
            {
                NewSqlCommand
                ExecuteNonQuery $AssurePsDbDeployQuery
                $script:PsDbDeployVersion = Get-PsDbDeployVersion
                
                AssurePsDbDeploy2
            }
        }
        export-ModuleMember -Function AssurePsDbDeploy
        # ----------------------------------------------------------------------------------
        function Get-PsDbDeployVersion
        {
            NewSqlCommand $GetPsDbDeployVersion
            $SqlCommand.ExecuteScalar()
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
        $ShaProvider = New-Object 'System.Security.Cryptography.SHA1CryptoServiceProvider'
        $MD5Provider = New-Object 'System.Security.Cryptography.MD5CryptoServiceProvider'
        function GetFileChecksum ([System.IO.FileInfo] $fileInfo)
        {
            $file = New-Object 'system.io.FileStream' ($fileInfo, [system.io.filemode]::Open, [system.IO.FileAccess]::Read)
        
            try
            {
                $shaHash = [system.Convert]::ToBase64String($ShaProvider.ComputeHash($file))  
                #$file.Position =0
                #$md5Hash = [system.Convert]::ToBase64String($MD5Provider.ComputeHash($file))  

                #Sample: md5:'KJ5/LZAAzMmOzHn7rowksg==' sha:'LNa8s47m0pa8BUPmy8QNQsc/vdc=' length:006822
                #"md5:'{0}' sha:'{1}' length:{2:d6}" -f $md5Hash,$shaHash,$fileInfo.Length
                
                '{0} {1:d7}' -f $shaHash,$fileInfo.Length
            }
            finally 
            {
                $file.Close()
            }
        }
        Export-ModuleMember -Function GetFileChecksum 

        # ----------------------------------------------------------------------------------
        function GetChecksumForPatch($filePath)
        {
            if ($PsDbDeployVersion -gt 0)
            {
                NewSqlCommand $ChecksumForPatchQuery
                ($SqlCommand.Parameters.Add('@FilePath',$null)).value = $filePath
                $SqlCommand.ExecuteScalar()
            }
            else
            {
                ''
            }
        }
        Export-ModuleMember -Function GetChecksumForPatch 

        # ----------------------------------------------------------------------------------
        function GetPatchName( [string]$PatchFile )
        {
            if (! $Patchfile.StartsWith($RootFolderPath))
            {
                Throw ("Patchfile '{0}' not under RootFolder '{1}'" -f $PatchFile,$RootFolderPath)
            }
            $PatchFile.Replace($RootFolderPath, '')
        }
        Export-ModuleMember -Function GetPatchName 

        # ----------------------------------------------------------------------------------
        
        function NewSqlCommand($CommandText='')
        {
            $NewSqlCmd = $Connection.CreateCommand()
            $NewSqlCmd.CommandTimeout = $DefaultCommandTimeout
            $NewSqlCmd.CommandType = [System.Data.CommandType]::Text
            $NewSqlCmd.CommandText = $CommandText
            $Script:SqlCommand = $NewSqlCmd
        }
        Export-ModuleMember -Function NewSqlCommand 

        # ----------------------------------------------------------------------------------

        function Get-DBServerName
        {
            $DBServerName
        }
        Export-ModuleMember -Function Get-DBServerName 

        # ----------------------------------------------------------------------------------

        function Get-DatabaseName
        {
            $DatabaseName
        }
        Export-ModuleMember -Function Get-DatabaseName 

        # ----------------------------------------------------------------------------------
        function ExecuteNonQuery($Query,[switch]$DontLogErrorQuery,[string]$ErrorMessage)
        {
            $ParsedQueries = ParseSqlStrings $Query
            foreach ($ParsedQuery in $ParsedQueries)
            {
                if ($ParsedQuery.Trim() -ne '')
                {
                    LogExecutedSql $ParsedQuery
                    if (! $PublishWhatIf)
                    {
                        try
                        {
                            $SqlCommand.CommandText=$ParsedQuery
                            [void] $SqlCommand.ExecuteNonQuery()
                        } 
                        catch
                        {
                            TerminalError $_ $ParsedQuery
                        }
                    }
                }
            }
        }
        Export-ModuleMember -Function ExecuteNonQuery 

        # ----------------------------------------------------------------------------------
        function GetMarkPatchAsExecutedString($filePath, $Checksum, $Content)
        {
            "EXEC #MarkPatchExecuted N'{0}',N'{1}',N'{2}'" -f $filePath.Replace("'","''"),$Checksum.Replace("'","''"),$Content.Replace("'","''")
        }
        Export-ModuleMember -Function GetMarkPatchAsExecutedString 

        # ----------------------------------------------------------------------------------
        function MarkPatchAsExecuted($filePath, $Checksum, $Content)
        {
            ExecuteNonQuery (GetMarkPatchAsExecutedString -filepath $filePath -checksum $Checksum -Content $Content )
        }
        Export-ModuleMember -Function MarkPatchAsExecuted 

        # ----------------------------------------------------------------------------------
        Function ParseSchemaAndObject($SourceStr, $ParseRegex)
        {
            function isNumeric ($x) {
                $x2 = 0
                $isNum = [System.Int32]::TryParse($x, [ref]$x2)
                return $isNum
            }

            $GotMatches = $SourceStr -match $ParseRegex
            $ParesedOwner = @{}
            if ($GotMatches)
            {
                foreach ($key in $Matches.Keys)
                {
                    if (!(isNumeric $key))
                    {
                        $ParesedOwner[$key] =$Matches[$key]
                    }
                }
            }

            $GotMatches,$ParesedOwner
        }
        Export-ModuleMember -Function ParseSchemaAndObject 

        # ----------------------------------------------------------------------------------
        function ReplacePatternValues($text,$MatchSet)
        {
            foreach ($key in $MatchSet.Keys)
            {
                $source = '@(' + $key + ')'
                $text = $text.Replace($source, $MatchSet[$key])
            }
            $text
        }

        Export-ModuleMember -Function ReplacePatternValues 

        # ----------------------------------------------------------------------------------
        function NewPatchObject($PatchFile,$PatchName,$Checksum,$CheckPoint,$Content)
        {
            New-Object -TypeName PSObject -Property (@{
                PatchFile = $PatchFile
                PatchName = $PatchName
                CheckSum = $CheckSum
                Content = $Content
                CheckPoint = $CheckPoint
                PatchContent = Get-Content $PatchFile | Out-String
                #BeforeEachPatch = $BeforeEachPatch
                #AfterEachPatch = $AfterEachPatch
                PatchAttributes = @{}
                #ErrorException = $null
                }) 
        }	
        
        Export-ModuleMember -Function NewPatchObject 

        # ----------------------------------------------------------------------------------
        function TestEnvironment([System.IO.FileInfo]$file)
        {
            # returns false if the basename ends with '(something)' and something doesn't match $Environment or if it is $null
            if ($file.basename -match ".*?\((?'fileEnv'.*?)\)$")
            {
                ($Matches['fileEnv'] -ne $Environment)
            }
            else
            {
                $true
            }
        }

        Export-ModuleMember -Function TestEnvironment 

        # ----------------------------------------------------------------------------------
        function OutPatchFile($Filename,$Content)
        {
            $script:OutPatchCount += 1
            $outFileName = '{0:0000}-{1}' -f $OutPatchCount, ($Filename.Replace('\','-').Replace('/','-'))
            $Content | Set-Content -Path (Join-Path $OutFolderPath $outFileName)
        }

        Export-ModuleMember -Function OutPatchFile 

        #endregion
        
        # ----------------------------------------------------------------------------------
        $DBServerName = $DBServerNameParm
        $DatabaseName = $DatabaseNameParm
        $DefaultCommandTimeout = 180
        
        if (!(Test-Path $RootFolderPathParm -PathType Container))
        {
            Throw 'RootFolder is not folder - $RootFolderPathParm'
        }
        
        $RootFolderPath = Join-Path $RootFolderPathParm '\'  # assure consitent \ on root folder name
        Export-ModuleMember -Variable RootFolderPath 

        $Constants = $DefaultConstants
        Export-ModuleMember -Variable Constants 
        
        # Initialize Connection
        $IntegratedConnectionString = 'Data Source={0}; Initial Catalog={1}; Integrated Security=True;MultipleActiveResultSets=False;Application Name="SQL Management"'
        $Connection = (New-Object 'System.Data.SqlClient.SqlConnection')
        $Connection.ConnectionString = $IntegratedConnectionString -f $DBServerName,$DatabaseName
        $Connection.Open()
        Export-ModuleMember -Variable Connection 

        ## Attach the InfoMessage Event Handler to the connection to write out the messages 
        $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] {
            param($sender, $event) 
            #Write-Host "----------------------------------------------------------------------------------------"
            $event | FL
            Write-Host "    >$($event.Message)"
        };
         
        $Connection.add_InfoMessage($handler); 
        $Connection.FireInfoMessageEventOnUserErrors = $false;

        $SqlCommand = NewSqlCommand

        $TokenReplacements = @()
        Export-ModuleMember -Variable TokenReplacements

        $OutFolderPath = Join-Path $OutFolderPathParm (get-date -Format yyyy-MM-dd-HH.mm.ss.fff)
        if (! (Test-Path $OutFolderPath -PathType Container) )
        {
            mkdir $OutFolderPath | Out-Null
        }

        $OutPatchCount = 0
    
        $ThisPsDbDeployVersion = 1
        $PsDbDeployVersion = Get-PsDbDeployVersion
        $LogSqlOutScreen = $false
        $SqlLogFile = $null
        $PublishWhatif = $false
        $Environment = $EnvironmentParm

        Export-ModuleMember -Variable SqlCommand 
        Export-ModuleMember -Variable LogSqlOutScreen 
        Export-ModuleMember -Variable PublishWhatif 
        Export-ModuleMember -Variable SqlLogFile 
        Export-ModuleMember -Variable OutFolderPath
        Export-ModuleMember -Variable OutPatchCount
        Export-ModuleMember -Variable Environment 
        Export-ModuleMember -Function NewCommand
    }
}

function ReplaceTokens([string]$str)
{
    foreach ($TokenReplacement in $PatchContext.TokenReplacements)
    {
        $str = $str.Replace($TokenReplacement.TokenValue,$TokenReplacement.ReplacementValue)
    }
    $str
}

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
                New-DbPatch -FilePath $Patch.PatchName -Checksum $Patch.Checksum -Content $Patch.patchContent
                try
                {
                    $PatchContext.ExecuteNonQuery( $Patch.patchContent )
                    New-DbExecutionLog -FilePath $Patch.PatchName -Successful
                }
                Catch
                {
                    $PatchContext.ExecuteNonQuery($PatchContext.Constants.RollbackTransactionScript)
                    New-DbExecutionLog -FilePath $Patch.PatchName 
                    throw $_
                }
            }
        }
    }
}

# ----------------------------------------------------------------------------------
function Add-SqlDbPatches
{
    [CmdletBinding(
        SupportsShouldProcess=$True,ConfirmImpact=’Medium’
    )]
 
    PARAM
    ( [parameter(Mandatory=$True,ValueFromPipeline=$True,Position=0)]
      [system.IO.FileInfo[]]$PatchFiles
    
    , [string]$BeforeEachPatch
    , [string]$AfterEachPatch
    , [switch]$ExecuteOnce
    , [switch]$CheckPoint
    , [string]$FileNamePattern

    , [ValidateSet('Function','View','Procedure')]
      [string]$FileContentPatternTemplate
    , [string]$FileContentPattern

    , [string]$Comment
    , [switch]$Force
    )
 
    Begin
    {
        $SchemaObjectPattern = "(\s*)(((\[(?'schema'[^\]]*))\])|(?'schema'[^\.[\]]*))\.(((\[(?'object'[^\]]*))\])|(?'object'[^ ]*))"
        switch ($FileContentPatternTemplate)
        {
            'Function' 
            {
                $FileContentPattern = "CREATE\s+FUNCTION$SchemaObjectPattern"
                $BeforeEachPatch = @" 
    IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[@(schema)].[@(object)]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION [@(schema)].[@(object)]
"@
                break;
            }

            'View' 
            {
                $FileContentPattern = "CREATE\s+VIEW$SchemaObjectPattern"
                $BeforeEachPatch = @" 
    IF  EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[@(schema)].[@(object)]'))
    DROP VIEW [@(schema)].[@(object)]
"@
                break;
            }

            'Procedure' 
            {
                $FileContentPattern = "CREATE\s+(PROCEDURE|PROC)$SchemaObjectPattern"
                $BeforeEachPatch = @" 
    IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[@(schema)].[@(object)]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [@(schema)].[@(object)]
"@
                break;
            }
        }					
    }
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
                elseif ($QueuedPatches.Where({$_.PatchName -eq $PatchName}))
                {
                    Write-Verbose "`$PatchName ignored because it is already queued"
                }
                else
                {
                    $Checksum = $PatchContext.GetFileChecksum($PatchFile)
                    Write-Verbose "`$Checksum: $Checksum"

                    $PatchCheckSum = [string]($PatchContext.GetChecksumForPatch($PatchName))
            
                    $ApplyPatch = $false
                    if ($Checksum -ne $PatchCheckSum -or $Force)
                    {
                        if ($ExecuteOnce -and ($PatchCheckSum -ne ''))
                        {
                            Write-Warning "Patch $PatchName has changed but will be ignored"
                        }
                        else
                        {
                            $ApplyPatch = $true
                            $BeforeEachPatchStr = ''
                            $AfterEachPatchStr = ''

                            $Patch = $PatchContext.NewPatchObject($PatchFile,$PatchName,$Checksum,$CheckPoint,$Comment,'','')

                            # Annoying use of multiple output
                            # ParseSchemaAndObject verifies match and returns Match Keys.
                            # No keys are a valid result on a match
                            $ObjectKeys = @()
                            if ($FileNamePattern)
                            {
                                Write-Verbose "Evaluate FilenamePattern '$FileNamePattern'"
                                $ApplyPatch, $ObjectKeys = $PatchContext.ParseSchemaAndObject($PatchFile,$FileNamePattern)
                                if (!$ApplyPatch)
                                {
                                    Write-Warning "FileNamePattern does not match patch '$PatchName' - Patch not executed"
                                }
                                else
                                {
                                    $BeforeEachPatchStr = $PatchContext.ReplacePatternValues($BeforeEachPatch, $ObjectKeys)
                                    Write-Verbose "`BeforeEachPatch: $($BeforeEachPatchStr)"
                                    $AfterEachPatchStr = $PatchContext.ReplacePatternValues($AfterEachPatch, $ObjectKeys)
                                    Write-Verbose "`AfterEachPatch: $($AfterEachPatchStr)"
                                }
                            }
                    
                            if ($FileContentPattern -and $ApplyPatch)
                            {
                                Write-Verbose "Evaluate FileContentPattern '$FileContentPattern'"
                                $ApplyPatch, $ObjectKeys = $PatchContext.ParseSchemaAndObject($Patch.PatchContent, $FileContentPattern)
                                if (!$ApplyPatch)
                                {
                                    Write-Warning "FileContentPattern does not match content in patch '$PatchName' - Patch not executed"
                                }
                                else
                                {
                                    $BeforeEachPatchStr = $PatchContext.ReplacePatternValues($BeforeEachPatch, $ObjectKeys)
                                    Write-Verbose "`BeforeEachPatch: $($BeforeEachPatchStr)"
                                    $AfterEachPatchStr = $PatchContext.ReplacePatternValues($AfterEachPatch, $ObjectKeys)
                                    Write-Verbose "`AfterEachPatch: $($AfterEachPatchStr)"
                                }
                            }

                            function GoScript($script)
                            {
                                if ($script)
                                {
                                    $script + "`nGO`n"
                                }
                            }
                            $Patch.PatchContent = (GoScript $PatchContext.Constants.BeginTransctionScript) + 
                                                  (GoScript $BeforeEachPatchStr) + 
                                                  (GoScript (ReplaceTokens $Patch.PatchContent)) + 
                                                  (GoScript $AfterEachPatchStr) + 
                                                  (GoScript $PatchContext.GetMarkPatchAsExecutedString($Patch.PatchName, $Patch.Checksum, '')) +
                                                  (GoScript $PatchContext.Constants.EndTransactionScript)
                        }
                    }
                    else
                    {
                        Write-Verbose "Patch $PatchName current" 
                    }

                    if ($ApplyPatch -or $Force)
                    {
                        [void]$QueuedPatches.Add($Patch) 
                    }
                }
            }
        }
        Catch
        {
            $PatchContext.TerminalError($_)
        }
    }
}

#region License

$LicenseMessage = @"
PsDbDeploy - Powershell Database Deployment for SQL Server Database Updates with coordinated Software releases. 
Copyright (C) 2013-14 Cash Foley Software Consulting LLC
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 https://psdbdeploy.codeplex.com/license
"@
#endregion

# ----------------------------------------------------------------------------------

$PublishWhatIf = $false

$DBPatchContext = @{}

$QueuedPatches = New-Object -TypeName System.Collections.ArrayList

#region Patches_Settings
# ----------------------------------------------------------------------------------
$DefaultConstants = @{
    #-----------------------------------------------------------------------------------------------
    BeginTransctionScript = @"
SET XACT_ABORT ON
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
BEGIN TRANSACTION;
"@
# Useful for Debug
# PRINT N'Transaction Count - ' + CAST (@@TRANCOUNT+1 AS varchar) 

    #-----------------------------------------------------------------------------------------------
    EndTransactionScript = @"
IF @@ERROR <> 0 AND @@TRANCOUNT >  0 WHILE @@TRANCOUNT>0 ROLLBACK TRANSACTION;
WHILE @@TRANCOUNT > 0 COMMIT TRANSACTION;
"@
    RollbackTransactionScript = @"
WHILE @@TRANCOUNT>0 ROLLBACK TRANSACTION;
"@
}
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

# ----------------------------------------------------------------------------------
# function Checkpoint-PatchFile( $PatchName, $Comment='Checkpoint' )
# {
#     $PatchFile = Join-Path $PatchContext.RootFolderPath $PatchName
# 
#     $Checksum = FileChecksum $PatchFile
#     
#     MarkPatchAsExecuted $PatchName $Checksum $Comment
# }
# 
# ----------------------------------------------------------------------------------

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

    process 
    {
        if ($QueuedPatches.Count -eq 0)
        {
            Write-Host -Object '    No Patches to Apply'
            return
        }
        try
        {
            $PatchContext.AssurePsDbDeploy()
            while ($QueuedPatches.Count -gt 0)
            {
                $Patch = $QueuedPatches[0]
                
                $PatchContext.NewSqlCommand()
                if ($Patch.CheckPoint)
                {
                    if ($PSCmdlet.ShouldProcess($Patch.PatchName,'Checkpoint Patch')) 
                    {
                        # Write-Host "Checkpoint (mark as executed) - $($Patch.PatchName)"
                        $PatchContext.MarkPatchAsExecuted($Patch.PatchName, $Patch.Checksum, '')
                    }
                }
                else
                {
                    $WhatIfExecute = $TRUE
                    if ($PSCmdlet.ShouldProcess($Patch.PatchName,'Publish Patch')) 
                    {
                        $WhatIfExecute = $false
                    }
                    PerformPatches $Patch $PatchContext $WhatIfExecute
                }
                $QueuedPatches.RemoveAt(0)
            }
        }
        Catch
        {
            $PatchContext.TerminalError($_)
        }
        $PatchContext.Connection.Close()
    }
}

# ----------------------------------------------------------------------------------

function Add-TokenReplacement 
{
     param
     (
         [Object]
         $TokenValue,

         [Object]
         $ReplacementValue
     )

    $PatchContext.TokenReplacements += @{
        TokenValue       = $TokenValue
        ReplacementValue = $ReplacementValue
    }
}

# ----------------------------------------------------------------------------------

$PatchContext = $null

function Initialize-PsDbDeploy
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
    
    $script:PatchContext = Get-PatchContext -ServerName $ServerName -DatabaseName $DatabaseName -RootFolderPath $RootFolderPath -OutFolderPath $OutFolderPath -Environment $Environment -DefaultConstants $DefaultConstants -DisplayCallStack $DisplayCallStack
    $PatchContext.LogSqlOutScreen = $EchoSql
    $PatchContext.SqlLogFile = $SqlLogFile
    $PatchContext.PublishWhatIf = $PublishWhatIf

    $QueuedPatches = $QueuedPatches.Clear()
    $TokenReplacements = @()

    AssurePsDbDeploy

}


