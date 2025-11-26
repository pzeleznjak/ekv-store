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

    $storePath = Get-StorePath -Name $Name -CheckExists
    if ($null -eq $storePath) { return }

    $masterPassword = Get-MasterPassword -StorePath $storePath
        
    $success = Compare-PasswordHashes -MasterPasswordHash $masterPassword.PasswordHash -Password $Password -Salt $masterPassword.Salt
    if (-not $success) { return $null }

    $found = $false
    $encryptedValueHex = $null

    $lines = Get-Content $storePath
    $result = foreach ($line in $lines) {
        if (-not $found -and $line -match "^$Key\s+") {
            $found = $true
            $parts = $line -split "\s+", 2
            $encryptedValueHex = $parts[1]
            continue
        }
        $line
    }

    $result | Set-Content $storePath

    if (-not $found) {
        Write-Error "No line with key $Key to remove"
        return $null
    }

    if ($null -eq $encryptedValueHex) {
        Write-Error "Encrypted value for key $Key not found"
        return $null
    }

    $encryptedValueBytes = for ($i = 0; $i -lt $encryptedValueHex.Length; $i += 2) { [Convert]::ToByte($encryptedValueHex.Substring($i,2),16) }

    try {
        $aes = New-AESObject -Password $Password -Salt $masterPassword.Salt
        $decryptor = $aes.CreateDecryptor()
        $decryptedBytes = $decryptor.TransformFinalBlock($encryptedValueBytes, 0, $encryptedValueBytes.Length)
        $decryptedValueText = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)    
    }
    finally {
        $aes.Dispose()
        $decryptor.Dispose()
    }  

    Write-Host "Successfully deleted key $Key"
    return $decryptedValueText
}