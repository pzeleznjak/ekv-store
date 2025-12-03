<#
.SYNOPSIS
Exports an Encrypted Key-Value (EKV) store to an .ekv encrypted file.

.DESCRIPTION
Checks whether the provided EKV store exists and exports it to the provided
directory where filename is $Name.ekv.

.PARAMETER Name
Name of the Encrypted Key-Value store to export.

.PARAMETER ExportDirectory
Target directory to which to export the EKV store. Resulting file is named
$Name.ekv.
If not defined, takes the directory from which the command was called and
exports the EKV to that directory.

.PARAMETER Force
Flag which forces the export of the Encrypted Key-Value store even if the
export file already exists.

.INPUTS
None

.OUTPUTS
Boolean
Flag which indicates whether the operation was successful.

.EXAMPLE
Export-EKVToFile -Name testekv -ExportPath C:/ekv-exports

Export an EKV named "testekv" to the C:/ekv-exports/testekv.ekv file.

.EXAMPLE
Export-EKVToFile -Name testekv

Export an EKV named "testekv" to the C:/path/to/called/directory/testekv.ekv
file.

.EXAMPLE
Export-EKVToFile -Name testekv -ExportPath C:/ekv-exports -Force
Export an EKV named "testekv" to the C:/ekv-exports/testekv.ekv file even
if it exists.

.NOTES
To define a Secure String -Password value use for example:
PS > $ekvpass = Read-Host -AsSecureString
PS > ********
#>
function Export-EKVToFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the Encrypted Key-Value store to access")]
        [string] $Name,

        [Parameter(Position=1, HelpMessage="Path to export Encrypted Key-Value store to to")]
        [string] $ExportDirectory,

        [Parameter(Position=2, HelpMessage="Flag which forces the export of the Encrypted Key-Value store even if export file already exists")]
        [switch] $Force = $false
    )

    $storePath = Get-StorePath -Name $Name -CheckExists
    if ($null -eq $storePath) { return $false }

    if (-not $ExportDirectory) {
        $exportFile = Get-StorePath -Name $Name -DirectoryPath $PWD
    } else {
        $exportFile = Get-StorePath -Name $Name -DirectoryPath $ExportDirectory
    }

    if ((-not $Force) -and (Test-Path $exportFile)) {
        Write-Host "Export file $exportFile already exists" -ForegroundColor Red
        return $false
    }

    Copy-Item -Path $storePath -Destination $exportFile
    
    Write-Host "Successfully exported $Name EKV store to $exportFile" -ForegroundColor Green
    return $true
}