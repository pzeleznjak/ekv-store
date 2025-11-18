$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Get-ChildItem "$ScriptDir\source\*.ps1" | ForEach-Object {
    . $_.FullName
    Write-Host "Loaded command: $($_.NameString)"
}