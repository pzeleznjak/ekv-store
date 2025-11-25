function Get-StoreDirectoryPath {
    return Join-Path $PSScriptRoot ".ekvs" 
}

function Get-StorePath{
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

    $StorePath = Join-Path $DirectoryPath "$($Name).ekv"
    if ($CheckExists -and -not (Test-Path -Path $StorePath)) {
        Write-Error "Encrypted Key-Value store $Name does not exist"
        return $null
    }
    return $StorePath
}

function New-StoreFile {
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Path to new Encrypted Key-Value store file")]
        [string] $StorePath,

        [Parameter(Position=1, HelpMessage="Force creation of the copied Encrypted Key-Value store")]
        [switch] $Force = $false
    )

    if (-not $Force -and (Test-Path -Path $StorePath)) {
        Write-Error "Encrypted Key-Value store $Name already exists"
        return $false
    }
    New-Item -Path $StorePath -ItemType File -Force | Out-Null
    Write-Host "Created new empty Encrypted Key-Value store"
    return $true
}

function Get-MasterPassword {
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Path to Encrypted Key-Value store file")]
        [string] $StorePath
    )

    $FirstLineSplit = (Get-Content -Path $StorePath -TotalCount 1 -Encoding UTF8) -split "\s+"
    return [PSCustomObject]@{
        PasswordHash = $FirstLineSplit[0]
        Salt = $FirstLineSplit[1]
    }
}

function ConvertTo-PlainString {
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Secure string to convert to plain string")]
        [securestring] $Secure,

        [Parameter(Position=1, HelpMessage="Dispose the secure string after converting")]
        [switch] $Dispose = $false
    )

    $Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
    try {
        return [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($Ptr)
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($Ptr)
        if ($Dispose) {
            $Secure.Dispose()
        }
    }
}

function Get-SHA256HashHex {
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Text for which to calculate SHA256 Hash Hex")]
        [string] $Text
    )

    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $SHA256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $HashBytes = $SHA256.ComputeHash($Bytes)
    }
    finally {
        $SHA256.Dispose()
    }
    # return [System.Text.Encoding]::UTF8.GetString($HashBytes)
    return [System.BitConverter]::ToString($HashBytes) -replace "-", ""
}

function Compare-PasswordHashes {
    [System.Diagnostics.CodeAnalysis.SuppressMessage("PSAvoidUsingPlainTextForPassword", "", Justification = "Hashed value is safe to use as a string")]
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Hashed master password")]
        [string] $MasterPasswordHash,
        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master password")]
        [securestring] $Password,
        [Parameter(Mandatory=$true, Position=2, HelpMessage="Master password salt")]
        [string] $Salt
    )

    $PlainPassword = ConvertTo-PlainString -Secure $Password
    $SaltedPassword = $PlainPassword + $Salt
    $HashText = Get-SHA256HashHex -Text $SaltedPassword
    if ($HashText -ne $MasterPasswordHash) {
        Write-Error "Invalid Key-Value store Master Password"
        return $false
    }
    return $true
}