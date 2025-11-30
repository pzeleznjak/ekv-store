<#
.SYNOPSIS
Renames an Encrypted Key-Value (EKV) store.

.DESCRIPTION
Checks whether the provided password is the master password of the provided
Encrypted Key-Value store, and renames it to new provided name.

.PARAMETER Name
Original name of the Encrypted Key-Value store to rename.

.PARAMETER Password
Master Password of the Encrypted Key-Value store to rename.

.PARAMETER NewName
New name of the Encrypted Key-Value Store.

.INPUTS
None

.OUTPUTS
Boolean
Flag which indicates whether the operation was successful.

.EXAMPLE
Rename-EKVStore -Name test -Password $ekvpass -NewName test2

Rename an EKV Store with name "test" to "test2".

.NOTES
To define a Secure String -Password or -Value value use for example:
PS > $ekvpass = Read-Host -AsSecureString
PS > ********
#>
function Rename-EKVStore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Original name of the Encrypted Key-Value store to rename")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the Encrypted Key-Value store to rename")]
        [securestring] $Password,

        [Parameter(Mandatory=$true, Position=2, HelpMessage="New name of the Encrypted Key-Value Store")]
        [string] $NewName
    )
    
    $storePath = Get-StorePath -Name $Name -CheckExists
    if ($null -eq $storePath) { return $false }

    $masterPassword = Get-MasterPassword -StorePath $storePath

    $success = Compare-PasswordHashes -MasterPasswordHash $masterPassword.PasswordHash -Password $Password -Salt $masterPassword.Salt
    if (-not $success) { return $false }

    $newStorePath = Get-StorePath -Name $NewName

    Rename-Item -Path $storePath -NewName $newStorePath

    Write-Host "Successfully renamed EKV store $Name to $NewName" -ForegroundColor Green
    return $true
}