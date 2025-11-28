<#
.SYNOPSIS
Removes an Encrypted Key-Value record form an Encrypted Key-Value (EKV) 
store.

.DESCRIPTION
Checks whether the provided password is the master password of the provided
Encrypted Key-Value store, finds the provided key in given EKV and removes
it along with the associated value.

.PARAMETER Name
Name of the Encrypted Key-Value store to access.

.PARAMETER Password
Master Password of the Encrypted Key-Value store to access.

.PARAMETER Key
Key of the Encrypted Key-Value record to remove.

.INPUTS
None

.OUTPUTS
String
Decrypted value associated with removed key.

.EXAMPLE
Remove-EKVRecord -Name testekv -Password $ekvpass -Key testkey

Removes an EKV record stored under "testkey" in EKV store "testekv".

.NOTES
To define a Secure String -Password value use for example:
PS > $ekvpass = Read-Host -AsSecureString
PS > ********
#>
function Remove-EKVRecord {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the Encrypted Key-Value store to access")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the Encrypted Key-Value store to access")]
        [securestring] $Password,

        [Parameter(Mandatory=$true, Position=2, HelpMessage="Key of the Encrypted Key-Value record to remove")]
        [string] $Key
    )

    $storePath = Get-StorePath -Name $Name -CheckExists
    if ($null -eq $storePath) { return $null }

    $masterPassword = Get-MasterPassword -StorePath $storePath
        
    $success = Compare-PasswordHashes -MasterPasswordHash $masterPassword.PasswordHash -Password $Password -Salt $masterPassword.Salt
    if (-not $success) { return $null }

    $found = $false
    $encryptedValueHex = $null

    $lines = Get-Content $storePath
    $result = foreach ($line in $lines) {
        if (-not $found -and $line -match "^$Key\s+") {
            $found = $true
            $parts = $line -split "\s+", 2
            $encryptedValueHex = $parts[1]
            continue
        }
        $line
    }

    $result | Set-Content $storePath

    if (-not $found) {
        Write-Error "No line with key $Key to remove" -ErrorAction Stop
    }

    if ($null -eq $encryptedValueHex) {
        Write-Error "Encrypted value for key $Key not found" -ErrorAction Stop
    }

    $encryptedValueBytes = for ($i = 0; $i -lt $encryptedValueHex.Length; $i += 2) { [Convert]::ToByte($encryptedValueHex.Substring($i,2),16) }

    try {
        $aes = New-AESObject -Password $Password -Salt $masterPassword.Salt
        $decryptor = $aes.CreateDecryptor()
        $decryptedBytes = $decryptor.TransformFinalBlock($encryptedValueBytes, 0, $encryptedValueBytes.Length)
        $decryptedValueText = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)    
    }
    finally {
        $aes.Dispose()
        $decryptor.Dispose()
    }  

    Write-Host "Successfully deleted key $Key" -ForegroundColor Green
    return $decryptedValueText
}