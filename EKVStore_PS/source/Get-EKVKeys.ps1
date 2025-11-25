function Get-EKVKeys {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the Encrypted Key-Value store to access")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the Encrypted Key-Value store to access")]
        [securestring] $Password
    )

    $StorePath = Get-StorePath -Name $Name -CheckExists
    if ($null -eq $StorePath) { return }

    $MasterPassword = Get-MasterPassword -StorePath $StorePath
    
    $PlainPassword = ConvertTo-PlainString -Secure $Password
    
    $SaltedPassword = $PlainPassword + $MasterPassword.Salt
    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($SaltedPassword)
    $SHA256 = [System.Security.Cryptography.SHA256]::Create()
    $HashBytes = $SHA256.ComputeHash($Bytes)
    $HashText = ([System.BitConverter]::ToString($HashBytes) -replace "-", "")
    if ($HashText -ne $MasterPassword.PasswordHash) {
        Write-Error "Invalid Key-Value store Master Password"
        return $null
    }

    $Keys = Get-Content -Path $StorePath -Encoding UTF8 | Select-Object -Skip 1 | ForEach-Object { ($_ -split "\s+")[0] }
    return $Keys
}