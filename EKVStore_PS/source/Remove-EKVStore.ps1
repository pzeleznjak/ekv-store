function Remove-EKVStore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the new Encrypted Key-Value store to be created")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the new Encrypted Key-Value store")]
        [securestring] $Password
    )

    $StorePath = Get-StorePath -Name $Name -CheckExists

    $MasterPassword = Get-MasterPassword -StorePath $StorePath
    
    $Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    try {
        $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($Ptr)
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($Ptr)
    }
    $SaltedPassword = $PlainPassword + $MasterPassword.Salt
    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($SaltedPassword)
    $SHA256 = [System.Security.Cryptography.SHA256]::Create()
    $HashBytes = $SHA256.ComputeHash($Bytes)
    $HashText = ([System.BitConverter]::ToString($HashBytes) -replace "-", "")
    if ($HashText -ne $MasterPassword.PasswordHash) {
        Write-Error "Invalid Key-Value store Master Password"
        return $null
    }

    Write-Host "Are you sure you want to remove Encrypted Key-Value store $Name ? (y/n)" -ForegroundColor Red
    $answer = Read-Host

    if ($answer -notmatch '^[Yy]') {
        Write-Host "Operation cancelled."
        return $null
    }

    $Records = foreach ($Line in (Get-Content $StorePath | Select-Object -Skip 1)) {
        $Parts = $Line -split "\s+"
        $Key = $Parts[0]
        $EncryptedValueHex = $Parts[1]

        $EncryptedValueBytes = for ($i = 0; $i -lt $EncryptedValueHex.Length; $i += 2) { [Convert]::ToByte($EncryptedValueHex.Substring($i,2),16) }

        $Kdf = [System.Security.Cryptography.Rfc2898DeriveBytes]::new(
            [System.Text.Encoding]::UTF8.GetBytes($PlainPassword), 
            [System.Text.Encoding]::UTF8.GetBytes($MasterPassword.Salt), 
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

        $Key, $DecryptedValueText
    }

    Remove-Item $StorePath -Force
    Write-Host "Removed Encrypted Key-Value store $Name"

    return $Records
}