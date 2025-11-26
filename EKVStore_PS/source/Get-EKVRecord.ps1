function Get-EKVRecord {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the Encrypted Key-Value store to access")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the Encrypted Key-Value store to access")]
        [securestring] $Password,

        [Parameter(Mandatory=$true, Position=2, HelpMessage="Key of the Encrypted Key-Value record to get")]
        [string] $Key,

        [Parameter(HelpMessage="Return Encrypted Value as SecureString")]
        [switch] $AsSecureString = $false
    )

    $StorePath = Get-StorePath -Name $Name -CheckExists
    if ($null -eq $StorePath) { return }

    $MasterPassword = Get-MasterPassword -StorePath $StorePath
       
    $success = Compare-PasswordHashes -MasterPasswordHash $MasterPassword.PasswordHash -Password $Password -Salt $MasterPassword.Salt
    if (-not $success) { return $null }

    $EncryptedValueHex = $null
    foreach ($Line in Get-Content -Path $StorePath -Encoding UTF8 | Select-Object -Skip 1) {
        $Split = $Line -split '\s+'
        if ($Split[0] -eq $Key) {
            $EncryptedValueHex = $Split[1]
            break;
        }
    }

    if ($null -eq $EncryptedValueHex) {
        Write-Error "Encrypted value for key $Key not found"
        return $null
    }

    $EncryptedValueBytes = for ($i = 0; $i -lt $EncryptedValueHex.Length; $i += 2) { [Convert]::ToByte($EncryptedValueHex.Substring($i,2),16) }

    try {
        $Aes = New-AESObject -Password $Password -Salt $MasterPassword.Salt
        $Decryptor = $Aes.CreateDecryptor()
        $DecryptedBytes = $Decryptor.TransformFinalBlock($EncryptedValueBytes, 0, $EncryptedValueBytes.Length)
        $DecryptedValueText = [System.Text.Encoding]::UTF8.GetString($DecryptedBytes)    
    }
    finally {
        $Aes.Dispose()
        $Decryptor.Dispose()
    }
    

    Write-Host "Successfully decrypted Encrypted Key-Value under key $Key"

    if ($AsSecureString) {
        return $DecryptedValueText | ConvertTo-SecureString -AsPlainText -Force
    }

    return $DecryptedValueText
}