function Get-EKVKeys {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the Encrypted Key-Value store to access")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the Encrypted Key-Value store to access")]
        [securestring] $Password
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

    $Keys = Get-Content -Path $StorePath -Encoding UTF8 | Select-Object -Skip 1 | ForEach-Object { ($_ -split "\s+")[0] }
    return $Keys
}