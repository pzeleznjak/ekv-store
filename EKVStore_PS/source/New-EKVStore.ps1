function New-EKVStore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the new Encrypted Key-Value store to be created")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the new Encrypted Key-Value store")]
        [securestring] $Password,

        [Parameter(Position=3, HelpMessage="Force creation of the copied Encrypted Key-Value store")]
        [switch] $Force = $false
    )

    $DirectoryPath = Join-Path $PSScriptRoot ".ekvs" 
    if (-Not (Test-Path -Path $DirectoryPath)) {
        New-Item -Path $DirectoryPath -ItemType Directory -Force | Out-Null
    }

    $StorePath = Join-Path $DirectoryPath "$($Name).ekv"
    if (-not $Force -and (Test-Path -Path $StorePath)) {
        Write-Error "Encrypted Key-Value store $Name already exists"
        return $null
    }
    New-Item -Path $StorePath -ItemType File -Force | Out-Null
    Write-Host "Created new empty Encrypted Key-Value store"

    $Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    try {
        $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($Ptr)
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($Ptr)
    }

    $SaltBytes = New-Object byte[] 8
    $Rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $Rng.GetBytes($SaltBytes)
    $Rng.Dispose()
    $SaltText = [Convert]::ToBase64String($SaltBytes)
    $SaltedPassword = $PlainPassword + $SaltText

    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($SaltedPassword)
    $SHA256 = [System.Security.Cryptography.SHA256]::Create()
    $HashBytes = $SHA256.ComputeHash($Bytes)
    $HashText = ([System.BitConverter]::ToString($HashBytes) -replace "-", "")
    # $HashText = [System.Text.Encoding]::UTF8.GetString($HashBytes)

    $Record = $HashText + " " + $SaltText
    $Record | Out-File -FilePath $StorePath -Encoding utf8

    return $StorePath
}