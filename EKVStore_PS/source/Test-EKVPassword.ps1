<#
.SYNOPSIS
Tests whether a password is the master pasword of an Encrypted Key-Value (EKV) store.

.DESCRIPTION
Checks whether the provided password is the master password of the provided
Encrypted Key-Value store and returns true if successful or false 
otherwise.

.PARAMETER Name
Name of the Encrypted Key-Value store to access.

.PARAMETER Password
Master Password of the Encrypted Key-Value store to test.

.INPUTS
None

.OUTPUTS
Boolean
Flag which indicates whether the provided password is the master password
of the provided EKV store.

.EXAMPLE
Test-EKVPassword -Name testekv -Password $ekvpass

Tests whether provided password is the master password of the EKV store
named "testekv"

.NOTES
To define a Secure String -Password or -Value value use for example:
PS > $ekvpass = Read-Host -AsSecureString
PS > ********
#>
function Test-EKVPassword {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the Encrypted Key-Value store to access")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the Encrypted Key-Value store to test")]
        [securestring] $Password
    )

    $storePath = Get-StorePath -Name $Name -CheckExists
    if ($null -eq $storePath) { return $false }

    $masterPassword = Get-MasterPassword -StorePath $storePath

    $success = Compare-PasswordHashes -MasterPasswordHash $masterPassword.PasswordHash -Password $Password -Salt $masterPassword.Salt
    if (-not $success) {
        Write-Host "Given password is not master password of the $Name EKV store" -ForegroundColor Red
    } else {
        Write-Host "Given password is master password of the $Name EKV store" -ForegroundColor Green
    }

    return $success
}