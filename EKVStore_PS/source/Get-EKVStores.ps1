function Get-EKVStores {
    $DirectoryPath = Join-Path $PSScriptRoot ".ekvs" 
    $Stores = Get-ChildItem $DirectoryPath -File -Filter *.ekv
        | Select-Object -ExpandProperty BaseName
    return $Stores
}