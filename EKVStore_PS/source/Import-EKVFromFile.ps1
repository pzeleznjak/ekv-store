<#
.SYNOPSIS
Imports an Encrypted Key-Value (EKV) store to from an exported .ekv 
encrypted file.

.DESCRIPTION
Checks whether the provided exported .ekv encrypted file exists and whether
the EKV store, named the same as the file, already exists and imports it.

.PARAMETER ExportPath
File which is to be imported to an EKV store. Resulting store is named the
same as the file (without extension).

.PARAMETER RemoveFile
Remove the exported encrypted .ekv file after importing.

.PARAMETER Force
Flag which forces the import of the Encrypted Key-Value store even if the
store already exists.

.INPUTS
None

.OUTPUTS
Boolean
Flag which indicates whether the operation was successful.

.EXAMPLE
Import-EKVFromFile -ExportFile ./testekv.ekv

Imports the ./testekv.ekv file as an EKV store named "testekv".

.EXAMPLE
Import-EKVFromFile -ExportFile ./testekv.ekv -RemoveFile

Imports the ./testekv.ekv file as an EKV store named "testekv" removing the
./testekv.ekv file.

.EXAMPLE
Import-EKVFromFile -ExportFile ./testekv.ekv -Force

Imports the ./testekv.ekv file as an EKV store named "testekv" even if the
"testekv" already exists.

.NOTES
To define a Secure String -Password value use for example:
PS > $ekvpass = Read-Host -AsSecureString
PS > ********
#>
function Import-EKVFromFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="File to import into an Encrypted Key-Value store")]
        [string] $ExportFile,

        [Parameter(Position=1, HelpMessage="Remove the export file after importing")]
        [switch] $RemoveFile = $false,

        [Parameter(Position=2, HelpMessage="Flag which forces the import of the Encrypted Key-Value store even if the store already exists")]
        [switch] $Force = $false
    )

    if (-not (Test-Path $ExportFile)) {
        Write-Error "$ExportFile does not exist" -ErrorAction Stop
    }

    $name = [System.IO.Path]::GetFileNameWithoutExtension($ExportFile)

    $storePath = Get-StorePath -Name $name
    if ((-not $Force) -and (Test-Path $storePath)) {
        Write-Host "Encrypted Key-Value store $name already exists" -ForegroundColor Red
        return $false
    }

    Copy-Item -Path $ExportFile -Destination $storePath

    if ($RemoveFile) {
        Remove-Item -Path $ExportFile
        Write-Host "Removed the $ExportFile unprotected file"
    }

    Write-Host "Imported $ExportFile to new Encrypted Key-Value store $name successfully" -ForegroundColor Green

    return $true   
}