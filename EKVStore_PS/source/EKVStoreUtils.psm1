function Get-StoreDirectoryPath {
    return Join-Path $PSScriptRoot ".ekvs" 
}

function Get-StorePath{
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the new Encrypted Key-Value store to be created")]
        [string] $Name,

        [Parameter(Position=1, HelpMessage="Directory where Encrypted Key-Value stores are located")]
        [string] $DirectoryPath = "",

        [Parameter(Position=2, HelpMessage="Check existance of store path")]
        [switch] $CheckExists = $false
    )

    if ($DirectoryPath -eq "") {
        $DirectoryPath = Get-StoreDirectoryPath
    }

    $StorePath = Join-Path $DirectoryPath "$($Name).ekv"
    if ($CheckExists -and -not (Test-Path -Path $StorePath)) {
        Write-Error "Encrypted Key-Value store $Name does not exist"
        return $null
    }
    return $StorePath
}

function New-StoreFile {
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Path to new Encrypted Key-Value store file")]
        $StorePath,

        [Parameter(Position=1, HelpMessage="Force creation of the copied Encrypted Key-Value store")]
        [switch] $Force = $false
    )

    if (-not $Force -and (Test-Path -Path $StorePath)) {
        Write-Error "Encrypted Key-Value store $Name already exists"
        return $false
    }
    New-Item -Path $StorePath -ItemType File -Force | Out-Null
    Write-Host "Created new empty Encrypted Key-Value store"
    return $true
}