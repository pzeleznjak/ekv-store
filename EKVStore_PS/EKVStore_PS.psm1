Import-Module "$PSScriptRoot\source\EKVStoreUtils.psm1" -Force

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Get-ChildItem $ScriptDir -Recurse -Filter *.ps1 -File | Unblock-File

Get-ChildItem "$ScriptDir\source\*.ps1" | ForEach-Object {
    . $_.FullName
    Write-Host "Loaded command: $($_.NameString)"
}