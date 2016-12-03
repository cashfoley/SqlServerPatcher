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

#region Data Load Functions
# ----------------------------------------------------------------------------------------------
# Generates SQL to Disable or Enable FKs to all XmlDataInfos
function Get-FKSql($command, $XmlDataFiles, [switch]$Disable)
{
    if ($Disable)
    {
        $CheckStr = "NOCHECK"
        $ActionMessages = "Disable","for"
    }
    else
    {
        $CheckStr = "WITH CHECK CHECK"
        $ActionMessages = "Enable","After"
    }

    "PRINT N'################################################################################'"
    "PRINT N'   $($ActionMessages[0]) FK Constraints $($ActionMessages[1]) Datatable Load'"
    "PRINT N'################################################################################'`n"
    foreach ($XmlDataFile in $XmlDataFiles)
    {
        $XmlDataInfo = parse-schemaname $XmlDataFile
        $command.CommandText = $FksToTableQuery -f $XmlDataInfo.schema,$XmlDataInfo.object
        "PRINT N'------------------------------------------------'"
        "`nPRINT N'$($ActionMessages[0]) FKs to {0}.{1}'" -f $XmlDataInfo.schema,$XmlDataInfo.object
        $sqlReader = $command.ExecuteReader()
        try
        {
            while ($sqlReader.Read()) 
            { 
                $TargetTableSchema = $sqlReader["Table_Schema"]
                $TargetTableName = $sqlReader["Table_Name"]
                $TargetTableConstraintName = $sqlReader["Constraint_Name"]
		        "PRINT N'{3} FK {2} on {0}.{1}'" -f $TargetTableSchema,$TargetTableName,$TargetTableConstraintName, $($ActionMessages[0])

		        "ALTER TABLE {0}.{1} {3} CONSTRAINT {2}`nGO`n" -f $TargetTableSchema,$TargetTableName,$TargetTableConstraintName, $CheckStr
            }
        }
        finally
        {
            $sqlReader.Close()
        }
    }
}

Export-ModuleMember -Function Get-FKSql

# ----------------------------------------------------------------------------------------------

function parse-schemaname
{
    param ([System.IO.FileInfo]$fileInfo)

    $filename = $fileInfo.Name

    if ($filename -match "^((?'schema'[^.]*)\.)?(?'object'[^.]*)\.xml$")
    {
        @{schema= $Matches['schema'];object=$Matches['object'];filename=$filename;fullname=$fileInfo.FullName}
    }
    else
    {
        Throw "Filename '$filename' is not in the form of '(<schema>.)<object>.xml'"
    }
}


function Get-XmlDeleteAndInsert($command, $xmlDataInfo,[switch]$IncludTimestamps)
{

}

class DbObjectName
{
    # private 
    hidden [int]$IncrementFactor
    # public Property
    [int]$Index

    [string]$schema
    [string]$object
    [string]$filename
    [string]$fullFileName
   
    # Constructor
    NewClass([System.IO.FileInfo]$fileInfo)
    {
        $this.filename= $fileInfo.Name
        $this.fullname= $fileInfo.FullName

        if (!($this.filename -match "^((?'schema'[^.]*)\.)?(?'object'[^.]*)\.xml$"))
        {
            Throw "Filename '$($this.filename)' is not in the form of '(<schema>.)<object>.xml'"
        }
        $this.schema= $Matches['schema']
        $this.object= $Matches['object']
    }
   
#     # Method
#     [void] Increment() {
#     $this.Index += $this.IncrementFactor
#     }
#       
#     [void] SetIncrementFactor([int]$NewFactor)
#     {
#     $this.IncrementFactor = $NewFactor
#     }
#       
#     [int] GetIncrementFactor()
#     {
#     return $this.IncrementFactor
#     }
}

# instantiate class
$myClass = [NewClass]::new()

# use properties and methods
$myClass.Index
$myClass.Increment()
$myClass.Index

$myClass.SetIncrementFactor(15)
$myClass.GetIncrementFactor()
$myClass.Index
$myClass.Increment()
$myClass.Index


# ----------------------------------------------------------------------------------------------
function Get-XmlInsertSql($command, $XmlDataFiles,[switch]$IncludTimestamps)
{
    "PRINT N'################################################################################'"
    "PRINT N'   Table Data Load'"
    "PRINT N'################################################################################'`n"
    foreach ($XmlDataFile in $XmlDataFiles)
    {
        $XmlDataInfo = parse-schemaname $XmlDataFile
        $TableFullName = "[{0}].[{1}]" -f $XmlDataInfo.schema,$XmlDataInfo.object
        $ColumnNames = @()
        $ColumnDataTypes = @()
        $command.CommandText = $TableDefinitionSQL -f $XmlDataInfo.schema,$XmlDataInfo.object
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
        "--   Load [{0}].[{1}]`n" -f $XmlDataInfo.schema,$XmlDataInfo.object
        "------------------------------------------------------------------------------`n"
                
        "PRINT N'DELETE all rows FROM $TableFullName'"
        "DELETE FROM $TableFullName`n"

        $xmlData = Get-Content $XmlDataInfo.fullname | Out-String | %{$_.Replace("'","''")}
        $LoadXmlDocumentSQL -f $xmlData.trim()

        $command.CommandText = $TableHasIdentity -f $XmlDataInfo.schema,$XmlDataInfo.object
        $HasIdentity = $command.ExecuteScalar()
        if ($HasIdentity -gt 0)
        {
            "SET IDENTITY_INSERT $TableFullName ON`n"
        }

        $InsertColumnNames = $ColumnNames -join "`n     , "
        $InsertColumnDefs  = $ColumnDataTypes -join "`n     , "
        $InsertXmlDataSQL -f $XmlDataInfo.schema, $XmlDataInfo.object, $InsertColumnNames, $InsertColumnDefs

        if ($HasIdentity -gt 0)
        {
            "SET IDENTITY_INSERT $TableFullName OFF"
        }
        "PRINT N'---------------------------------------------'"
        "GO`n"
    }
}

Export-ModuleMember -Function Get-XmlInsertSql

#endregion


