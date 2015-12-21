

<#

PatchTargetServer

PatchExecutor:
    SqlServer
    MockSqlServer

PatchStore:
    SqlServer
    Json



#>

enum PatchStoreKinds { 
   SqlServer
   Json
   }
   

Class PatchStore {

    Test1()
    {
        Write-Error "Not Implemented"
    }
    Test2()
    {
        Write-Error "Not Implemented"
    }
}

Class JsonPatchStore: PatchStore
{
    [string]Test1()
    {
        return "Do the right thing"
    }

    SqlServerPatchStore([string]$PatchStoreFile)
    {
    
    }
}

Class SqlServerPatchStore: PatchStore
{
    [string]Test1()
    {
        return "Do the right thing"
    }


}


'------'
[PatchStore]$store = [JsonPatchStore]::new('test')

$store.Test1()
$store.Test2()


