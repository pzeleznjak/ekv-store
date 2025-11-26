Import-Module "$PSScriptRoot\source\EKVStoreUtils.psm1" -Force

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Get-ChildItem $scriptDir -Recurse -Filter *.ps1 -File | Unblock-File

Get-ChildItem "$scriptDir\source\*.ps1" | ForEach-Object {
    . $_.FullName
    Write-Host "Loaded command: $($_.NameString)"
}