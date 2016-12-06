$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2

# ----------------------------------------------------------------------------------
$QueriesRegexOptions = "IgnorePatternWhitespace,Singleline,IgnoreCase,Multiline,Compiled"
$QueriesExpression = "((?'Query'(?:(?:/\*.*?\*/)|.)*?)(?:^\s*go\s*$))*(?'Query'.*)"
$QueriesRegex = New-Object System.Text.RegularExpressions.Regex -ArgumentList ($QueriesExpression, [System.Text.RegularExpressions.RegexOptions]$QueriesRegexOptions)


#region Data Load Queries
# ----------------------------------------------------------------------------------------------
# Query to get all the FKs going to the Target Table
$FksToTableQuery = @"
SELECT QUOTENAME(ctu.Table_Schema) Table_Schema
     , QUOTENAME(ctu.Table_Name) Table_Name
     , QUOTENAME(rc.Constraint_Name) Constraint_Name
  FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
       JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
         ON tc.Constraint_Name = rc.Unique_Constraint_Name AND tc.Constraint_Schema = rc.Constraint_Schema
       JOIN INFORMATION_SCHEMA.CONSTRAINT_TABLE_USAGE ctu
         ON rc.Constraint_Name = ctu.Constraint_Name AND rc.Constraint_Schema = ctu.Constraint_Schema
 WHERE tc.table_schema = '{0}'
   AND tc.table_name = '{1}'
"@

# ----------------------------------------------------------------------------------------------
# Query to get Table Definition from Info Schema
$TableDefinitionSQL = @"
SELECT Column_Name
     , Data_Type
     , Character_Maximum_Length
  FROM INFORMATION_SCHEMA.COLUMNS
 WHERE Table_Schema = N'{0}'
   AND Table_Name = N'{1}'
 ORDER BY Ordinal_Position
"@

# ----------------------------------------------------------------------------------------------
# Scalar Query to determine if Table has Identity Column
$TableHasIdentity = @"
	SELECT Count(*)
	  FROM sys.tables AS t
	  JOIN sys.identity_columns ic ON t.object_id = ic.object_id
	 WHERE t.name = N'{1}'
	   AND SCHEMA_NAME(schema_id) = N'{0}'
"@

# ----------------------------------------------------------------------------------------------
# SQL to load a prepared XML document.  It is then accessed through OPENXML
$LoadXmlDocumentSQL = @"
DECLARE @XmlDocument nvarchar(max)
SET @XmlDocument = N'<ROOT>
{0}
</ROOT>'

DECLARE @DocHandle  int
EXEC sp_xml_preparedocument @DocHandle OUTPUT, @XmlDocument
"@

# ----------------------------------------------------------------------------------------------
# SQL to insert Prepared OPENXML document into a Table
$InsertXmlDataSQL = @"
PRINT N'INSERT XML Data INTO [{0}].[{1}]'
INSERT 
  INTO [{0}].[{1}]
     ( {2} 
     )
SELECT {2}
  FROM OPENXML (@DocHandle, '/ROOT/{0}.{1}',1) 
  WITH 
     ( {3}
     )

EXEC sp_xml_removedocument @DocHandle

"@

#endregion

##############################################################################################################

class XmlDataFile
{
    # private 
    #hidden [int]$aVar
    
    # public Property

    [string]$Schema
    [string]$TableName

    [string]$Filename
    [string]$FullFilename
    [string]$TableFullName
   
    # Constructor
    # --------------------------------------------------------------------
    XmlDataFile([System.IO.FileInfo]$fileInfo)
    {
        $this.Filename= $fileInfo.Name
        $this.FullFilename = $fileInfo.FullName

        if (!($this.Filename -match "^((?'schema'[^.]*)\.)?(?'TableName'[^.]*)\.xml$"))
        {
            Throw "Filename '$($this.Filename)' is not in the form of '(<schema>.)<TableName>.xml'"
        }
        $this.Schema= $Matches['schema']
        $this.TableName= $Matches['TableName']
        $this.TableFullName = "[{0}].[{1}]" -f $this.Schema, $this.TableName
    }

    # --------------------------------------------------------------------
    [string] FileContent()
    {
        return (Get-Content $this.FullFilename | Out-String | %{$_.Replace("'","''")}).trim()
    }
}

##############################################################################################################
class FksToTable
{

    hidden [string] $AlterFkStr = @"
PRINT N'{4} FK {2} on {0}.{1}'
ALTER TABLE {0}.{1} {3} CONSTRAINT {2}
GO

"@

    hidden [string] $BannerMsgStr =@"
------------------------------------------------------------------------------------------------------
--  {0} FK Constraints to {1}
------------------------------------------------------------------------------------------------------

"@

    [XmlDataFile]$XmlDataFile
    [array]$ForeignKeys

