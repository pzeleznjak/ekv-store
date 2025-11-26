function Remove-EKVRecord {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the Encrypted Key-Value store to access")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the Encrypted Key-Value store to access")]
        [securestring] $Password,

        [Parameter(Mandatory=$true, Position=2, HelpMessage="Key of the Encrypted Key-Value record to remove")]
        [string] $Key
    )

    $StorePath = Get-StorePath -Name $Name -CheckExists
    if ($null -eq $StorePath) { return }

    $MasterPassword = Get-MasterPassword -StorePath $StorePath
        
    $success = Compare-PasswordHashes -MasterPasswordHash $MasterPassword.PasswordHash -Password $Password -Salt $MasterPassword.Salt
    if (-not $success) { return $null }

    $Found = $false
    $EncryptedValueHex = $null

    $lines = Get-Content $StorePath
    $result = foreach ($line in $lines) {
        if (-not $Found -and $line -match "^$Key\s+") {
            $Found = $true
            $parts = $line -split "\s+", 2
            $EncryptedValueHex = $parts[1]
            continue
        }
        $line
    }

    $result | Set-Content $StorePath

    if (-not $Found) {
        Write-Error "No line with key $Key to remove"
        return $null
    }

    if ($null -eq $EncryptedValueHex) {
        Write-Error "Encrypted value for key $Key not found"
        return $null
    }

    $EncryptedValueBytes = for ($i = 0; $i -lt $EncryptedValueHex.Length; $i += 2) { [Convert]::ToByte($EncryptedValueHex.Substring($i,2),16) }

    try {
        $Aes = New-AESObject -Password $Password -Salt $MasterPassword.Salt
        $Decryptor = $Aes.CreateDecryptor()
        $DecryptedBytes = $Decryptor.TransformFinalBlock($EncryptedValueBytes, 0, $EncryptedValueBytes.Length)
        $DecryptedValueText = [System.Text.Encoding]::UTF8.GetString($DecryptedBytes)    
    }
    finally {
        $Aes.Dispose()
        $Decryptor.Dispose()
    }  

    Write-Host "Successfully deleted key $Key"
    return $DecryptedValueText
}