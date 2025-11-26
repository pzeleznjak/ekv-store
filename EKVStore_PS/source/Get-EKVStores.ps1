function Get-EKVStores {
    $directoryPath = Get-StoreDirectoryPath
    $stores = Get-ChildItem $directoryPath -File -Filter *.ekv
        | Select-Object -ExpandProperty BaseName
    return $stores
}