    # Constructor
    # --------------------------------------------------------------------
    FksToTable([System.Data.Common.DbConnection]$Connection,[XmlDataFile]$XmlDataFile,$FksToTableQuery)
    {
        [System.Data.SqlClient.sqlCommand]$command = New-Object System.Data.SqlClient.sqlCommand
        $command.Connection = $Connection 
        $command.CommandText = $FksToTableQuery -f $xmlDataFile.Schema,$xmlDataFile.TableName

        $this.xmlDataFile = $xmlDataFile

        $sqlReader = $command.ExecuteReader()
        $this.ForeignKeys = @()
        try
        {
            while ($sqlReader.Read()) 
            { 
                $fk = @{}
                $fk.Schema         = $sqlReader["Table_Schema"]
                $fk.TableName      = $sqlReader["Table_Name"]
                $fk.ConstraintName = $sqlReader["Constraint_Name"]
                $this.ForeignKeys += $fk
            }
        }
        finally
        {
            $sqlReader.Close()
        }
    }
    
    # --------------------------------------------------------------------
    hidden [string] GenerateFKs($ActionStr,$CheckString)
    {
        $result = @()
        $result = $this.BannerMsgStr -f $ActionStr, $this.XmlDataFile.TableFullName
        foreach ($fk in $this.ForeignKeys)
        {
            $result += $this.AlterFkStr -f $fk.Schema, $fk.TableName, $fk.ConstraintName, $CheckString, $ActionStr
        }
        return $result
    }

    # --------------------------------------------------------------------
    [string] GetEnableFKsSql()
    {
        return $this.GenerateFKs('Enable','WITH CHECK CHECK')
    }
    [string] GetDisableFKsSql()
    {
        return $this.GenerateFKs('Disable','NOCHECK')
    }
}

# ----------------------------------------------------------------------------------------------

#region Data Load Functions
##############################################################################################################
# Generates SQL to Disable or Enable FKs to all XmlDataInfos
function Get-FKSql($connection, $XmlDataFiles, [switch]$Disable)
{
    foreach ($XmlDataFile in $XmlDataFiles)
    {
        $FksToTable = [FksToTable]::new($connection,$XmlDataFile,$FksToTableQuery)
        if ($Disable)
        {
            $FksToTable.GetDisableFKsSql()
        }
        else
        {
            $FksToTable.GetEnableFKsSql()
        }
    }
}

Export-ModuleMember -Function Get-FKSql

##############################################################################################################
function Get-XmlInsertSql($connection, $XmlDataFiles,[switch]$IncludTimestamps)
{
    $command = New-Object System.Data.SqlClient.sqlCommand
    $command.Connection = $connection 

    "PRINT N'################################################################################'"
    "PRINT N'   Table Data Load'"
    "PRINT N'################################################################################'`n"
    foreach ($XmlDataFile in $XmlDataFiles)
    {
        $xmlDataFile = [XmlDataFile]::new($XmlDataFile)

        $ColumnNames = @()
        $ColumnDataTypes = @()
        $command.CommandText = $TableDefinitionSQL -f $xmlDataFile.Schema,$xmlDataFile.TableName
        $sqlReader = $command.ExecuteReader()
        try
        {
            while ($sqlReader.Read()) 
            { 
                if ($IncludTimestamps -or ($sqlReader["Data_Type"] -ne 'TIMESTAMP'))
                {
                    $ColumnName = "[" + $sqlReader["Column_Name"] +"]"
                    $ColumnDataType = $sqlReader["Data_Type"]
                    $ColumnCharacterMaximumLength = $sqlReader["Character_Maximum_Length"]
                    
                    $ColumnNames += $ColumnName

                    if (($ColumnCharacterMaximumLength -is [System.DBNull]) -or ($ColumnDataType -in @('image','ntext','text')))
                    { 
                        $ColumnDataLength = ''
                    }
                    elseif ($ColumnCharacterMaximumLength -eq -1) 
                    {
                        $ColumnDataLength = '(MAX)'
                    }
                    else 
                    {
                        $ColumnDataLength = "($ColumnCharacterMaximumLength)"
                    }

                    $ColumnDataTypes += "{0} {1}{2}" -f $ColumnName,$ColumnDataType,$ColumnDataLength
                }
            }
        }
        finally
        {
            $sqlReader.Close()
        }
        "------------------------------------------------------------------------------`n"
        "--   Load $($xmlDataFile.TableFullName)`n" 
        "------------------------------------------------------------------------------`n"
                
        "PRINT N'DELETE all rows FROM $($xmlDataFile.TableFullName)'"
        "DELETE FROM $($xmlDataFile.TableFullName)`n"

        $LoadXmlDocumentSQL -f $xmlDataFile.FileContent()

        $command.CommandText = $TableHasIdentity -f $xmlDataFile.Schema,$xmlDataFile.TableName
        $HasIdentity = $command.ExecuteScalar()
        if ($HasIdentity -gt 0)
        {
            "SET IDENTITY_INSERT $($xmlDataFile.TableFullName) ON`n"
        }

        $InsertColumnNames = $ColumnNames -join "`n     , "
        $InsertColumnDefs  = $ColumnDataTypes -join "`n     , "
        $InsertXmlDataSQL -f $xmlDataFile.Schema, $xmlDataFile.TableName, $InsertColumnNames, $InsertColumnDefs

        if ($HasIdentity -gt 0)
        {
            "SET IDENTITY_INSERT $($xmlDataFile.TableFullName) OFF"
        }
        "PRINT N'---------------------------------------------'"
        "GO`n"
    }
}

Export-ModuleMember -Function Get-XmlInsertSql

#endregion


