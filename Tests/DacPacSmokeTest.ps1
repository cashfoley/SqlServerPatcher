
Add-Type -TypeDefinition @'
Public Enum SqlDacMajorVersion2
{
    v2008R2,
    v2012,
    v2010,
}
'@
function test([SqlDacMajorVersion2]$version)
{
    Write-Host $version
}

test ([SqlDacMajorVersion2]::v2008R2)
