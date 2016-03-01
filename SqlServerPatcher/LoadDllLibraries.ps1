$DacpacDllPath = 'C:\Program Files (x86)\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\120'
$SqlDacDll = Join-Path $dacpacDllPath 'Microsoft.SqlServer.Dac.dll'
add-type -path $SqlDacDll
