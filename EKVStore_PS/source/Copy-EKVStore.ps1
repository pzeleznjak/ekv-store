function Copy-EKVStore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the Encrypted Key-Value store to copy")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the Encrypted Key-Value store")]
        [securestring] $Password,

        [Parameter(Position=2, HelpMessage="Name of the copy Encrypted Key-Value store")]
        [string] $CopyName = $StoreName + "_copy",

        [Parameter(Position=3, HelpMessage="Force creation of the copied Encrypted Key-Value store")]
        [switch] $Force = $false
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
    
    $CopyStorePath = Join-Path $DirectoryPath "$($CopyName).ekv"
    if (-not $Force -and (Test-Path -Path $CopyStorePath)) {
        Write-Error "Encrypted Key-Value store $CopyName already exists"
        return $null
    }
    New-Item -Path $CopyStorePath -ItemType File -Force | Out-Null
    Write-Host "Created new empty Encrypted Key-Value store"

    (Get-Content $StorePath) | Set-Content $CopyStorePath
    Write-Host "Copied contents of $Name to $CopyName Encrypted Key-Value store"
    return $CopyStorePath
}