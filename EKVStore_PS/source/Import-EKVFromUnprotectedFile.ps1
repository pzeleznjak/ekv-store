<#
.SYNOPSIS
Imports an exported Encrypted Key-Value (EKV) store from an unprotected
.kv plaintext file into given EKV store.

.DESCRIPTION
Creates a new Encrypted Key-Value store and stores all Key-Value records
contained in the provided .kv plaintext file to the new store.

.PARAMETER Name
Name of the Encrypted Key-Value store to create.

.PARAMETER Password
Master Password of the Encrypted Key-Value store to create.

.PARAMETER ExportFile
Path to unprotected file to import to new Encrypted Key-Value store.

.PARAMETER RemoveFile
Remove the unprotected file after importing.

.PARAMETER Force
Force creation of the new Encrypted Key-Value store even if such already
exists, overwriting it.

.INPUTS
None

.OUTPUTS
Boolean
Flag which indicates whether the operation was successful.

.EXAMPLE
Import-EKVFromUnprotectedFile -Name testekv -Password $ekvpass -ExportFile C:\ekv-exports\export.kv

Create a new EKV store named "testekv" and import all records from 
C:\ekv-exports\export.kv.

.EXAMPLE
Import-EKVFromUnprotectedFile -Name testekv -Password $ekvpass -ExportFile C:\ekv-exports\export.kv -Force

Create a new EKV store named "testekv" and import all records from 
C:\ekv-exports\export.kv even if "testekv" already exists, overwriting it.

.NOTES
To define a Secure String -Password value use for example:
PS > $ekvpass = Read-Host -AsSecureString
PS > ********
#>
function Import-EKVFromUnprotectedFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the Encrypted Key-Value store to create")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the Encrypted Key-Value store to create")]
        [securestring] $Password,

        [Parameter(Position=2, HelpMessage="Path to unprotected file to import to new Encrypted Key-Value store")]
        [string] $ExportFile,

        [Parameter(Position=3, HelpMessage="Remove the unprotected file after importing")]
        [switch] $RemoveFile = $false,

        [Parameter(Position=4, HelpMessage="Force creation of the new Encrypted Key-Value store")]
        [switch] $Force = $false
    )

    if (-not (Test-Path $ExportFile)) {
        Write-Error "$ExportFile does not exist" -ErrorAction Stop
    }

    $lines = Get-Content -Path $ExportFile

    $found = $false
    $kvLines = $lines | ForEach-Object {
        if (-not $found) {
            if ($_.StartsWith("Key-Value_Store")) {
                $found = $true
            }
            return
        }
        if ($_.StartsWith("#")) {
            return
        }
        if ($_ -eq '') {
            return
        }
        $_
    }

    $success = $false
    if ($Force) { $success = New-EKVStore -Name $Name -Password $Password -Force } 
    else { $success = New-EKVStore -Name $Name -Password $Password }
    if (-not $success) { return $false }

    $kvLines | ForEach-Object {
        $split = $_ -split "="
        Add-EKVRecord -Name $Name -Password $Password -Key $split[0] -RawValue $split[1] | Out-Null
    }

    if ($RemoveFile) {
        Remove-Item -Path $ExportFile
        Write-Host "Removed the $ExportFile unprotected file"
    }

    Write-Host "Imported $ExportFile to new Encrypted Key-Value store $Name successfully" -ForegroundColor Green

    return $true
}