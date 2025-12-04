<#
.SYNOPSIS
Exports an Encrypted Key-Value (EKV) store to an unprotected .kv plaintext file.

.DESCRIPTION
Checks whether the provided password is the master password of the provided
Encrypted Key-Value store, decrypts all encrypted records and stores them
in a provided .kv plaintext export file.

.PARAMETER Name
Name of the Encrypted Key-Value store to export.

.PARAMETER Password
Master Password of the Encrypted Key-Value store to export.

.PARAMETER ExportFile
Target .kv file to which to export the EKV store.
If value is not provided it automatically has value "$Name.kv" in caller
working directory.
If the provided file does not have extension .kv, the extension is 
automatically appended.

.PARAMETER Force
Force creation of the unprotected .kv file even if such already exists.

.INPUTS
None

.OUTPUTS
Boolean
Flag which indicates whether the operation was successful.

.EXAMPLE
Export-ToUnprotectedFile -Name testekv -Password $ekvpass -ExportFile C:\ekv-exports\export.kv

Export an EKV named "testekv" to the C:\ekv-exports\export.kv file.

.EXAMPLE
Export-ToUnprotectedFile -Name testekv -Password $ekvpass

Export an EKV named "testekv" to the automatically assigned .\testekv.kv
file.

.NOTES
To define a Secure String -Password value use for example:
PS > $ekvpass = Read-Host -AsSecureString
PS > ********
#>
function Export-ToUnprotectedFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the Encrypted Key-Value store to export")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the Encrypted Key-Value store to export")]
        [securestring] $Password,

        [Parameter(Position=2, HelpMessage="Path to unprotected file to export Encrypted Key-Value store to")]
        [string] $ExportFile,

        [Parameter(Position=3, HelpMessage="Force creation of the unprotected file")]
        [switch] $Force = $false
    )

    if (-not $PSBoundParameters.ContainsKey("ExportFile")) {
        $ExportFile = Join-Path -Path $PWD -ChildPath ".\$Name.kv"
    }

    if ([IO.Path]::GetExtension($ExportFile) -ne ".kv") {
        Write-Host "ExportFile must have extension .kv" -ForegroundColor Yellow
        Write-Host "Appended '.kv' to ExportFile path"
        $ExportFile = "$ExportFile.kv"
    }

    if ((-not $Force) -and (Test-Path $ExportFile)) {
        Write-Host "File $ExportFile already exists" -ForegroundColor Red
        return $false
    }

    Write-Host "Exporting $Name to $ExportFile"

    $keys = Get-EKVKeys -Name $Name -Password $Password
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("Key-Value_Store")
    [void]$sb.AppendLine("# --------------- #")
    foreach ($key in $keys) {
        $value = Get-EKVRecord -Name $Name -Password $Password -Key $key
        [void]$sb.Append($key)
        [void]$sb.Append("=")
        [void]$sb.AppendLine($value)
    }

    Set-Content -Path $ExportFile -Value $sb.ToString()

    Write-Host "Successfully exported Encrypted Key-Value store $Name to $ExportFile" -ForegroundColor Green
}