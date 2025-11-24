function Get-EKVStores {
    $DirectoryPath = Get-StoreDirectoryPath
    $Stores = Get-ChildItem $DirectoryPath -File -Filter *.ekv
        | Select-Object -ExpandProperty BaseName
    return $Stores
}