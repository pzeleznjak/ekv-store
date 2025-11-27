function Copy-EKVStore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the Encrypted Key-Value store to copy")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the Encrypted Key-Value store")]
        [securestring] $Password,

        [Parameter(Position=2, HelpMessage="Name of the copy Encrypted Key-Value store")]
        [string] $CopyName = $StoreName + "_copy",

        [Parameter(Position=3, HelpMessage="Force creation of the copied Encrypted Key-Value store")]
        [switch] $Force = $false
    )

    $directoryPath = Get-StoreDirectoryPath
    $storePath = Get-StorePath -Name $Name -CheckExists
    if ($null -eq $storePath) { return }

    $masterPassword = Get-MasterPassword -StorePath $storePath
    
    $success = Compare-PasswordHashes -MasterPasswordHash $masterPassword.PasswordHash -Password $Password -Salt $masterPassword.Salt
    if (-not $success) { return $null }
    
    $copyStorePath = Get-StorePath -Name $CopyName -DirectoryPath $directoryPath
    if ($null -eq $copyStorePath) { return }
    $success = $false
    if ($Force) { $success = New-StoreFile -StorePath $copyStorePath -Force } 
    else { $success = New-StoreFile -StorePath $copyStorePath }
    if (-not $success) { return }

    (Get-Content $storePath) | Set-Content $copyStorePath
    Write-Host "Copied contents of $Name to $CopyName Encrypted Key-Value store" -ForegroundColor Green
}