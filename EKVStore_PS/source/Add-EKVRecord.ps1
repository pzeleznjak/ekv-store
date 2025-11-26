function Add-EKVRecord {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the Encrypted Key-Value store to access")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the Encrypted Key-Value store to access")]
        [securestring] $Password,

        [Parameter(Mandatory=$true, Position=2, HelpMessage="Key of the Encrypted Key-Value record to add")]
        [string] $Key,

        [Parameter(Mandatory=$true, Position=3, HelpMessage="Value of the Encrypted Key-Value record to add")]
        [string] $Value
    )

    $StorePath = Get-StorePath -Name $Name -CheckExists
    if ($null -eq $StorePath) { return $null }

    $MasterPassword = Get-MasterPassword -StorePath $StorePath

    $success = Compare-PasswordHashes -MasterPasswordHash $MasterPassword.PasswordHash -Password $Password -Salt $MasterPassword.Salt
    if (-not $success) { return $null }

    $ValueBytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
    
    try {
        $Aes = New-AESObject -Password $Password -Salt $MasterPassword.Salt    
        $Encryptor = $Aes.CreateEncryptor()
        $EncryptedValueBytes = $Encryptor.TransformFinalBlock($ValueBytes, 0, $ValueBytes.Length)
        $EncryptedValueHex = [System.BitConverter]::ToString($EncryptedValueBytes) -replace "-", ""
    }
    finally {
        $Aes.Dispose()
        $Encryptor.Dispose()
    }

    $Record = $Key + " " + $EncryptedValueHex
    $Record | Out-File -FilePath $StorePath -Encoding utf8 -Append

    Write-Host "Successfully added Encrypted Key-Value under key $Key"

    return $Key
}