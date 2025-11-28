<#
.SYNOPSIS
Gets all keys in Encrypted Key-Value store (EKV).

.DESCRIPTION
Checks whether the provided password is the master password of the provided
Encrypted Key-Value store and lists all stored keys.

.PARAMETER Name
Name of the Encrypted Key-Value store to access.

.PARAMETER Password
Master Password of the Encrypted Key-Value store to access.

.INPUTS
None

.OUTPUTS
List<string>
All keys stored in the EKV store.

.EXAMPLE
Get-EKVKeys -Name testekv -Password $ekvpass

List all keys in EKV named testekv.

.NOTES
To define a Secure String -Password value use for example:
PS > $ekvpass = Read-Host -AsSecureString
PS > ********
#>
function Get-EKVKeys {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the Encrypted Key-Value store to access")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the Encrypted Key-Value store to access")]
        [securestring] $Password
    )

    $storePath = Get-StorePath -Name $Name -CheckExists
    if ($null -eq $storePath) { return }

    $masterPassword = Get-MasterPassword -StorePath $storePath
    
    $success = Compare-PasswordHashes -MasterPasswordHash $masterPassword.PasswordHash -Password $Password -Salt $masterPassword.Salt
    if (-not $success) { return $null }

    $keys = Get-Content -Path $storePath -Encoding UTF8 | Select-Object -Skip 1 | ForEach-Object { ($_ -split "\s+")[0] }
    return $keys
}