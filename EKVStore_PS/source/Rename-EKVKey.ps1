<#
.SYNOPSIS
Renames a Key in an Encrypted Key-Value (EKV) store.

.DESCRIPTION
Checks whether the provided password is the master password of the provided
Encrypted Key-Value store, finds the provided key in given EKV and renames it.

.PARAMETER Name
Name of the Encrypted Key-Value store to access.

.PARAMETER Password
Master Password of the Encrypted Key-Value store to access.

.PARAMETER Key
Key of the Encrypted Key-Value record to rename.

.PARAMETER NewKey
New key of the Encrypted Key-Value record.

.INPUTS
None

.OUTPUTS
Boolean
Flag which indicates whether the operation was successful.

.EXAMPLE
Rename-EKVRecord -Name test -Password $ekvpass -Key testkey1 -NewKey testkey

Renames a key named "testkey1" to "testkey" in an EKV store named "test"-

.NOTES
To define a Secure String -Password or -Value value use for example:
PS > $ekvpass = Read-Host -AsSecureString
PS > ********
#>
function Rename-EKVKey {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the Encrypted Key-Value store to access")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the Encrypted Key-Value store to access")]
        [securestring] $Password,

        [Parameter(Mandatory=$true, Position=2, HelpMessage="Key of the Encrypted Key-Value record to rename")]
        [string] $Key,

        [Parameter(Mandatory=$true, Position=3, HelpMessage="New key of the Encrypted Key-Value record")]
        [string] $NewKey
    )

    $storePath = Get-StorePath -Name $Name -CheckExists
    if ($null -eq $storePath) { return }

    $masterPassword = Get-MasterPassword -StorePath $storePath
       
    $success = Compare-PasswordHashes -MasterPasswordHash $masterPassword.PasswordHash -Password $Password -Salt $masterPassword.Salt
    if (-not $success) { return $null }

    $lines = New-Object System.Collections.Generic.List[string]
    $firstLine = $true
    $found = $false
    foreach ($line in Get-Content -Path $storePath -Encoding UTF8) {
        if ($firstLine) {
            $lines.Add($line)
            $firstLine = $false
            continue
        }
        $split = $line -split '\s+'
        if ($split[0] -eq $Key) {
            $found = $true
            $lines.Add("$NewKey $($split[1])")
            continue
        }
        $lines.Add($line)
    }

    if (-not $found) {
        Write-Host "Key $Key does not exist" -ForegroundColor Red
        return $false
    }

    Set-Content -Path $storePath -Value $lines

    Write-Host "Successfuly renamed key $Key to $NewKey" -ForegroundColor Green
    return $true
}