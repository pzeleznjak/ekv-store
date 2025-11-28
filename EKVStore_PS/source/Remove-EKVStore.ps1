<#
.SYNOPSIS
Removes an Encrypted Key-Value (EKV) store.

.DESCRIPTION
Checks whether the provided password is the master password of the provided
Encrypted Key-Value store and removes the EKV store.

.PARAMETER Name
Name of the Encrypted Key-Value store to remove.

.PARAMETER Password
Master Password of the Encrypted Key-Value store to remove.

.PARAMETER Force
Flag which forces the command to remove the specified Encrypted Key-Value
store without prompting the user for confirmation.

.INPUTS
None

.OUTPUTS
List<(string, string)>
List of all Key-Value records contained in the removed store.

.EXAMPLE
Remove-EKVStore -Name testekv -Password $ekvpass

Remove an EKV store named "testekv".

.EXAMPLE
Remove-EKVStore -Name testekv -Password $ekvpass -Force

Remove an EKV store named "testekv" without prompting the user for 
confirmation.

.NOTES
To define a Secure String -Password value use for example:
PS > $ekvpass = Read-Host -AsSecureString
PS > ********
#>
function Remove-EKVStore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="Name of the new Encrypted Key-Value store to be created")]
        [string] $Name,

        [Parameter(Mandatory=$true, Position=1, HelpMessage="Master Password of the new Encrypted Key-Value store")]
        [securestring] $Password,

        [Parameter(Position=2, HelpMessage="Force removal of the new Encrypted Key-Value store")]
        [switch] $Force = $false
    )

    $storePath = Get-StorePath -Name $Name -CheckExists
    if ($null -eq $storePath) { return $null }

    $masterPassword = Get-MasterPassword -StorePath $storePath
        
    $success = Compare-PasswordHashes -MasterPasswordHash $masterPassword.PasswordHash -Password $Password -Salt $masterPassword.Salt
    if (-not $success) { return $null }

    if (-not $Force) {
        Write-Host "Are you sure you want to remove Encrypted Key-Value store $Name ? (y/n)" -ForegroundColor DarkRed
        $answer = Read-Host

        if ($answer -notmatch '^[Yy]') {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            return $null
        }
    }

    try {
        $aes = New-AESObject -Password $Password -Salt $masterPassword.Salt
        $decryptor = $aes.CreateDecryptor()

        $records = foreach ($Line in (Get-Content $storePath | Select-Object -Skip 1)) {
            $parts = $Line -split "\s+"
            $key = $parts[0]
            $encryptedValueHex = $parts[1]

            $encryptedValueBytes = for ($i = 0; $i -lt $encryptedValueHex.Length; $i += 2) { [Convert]::ToByte($encryptedValueHex.Substring($i,2),16) }

            $decryptedBytes = $decryptor.TransformFinalBlock($encryptedValueBytes, 0, $encryptedValueBytes.Length)
            $decryptedValueText = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)

            $key, $decryptedValueText
        }    
    }
    finally {
        $aes.Dispose()
        $decryptor.Dispose()
    }    

    Remove-Item $storePath -Force
    Write-Host "Removed Encrypted Key-Value store $Name" -ForegroundColor Green
    
    return $records
}