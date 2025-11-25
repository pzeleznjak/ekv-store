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

    $DirectoryPath = Get-StoreDirectoryPath
    $StorePath = Get-StorePath -Name $Name -CheckExists
    if ($null -eq $StorePath) { return }

    $MasterPassword = Get-MasterPassword -StorePath $StorePath
    
    $success = Compare-PasswordHashes -MasterPasswordHash $MasterPassword.PasswordHash -Password $Password -Salt $MasterPassword.Salt
    if (-not $success) { return $null }
    
    $CopyStorePath = Get-StorePath -Name $CopyName -DirectoryPath $DirectoryPath
    if ($null -eq $CopyStorePath) { return }
    $success = $false
    if ($Force) { $success = New-StoreFile -StorePath $CopyStorePath -Force } 
    else { $success = New-StoreFile -StorePath $CopyStorePath }
    if (-not $success) { return }

    (Get-Content $StorePath) | Set-Content $CopyStorePath
    Write-Host "Copied contents of $Name to $CopyName Encrypted Key-Value store"
}