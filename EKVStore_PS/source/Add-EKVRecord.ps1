<#
.SYNOPSIS
Adds a new Key-Value record to an Encrypted Key-Value (EKV) store.

.DESCRIPTION
Checks whether the provided password is the master password of the provided
Encrypted Key-Value store, encrypts the provided value and stores it under
the provided key.

.PARAMETER Name
Name of the Encrypted Key-Value store to access.

.PARAMETER Password
Master Password of the Encrypted Key-Value store to access.

.PARAMETER Key
Key of the Encrypted Key-Value record to add.

.PARAMETER Value
Secure String Value of the Encrypted Key-Value record to add.
Must be provided if RawValue is not.
If both are provided, Value is used.

.PARAMETER RawValue
Raw value of the Encrypted Key-Value record to add.
Must be provided if Value is not.
If both are provided, Value is used.

.INPUTS
None

.OUTPUTS
Boolean
Flag which indicates whether the operation was successful.

.EXAMPLE
Add-EKVRecord -Name testekv -Password $ekvpass -Key testkey -Value $ekvvalue

Add a record with key "testkey" and Secure String value ********* to EKV Store named "testekv".

.EXAMPLE
Add-EKVRecord -Name testekv -Password $ekvpass -Key testkey -RawValue testvalue

Add a record with key "testkey" and value testvalue to EKV Store named "testekv".

.NOTES
To define a Secure String -Password or -Value value use for example:
PS > $ekvpass = Read-Host -AsSecureString
PS > ********
#>
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

    if ($Key -match '\s|,|=') {
        Write-Error "Key must not contain whitespace, commas or equality operator signs." -ErrorAction Stop
    }

    $storePath = Get-StorePath -Name $Name -CheckExists
    if ($null -eq $storePath) { return $false }

    $masterPassword = Get-MasterPassword -StorePath $storePath

    $success = Compare-PasswordHashes -MasterPasswordHash $masterPassword.PasswordHash -Password $Password -Salt $masterPassword.Salt
    if (-not $success) { return $false }

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

    Write-Host "Successfully added Encrypted Key-Value under key $Key" -ForegroundColor Green

    return $true
}