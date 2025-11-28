function Export-ToUnprotectedFile {
    param (
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the Encrypted Key-Value store to export")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the Encrypted Key-Value store to export")]
        [securestring] $Password,

        [Parameter(Position=2, HelpMessage="Path to unprotected file to export Encrypted Key-Value store to")]
        [string] $ExportFile
    )

    if (-not $PSBoundParameters.ContainsKey("ExportFile")) {
        $ExportFile = ".\$Name.kv"
    }

    if ([IO.Path]::GetExtension($ExportFile) -ne ".kv") {
        Write-Host "ExportFile must have extension .kv" -ForegroundColor Yellow
        Write-Host "Appended '.kv' to ExportFile path"
        $ExportFile = "$ExportFile.kv"
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
    return $ExportFile
}