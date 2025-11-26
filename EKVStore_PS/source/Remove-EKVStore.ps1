function Remove-EKVStore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the new Encrypted Key-Value store to be created")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the new Encrypted Key-Value store")]
        [securestring] $Password
    )

    $StorePath = Get-StorePath -Name $Name -CheckExists
    if ($null -eq $StorePath) { return }

    $MasterPassword = Get-MasterPassword -StorePath $StorePath
        
    $success = Compare-PasswordHashes -MasterPasswordHash $MasterPassword.PasswordHash -Password $Password -Salt $MasterPassword.Salt
    if (-not $success) { return $null }

    Write-Host "Are you sure you want to remove Encrypted Key-Value store $Name ? (y/n)" -ForegroundColor Red
    $answer = Read-Host

    if ($answer -notmatch '^[Yy]') {
        Write-Host "Operation cancelled."
        return $null
    }

    try {
        $Aes = New-AESObject -Password $Password -Salt $MasterPassword.Salt
        $Decryptor = $Aes.CreateDecryptor()

        $Records = foreach ($Line in (Get-Content $StorePath | Select-Object -Skip 1)) {
            $Parts = $Line -split "\s+"
            $Key = $Parts[0]
            $EncryptedValueHex = $Parts[1]

            $EncryptedValueBytes = for ($i = 0; $i -lt $EncryptedValueHex.Length; $i += 2) { [Convert]::ToByte($EncryptedValueHex.Substring($i,2),16) }

            $DecryptedBytes = $Decryptor.TransformFinalBlock($EncryptedValueBytes, 0, $EncryptedValueBytes.Length)
            $DecryptedValueText = [System.Text.Encoding]::UTF8.GetString($DecryptedBytes)

            $Key, $DecryptedValueText
        }    
    }
    finally {
        $Aes.Dispose()
        $Decryptor.Dispose()
    }    

    Remove-Item $StorePath -Force
    Write-Host "Removed Encrypted Key-Value store $Name"
    
    return $Records
}