function New-EKVStore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the new Encrypted Key-Value store to be created")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the new Encrypted Key-Value store")]
        [securestring] $Password,

        [Parameter(Position=2, HelpMessage="Force creation of the copied Encrypted Key-Value store")]
        [switch] $Force = $false
    )

    $DirectoryPath = Get-StoreDirectoryPath
    if (-not (Test-Path -Path $DirectoryPath)) {
        New-Item -Path $DirectoryPath -ItemType Directory -Force | Out-Null
    }
    $StorePath = Get-StorePath -Name $Name -DirectoryPath $DirectoryPath
    $success = $false
    if ($Force) { $success = New-StoreFile -StorePath $StorePath -Force } 
    else { $success = New-StoreFile -StorePath $StorePath }
    if (-not $success) { return }

    $PlainPassword = ConvertTo-PlainString -Secure $Password

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

    return
}