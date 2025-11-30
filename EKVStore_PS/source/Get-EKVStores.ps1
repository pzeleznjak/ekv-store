<#
.SYNOPSIS
Gets all Encrypted Key-Value (EKV) stores.

.DESCRIPTION
Gets all Encrypted Key-Value (EKV) store names.

.INPUTS
None

.OUTPUTS
List<String>
List of all EKV store names.

.EXAMPLE
Get-EKVStores

Lists all EKV store names.
#>
function Get-EKVStores {
    [CmdletBinding()]
    param()
    $directoryPath = Get-StoreDirectoryPath
    $stores = Get-ChildItem $directoryPath -File -Filter *.ekv
        | Select-Object -ExpandProperty BaseName
    return $stores
}