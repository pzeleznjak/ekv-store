<#
.SYNOPSIS
Creates a new empty Encrypted Key-Value (EKV) store.

.DESCRIPTION
Creates a new empty Encrypted Key-Value store and sets its master password.

.PARAMETER Name
Name of the Encrypted Key-Value store to create.

.PARAMETER Password
Master Password of the Encrypted Key-Value store to create.

.PARAMETER Force
Flag which forces the command to create the specified Encrypted Key-Value
store even if the target copy store already exists, overwriting it.

.INPUTS
None

.OUTPUTS
Boolean
Flag which indicates whether the operation was successful.

.EXAMPLE
New-EKVStore -Name testekv -Password $ekvpass

Create new EKV store named "testekv".

.EXAMPLE
New-EKVStore -Name testekv -Password $ekvpass -Force

Create new EKV store named "testekv" even if such already exists.

.NOTES
To define a Secure String -Password value use for example:
PS > $ekvpass = Read-Host -AsSecureString
PS > ********
#>
function New-EKVStore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the new Encrypted Key-Value store to be created")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the new Encrypted Key-Value store")]
        [securestring] $Password,

        [Parameter(Position=2, HelpMessage="Force creation of the new Encrypted Key-Value store")]
        [switch] $Force = $false
    )

    $directoryPath = Get-StoreDirectoryPath
    if (-not (Test-Path -Path $directoryPath)) {
        New-Item -Path $directoryPath -ItemType Directory -Force | Out-Null
    }
    $storePath = Get-StorePath -Name $Name -DirectoryPath $directoryPath
    $success = $false
    if ($Force) { $success = New-StoreFile -StorePath $storePath -Force } 
    else { $success = New-StoreFile -StorePath $storePath }
    if (-not $success) { return $false }

    $plainPassword = ConvertTo-PlainString -Secure $Password

    $saltBytes = New-Object byte[] 8
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $rng.GetBytes($saltBytes)
    $rng.Dispose()
    $saltText = [Convert]::ToBase64String($saltBytes)
    $saltedPassword = $plainPassword + $saltText

    $hashText = Get-SHA256HashHex -Text $saltedPassword

    $record = $hashText + " " + $saltText
    $record | Out-File -FilePath $storePath -Encoding utf8

    Write-Host "Successfully created new Encrypted Key-Value store $Name" -ForegroundColor Green

    return $true
}