<#
.SYNOPSIS
Copies an existing Encrypted Key-Value (EKV) store into a new store.

.DESCRIPTION
Checks whether the provided password is the master password of the provided
Encrypted Key-Value store, creates a new Encrypted Key-Value store and
copies the contents of the original to the copy.

.PARAMETER Name
Name of the Encrypted Key-Value store to copy.

.PARAMETER Password
Master Password of the Encrypted Key-Value store to copy.

.PARAMETER CopyName
Name of the new copy Encrypted Key-Value store.

.PARAMETER Force
Flag which forces the command to copy the specified Encrypted Key-Value
store even if the target copy store already exists, overwriting it.

.INPUTS
None

.OUTPUTS
Boolean
Flag which indicates whether the operation was successful.

.EXAMPLE
Copy-EKVStore -Name testekv -Password $ekvpass -CopyName testekv2

Copy the contents of the EKV Store named "testekv" to "testekv2".

.EXAMPLE
Copy-EKVStore -Name testekv -Password $ekvpass -CopyName testekv2 -Force

Copy the contents of the EKV Store named "testekv" to "testekv2" even if
"testekv2" already exists, overwriting all previous existing contents.

.NOTES
To define a Secure String -Password value use for example:
PS > $ekvpass = Read-Host -AsSecureString
PS > ********
#>
function Copy-EKVStore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the Encrypted Key-Value store to copy")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the Encrypted Key-Value store")]
        [securestring] $Password,

        [Parameter(Position=2, HelpMessage="Name of the copy Encrypted Key-Value store")]
        [string] $CopyName = $StoreName + "_copy",

        [Parameter(Position=3, HelpMessage="Force creation of the copied Encrypted Key-Value store")]
        [switch] $Force = $false
    )

    $directoryPath = Get-StoreDirectoryPath
    $storePath = Get-StorePath -Name $Name -CheckExists
    if ($null -eq $storePath) { return $false }

    $masterPassword = Get-MasterPassword -StorePath $storePath
    
    $success = Compare-PasswordHashes -MasterPasswordHash $masterPassword.PasswordHash -Password $Password -Salt $masterPassword.Salt
    if (-not $success) { return $false }
    
    $copyStorePath = Get-StorePath -Name $CopyName -DirectoryPath $directoryPath
    if ($null -eq $copyStorePath) { return }
    $success = $false
    if ($Force) { $success = New-StoreFile -StorePath $copyStorePath -Force } 
    else { $success = New-StoreFile -StorePath $copyStorePath }
    if (-not $success) { return }

    (Get-Content $storePath) | Set-Content $copyStorePath
    Write-Host "Copied contents of $Name to $CopyName Encrypted Key-Value store" -ForegroundColor Green
    return $true
}