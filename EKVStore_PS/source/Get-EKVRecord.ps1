function Get-EKVRecord {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the Encrypted Key-Value store to access")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the Encrypted Key-Value store to access")]
        [securestring] $Password,

        [Parameter(Mandatory=$true, Position=2, HelpMessage="Key of the Encrypted Key-Value record to get")]
        [string] $Key,

        [Parameter(HelpMessage="Return Encrypted Value as SecureString")]
        [switch] $AsSecureString = $false
    )

    $storePath = Get-StorePath -Name $Name -CheckExists
    if ($null -eq $storePath) { return }

    $masterPassword = Get-MasterPassword -StorePath $storePath
       
    $success = Compare-PasswordHashes -MasterPasswordHash $masterPassword.PasswordHash -Password $Password -Salt $masterPassword.Salt
    if (-not $success) { return $null }

    $encryptedValueHex = $null
    foreach ($Line in Get-Content -Path $storePath -Encoding UTF8 | Select-Object -Skip 1) {
        $Split = $Line -split '\s+'
        if ($Split[0] -eq $Key) {
            $encryptedValueHex = $Split[1]
            break;
        }
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
    

    Write-Host "Successfully decrypted Encrypted Key-Value under key $Key"

    if ($AsSecureString) {
        return $decryptedValueText | ConvertTo-SecureString -AsPlainText -Force
    }

    return $decryptedValueText
}