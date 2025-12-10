<#
.SYNOPSIS
Gets an Encrypted Key-Value record from an Encrypted Key-Value (EKV) store.

.DESCRIPTION
Checks whether the provided password is the master password of the provided
Encrypted Key-Value store, finds the provided key in given EKV, decrypts
the value stored under it and returns it.

.PARAMETER Name
Name of the Encrypted Key-Value store to access.

.PARAMETER Password
Master Password of the Encrypted Key-Value store to access.

.PARAMETER Key
Key of the Encrypted Key-Value record to get.

.PARAMETER AsSecureString
Flag which indicates that the function must return the decrypted value
as a Secure String as opposed to a plaintext string.
Can not be used with -ToClipboard flag.

.PARAMETER ToClipboard
Flag which ensures that decrypted EKV record is copied to clipboard to be
pasted later.
Can not be used with -AsSecureString flag.

.INPUTS
None

.OUTPUTS
String
Decrypted value stored under a key as a plaintext string.
SecureString
Decrypted value stored under a key as a SecureString.
null
Unsuccessful operation.

.EXAMPLE
Get-EKVRecord -Name testekv -Password $ekvpass -Key testkey

Get a value stored under "testkey" in EKV store "testekv" as a plaintext
string.

.EXAMPLE
Get-EKVRecord -Name testekv -Password $ekvpass -Key testkey -ToClipboard

Get a value stored under "testkey" in EKV store "testekv" as a plaintext
string and copy it to clipboard.

.EXAMPLE
Get-EKVRecord -Name testekv -Password $ekvpass -Key testkey -AsSecureString

Get a value stored under "testkey" in EKV store "testekv" as a Secure
String.

.NOTES
To define a Secure String -Password or -Value value use for example:
PS > $ekvpass = Read-Host -AsSecureString
PS > ********
#>
function Get-EKVRecord {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the Encrypted Key-Value store to access")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the Encrypted Key-Value store to access")]
        [securestring] $Password,

        [Parameter(Mandatory=$true, Position=2, HelpMessage="Key of the Encrypted Key-Value record to get")]
        [string] $Key,

        [Parameter(ParameterSetName='SecureStringSet', HelpMessage="Return Encrypted Value as SecureString")]
        [switch] $AsSecureString = $false,

        [Parameter(ParameterSetName='ClipboardSet', HelpMessage="Add Encrypted Key-Value record decrypted value to clipboard")]
        [switch] $ToClipboard = $false
    )

    $storePath = Get-StorePath -Name $Name -CheckExists
    if ($null -eq $storePath) { return }

    $masterPassword = Get-MasterPassword -StorePath $storePath
       
    $success = Compare-PasswordHashes -MasterPasswordHash $masterPassword.PasswordHash -Password $Password -Salt $masterPassword.Salt
    if (-not $success) { return $null }

    $encryptedValueHex = $null
    foreach ($line in Get-Content -Path $storePath -Encoding UTF8 | Select-Object -Skip 1) {
        $split = $line -split '\s+'
        if ($split[0] -eq $Key) {
            $encryptedValueHex = $split[1]
            break;
        }
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
    

    Write-Host "Successfully decrypted Encrypted Key-Value under key $Key" -ForegroundColor Green

    if ($AsSecureString) {

        $secureDecryptedValueText = $decryptedValueText | ConvertTo-SecureString -AsPlainText -Force
        Set-Clipboard $secureDecryptedValueText
        return $secureDecryptedValueText
    }

    Set-Clipboard $decryptedValueText
    return $decryptedValueText
}