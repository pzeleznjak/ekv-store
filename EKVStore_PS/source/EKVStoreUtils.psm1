function Get-StoreDirectoryPath {
    [OutputType([string])]
    param()
    return Join-Path $PSScriptRoot ".ekvs" 
}

function Get-StorePath{
    [OutputType([string], [System.Nullable])]
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the new Encrypted Key-Value store to be created")]
        [string] $Name,

        [Parameter(Position=1, HelpMessage="Directory where Encrypted Key-Value stores are located")]
        [string] $DirectoryPath = "",

        [Parameter(Position=2, HelpMessage="Check existance of store path")]
        [switch] $CheckExists = $false
    )

    if ($DirectoryPath -eq "") {
        $DirectoryPath = Get-StoreDirectoryPath
    }

    $storePath = Join-Path $DirectoryPath "$($Name).ekv"
    if ($CheckExists -and -not (Test-Path -Path $storePath)) {
        Write-Host "Encrypted Key-Value store $Name does not exist" -ForegroundColor Red
        return $null
    }
    return $storePath
}

function New-StoreFile {
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Path to new Encrypted Key-Value store file")]
        [string] $StorePath,

        [Parameter(Position=1, HelpMessage="Force creation of the copied Encrypted Key-Value store")]
        [switch] $Force = $false
    )

    if (-not $Force -and (Test-Path -Path $StorePath)) {
        Write-Host "Encrypted Key-Value store already exists" -ForegroundColor Red
        return $false
    }
    New-Item -Path $StorePath -ItemType File -Force | Out-Null
    Write-Host "Created new empty Encrypted Key-Value store"
    return $true
}

class MasterPassword {
    [string] $PasswordHash
    [string] $Salt
}

function Get-MasterPassword {
    [OutputType([MasterPassword])]
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Path to Encrypted Key-Value store file")]
        [string] $StorePath
    )

    $firstLineSplit = (Get-Content -Path $StorePath -TotalCount 1 -Encoding UTF8) -split "\s+"
    return [MasterPassword]@{
        PasswordHash = $firstLineSplit[0]
        Salt = $firstLineSplit[1]
    }
}

function ConvertTo-PlainString {
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Secure string to convert to plain string")]
        [securestring] $Secure,

        [Parameter(Position=1, HelpMessage="Dispose the secure string after converting")]
        [switch] $Dispose = $false
    )

    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
    try {
        return [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
        if ($Dispose) {
            $Secure.Dispose()
        }
    }
}

function Get-SHA256HashHex {
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Text for which to calculate SHA256 Hash Hex")]
        [string] $Text
    )

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $sha256.ComputeHash($bytes)
    }
    finally {
        $sha256.Dispose()
    }
    # return [System.Text.Encoding]::UTF8.GetString($HashBytes)
    return [System.BitConverter]::ToString($hashBytes) -replace "-", ""
}

function Compare-PasswordHashes {
    [System.Diagnostics.CodeAnalysis.SuppressMessage("PSAvoidUsingPlainTextForPassword", "", Justification = "Hashed value is safe to use as a string")]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Hashed master password")]
        [string] $MasterPasswordHash,
        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master password")]
        [securestring] $Password,
        [Parameter(Mandatory=$true, Position=2, HelpMessage="Master password salt")]
        [string] $Salt
    )

    $plainPassword = ConvertTo-PlainString -Secure $Password
    $saltedPassword = $plainPassword + $Salt
    $hashText = Get-SHA256HashHex -Text $saltedPassword
    if ($hashText -ne $MasterPasswordHash) {
        Write-Host "Invalid Key-Value store Master Password" -ForegroundColor Red
        return $false
    }
    return $true
}

function New-AESObject {
    [OutputType([System.Security.Cryptography.Aes])]
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Master password used as key for AES encryption/decryption")]
        [securestring] $Password,
        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master password salt")]
        [string] $Salt
    )

    $plainPassword = ConvertTo-PlainString -Secure $Password

    $kdf = [System.Security.Cryptography.Rfc2898DeriveBytes]::new(
        [System.Text.Encoding]::UTF8.GetBytes($plainPassword), 
        [System.Text.Encoding]::UTF8.GetBytes($Salt), 
        8192, 
        [System.Security.Cryptography.HashAlgorithmName]::SHA256)
    
    $encryptionKey = $kdf.GetBytes(32)
    $encryptionIv = $kdf.GetBytes(16)

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.KeySize = 256
    $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    $aes.Key = $encryptionKey
    $aes.Iv = $encryptionIv

    return $aes
}