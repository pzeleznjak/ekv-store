function Add-EKVRecord {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the Encrypted Key-Value store to access")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the Encrypted Key-Value store to access")]
        [securestring] $Password,

        [Parameter(Mandatory=$true, Position=2, HelpMessage="Key of the Encrypted Key-Value record to add")]
        [string] $Key,

        [Parameter(Mandatory=$true, Position=3, HelpMessage="Value of the Encrypted Key-Value record to add")]
        [string] $Value
    )

    $StorePath = Get-StorePath -Name $Name -CheckExists
    if ($null -eq $StorePath) { return $null }

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

    $ValueBytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
    
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

    $Encryptor = $Aes.CreateEncryptor()
    $EncryptedValueBytes = $Encryptor.TransformFinalBlock($ValueBytes, 0, $ValueBytes.Length)
    $EncryptedValueText = [System.BitConverter]::ToString($EncryptedValueBytes) -replace "-", ""

    $Record = $Key + " " + $EncryptedValueText
    $Record | Out-File -FilePath $StorePath -Encoding utf8 -Append

    Write-Host "Successfully added Encrypted Key-Value under key $Key"

    return $Key
}