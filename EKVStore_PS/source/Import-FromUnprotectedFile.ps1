function Import-FromUnprotectedFile {
    param (
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the Encrypted Key-Value store to create")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the Encrypted Key-Value store to create")]
        [securestring] $Password,

        [Parameter(Position=2, HelpMessage="Path to unprotected file to import to new Encrypted Key-Value store")]
        [string] $ExportFile,

        [Parameter(Position=2, HelpMessage="Force creation of the new Encrypted Key-Value store")]
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
    if (-not $success) { return }
    Write-Host "SUCCESS"

    $kvLines | ForEach-Object {
        $split = $_ -split "="
        Add-EKVRecord -Name $Name -Password $Password -Key $split[0] -RawValue $split[1]
    }

    Write-Host "Imported $ExportFile to new Encrypted Key-Value store $Name successfully"
}