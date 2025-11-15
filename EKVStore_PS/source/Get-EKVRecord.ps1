function Get-EKVRecord {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the Encrypted Key-Value store to access")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the Encrypted Key-Value store to access")]
        [securestring] $Password,

        [Parameter(Mandatory=$true, Position=2, HelpMessage="Key of the Encrypted Key-Value record to get")]
        [string] $Key
    )

    $DirectoryPath = Join-Path $PSScriptRoot ".ekvs" 
    $StorePath = Join-Path $DirectoryPath "$($Name).ekv"
    if (-Not (Test-Path -Path $StorePath)) {
        Write-Error "Encrypted Key-Value store $Name does not exist"
        return $null
    }

    $FirstLineSplit = (Get-Content -Path $StorePath -TotalCount 1 -Encoding UTF8) -split "\s+"
    $PasswordSaltHash = $FirstLineSplit[0]
    $PasswordSalt = $FirstLineSplit[1]
    
    $Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    try {
        $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($Ptr)
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($Ptr)
    }
    $SaltedPassword = $PlainPassword + $PasswordSalt
    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($SaltedPassword)
    $SHA256 = [System.Security.Cryptography.SHA256]::Create()
    $HashBytes = $SHA256.ComputeHash($Bytes)
    $HashText = ([System.BitConverter]::ToString($HashBytes) -replace "-", "")
    if ($HashText -ne $PasswordSaltHash) {
        Write-Error "Invalid Key-Value store Master Password"
        return $null
    }

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

    $Kdf = [System.Security.Cryptography.Rfc2898DeriveBytes]::new(
        [System.Text.Encoding]::UTF8.GetBytes($PlainPassword), 
        [System.Text.Encoding]::UTF8.GetBytes($PasswordSalt), 
        8192, 
        [System.Security.Cryptography.HashAlgorithmName]::SHA256)
    
    $EncryptionKey = $Kdf.GetBytes(32)
    $EncryptionIv = $Kdf.GetBytes(16)

    $Aes = [System.Security.Cryptography.Aes]::Create()
    $Aes.KeySize = 256
    $Aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $Aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    $Aes.Key = $EncryptionKey
    $Aes.Iv = $EncryptionIV

    $Decryptor = $Aes.CreateDecryptor()
    $DecryptedBytes = $Decryptor.TransformFinalBlock($EncryptedValueBytes, 0, $EncryptedValueBytes.Length)
    $DecryptedValueText = [System.Text.Encoding]::UTF8.GetString($DecryptedBytes)

    Write-Host "Successfully decrypted Encrypted Key-Value under key $Key"
    return $DecryptedValueText
}