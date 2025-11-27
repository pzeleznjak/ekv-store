function Add-EKVRecord {
    [CmdletBinding(DefaultParameterSetName = "ByValue")]
    param (
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the Encrypted Key-Value store to access")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the Encrypted Key-Value store to access")]
        [securestring] $Password,

        [Parameter(Mandatory=$true, Position=2, HelpMessage="Key of the Encrypted Key-Value record to add")]
        [string] $Key,

        [Parameter(Mandatory=$true, Position=3, ParameterSetName="ByValue", HelpMessage="Secure String Value of the Encrypted Key-Value record to add")]
        [securestring] $Value,

        [Parameter(Mandatory=$true, Position=4, ParameterSetName="ByRawValue", HelpMessage="Raw value of the Encrypted Key-Value record to add")]
        [string] $RawValue
    )

    $storePath = Get-StorePath -Name $Name -CheckExists
    if ($null -eq $storePath) { return $null }

    $masterPassword = Get-MasterPassword -StorePath $storePath

    $success = Compare-PasswordHashes -MasterPasswordHash $masterPassword.PasswordHash -Password $Password -Salt $masterPassword.Salt
    if (-not $success) { return $null }

    if ($PSBoundParameters.ContainsKey("Value")) {
        $RawValue = ConvertTo-PlainString -Secure $Value
    }

    $valueBytes = [System.Text.Encoding]::UTF8.GetBytes($RawValue)
    
    try {
        $aes = New-AESObject -Password $Password -Salt $masterPassword.Salt    
        $encryptor = $aes.CreateEncryptor()
        $encryptedValueBytes = $encryptor.TransformFinalBlock($valueBytes, 0, $valueBytes.Length)
        $encryptedValueHex = [System.BitConverter]::ToString($encryptedValueBytes) -replace "-", ""
    }
    finally {
        $aes.Dispose()
        $encryptor.Dispose()
    }

    $record = $Key + " " + $encryptedValueHex
    $record | Out-File -FilePath $storePath -Encoding utf8 -Append

    Write-Host "Successfully added Encrypted Key-Value under key $Key"

    return $Key
}