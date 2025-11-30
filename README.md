# Encrypted Key-Value (EKV) Store
Implementation of Powershell tools used to manage Key-Value stores with the property that the stored values are cryptographically encrypted.

## Contents
1. [Compatibility](#compatibility)
2. [Usage](#usage)
    1. [New-EKVStore](#new-ekvstore)
    2. [Add-EKVRecord](#add-ekvrecord)
    3. [Get-EKVRecord](#get-ekvrecord)
    4. [Get-EKVKeys](#get-ekvkeys)
    5. [Remove-EKVRecord](#remove-ekvrecord)
    6. [Remove-EKVStore](#remove-ekvstore)
    7. [Copy-EKVStore](#copy-ekvstore)
    8. [Get-EKVStores](#get-ekvstores)
    9. [Export-ToUnprotectedFile](#export-tounprotectedfile)
    10. [Import-FromUnprotectedFile](#import-fromunprotectedfile)
    11. [Rename-EKVStore](#rename-ekvstore)
    12. [Rename-EKVKey](#rename-ekvkey)
    13. [Typical usage](#typical-usage)
3. [Implementation notes](#implementation-notes)
    1. [Physical storage](#physical-storage)
    2. [Master password check](#master-password-check)
    3. [Record encryption](#record-encryption)
    4. [Record decryption](#record-decryption)
4. [Author](#author)
5. [Changelog](#changelog)

## Compatibility

| Component  | Version   |
| ---------- | --------- |
| Powershell | 7.5.4     |
| .NET Core  | 9.0.10    |

## Usage

Before using this module it is required to set the Execution Policy of Powershell to the one that does not restrict the execution of scripts which are not digitally signed.

`Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process`

_Always verify the scripts before enabling their execution!_

Import the module using Import-Module Cmdlet with -Path argument pointing to the directory where the EKVStore_PS.psd1 file is located.

Most of the Cmdlets have a -Password parameter which expects a [Secure String](https://learn.microsoft.com/en-us/dotnet/api/system.security.securestring?view=net-9.0) value of the Encrypted Key-Value store master password. To define a Secure String variable to be used as the master password, you can use the following command:

`$ekvpass = Read-Host -AsSecureString`

### New-EKVStore
- Creates a new empty Encrypted Key-Value store and sets its master password
- Parameters
    - Name - String - Name of the Encrypted Key-Value store to create
    - Password - SecureString - Master Password of the Encrypted Key-Value store to create
    - Force - SwitchParameter - Flag which forces the command to create the specified Encrypted Key-Value store even if the target copy store already exists, overwriting it
- Inputs - None
- Outputs - Boolean - Flag which indicates whether the operation was successful

### Add-EKVRecord
- Checks whether the provided password is the master password of the provided Encrypted Key-Value store, encrypts the provided value and stores it under the provided key
- Parameters
    - Name - String - Name of the Encrypted Key-Value store to access
    - Password - SecureString - Master Password of the Encrypted Key-Value store to access
    - Key - String - Key of the Encrypted Key-Value record to add
    - Value - SecureString - Secure String Value of the Encrypted Key-Value record to add
        - Must be provided if RawValue is not
        - If both are provided, Value is used
    - RawValue - String - Raw value of the Encrypted Key-Value record to add
        - Must be provided if Value is not
        - If both are provided, Value is used
- Inputs - None
- Outputs - Boolean - Flag which indicates whether the operation was successful

### Get-EKVRecord
- Checks whether the provided password is the master password of the provided Encrypted Key-Value store, finds the provided key in given EKV, decrypts the value stored under it and returns it
- Parameters
    - Name - String - Name of the Encrypted Key-Value store to access
    - Password - SecureString - Master Password of the Encrypted Key-Value store to access
    - Key - String - Key of the Encrypted Key-Value record to get
    - AsSecureString - SwitchParameter - Flag which indicates that the function must return the decrypted value as a Secure String as opposed to a plaintext string
- Inputs - None
- Outputs
    - String - Decrypted value stored under a key as a plaintext string
    - SecureString - Decrypted value stored under a key as a SecureString
    - null - Unsuccessful operation

### Get-EKVKeys
- Checks whether the provided password is the master password of the provided Encrypted Key-Value store and lists all stored keys
- Parameters
    - Name - String - Name of the Encrypted Key-Value store to access
    - Password - SecureSting - Master Password of the Encrypted Key-Value store to access
- Inputs - None
- Outputs - List<String\> -All keys stored in the EKV store

### Remove-EKVRecord
- Checks whether the provided password is the master password of the provided Encrypted Key-Value store, finds the provided key in given EKV and removes it along with the associated value
- Parameters
    - Name - String - Name of the Encrypted Key-Value store to access
    - Password - SecureString - Master Password of the Encrypted Key-Value store to access
    - Key - String - Key of the Encrypted Key-Value record to remove
- Inputs - None
- Outputs - String - Decrypted value associated with removed key

### Remove-EKVStore
- Checks whether the provided password is the master password of the provided Encrypted Key-Value store and removes the EKV store
- Parameters
    - Name - String - Name of the Encrypted Key-Value store to remove
    - Password - SecureString - Master Password of the Encrypted Key-Value store to remove
    - Force - SwitchParameter - Flag which forces the command to remove the specified Encrypted Key-Value store without prompting the user for confirmation
- Inputs - None
- Outputs - List<(string, string)> - List of all Key-Value records contained in the removed store

### Copy-EKVStore
- Checks whether the provided password is the master password of the provided Encrypted Key-Value store, creates a new Encrypted Key-Value store and copies the contents of the original to the copy
- Parameters
    - Name - String - Name of the Encrypted Key-Value store to copy
    - Password - SecureString - Master Password of the Encrypted Key-Value store to copy
    - CopyName - String - Name of the new copy Encrypted Key-Value store
    - Force - SwitchParameter - Flag which forces the command to copy the specified Encrypted Key-Value store even if the target copy store already exists, overwriting it
- Inputs - None
- Outputs - Boolean - Flag which indicates whether the operation was successful

### Get-EKVStores
- Gets all Encrypted Key-Value (EKV) store names
- Parameters - None
- Inputs - None
- Outputs - List<string\> - List of all EKV store names

### Export-ToUnprotectedFile
- Checks whether the provided password is the master password of the provided Encrypted Key-Value store, decrypts all encrypted records and stores them in a provided .kv plaintext export file
- Parameters
    - Name - String - Name of the Encrypted Key-Value store to export
    - Password - SecureString - Master Password of the Encrypted Key-Value store to export
    - ExportFile - String - Target .kv file to which to export the EKV store
        - If value is not provided it automatically has value "$Name.kv" in caller working directory.
        - If the provided file does not have extension .kv, the extension is automatically appended
- Inputs - None
- Outputs - None

### Import-FromUnprotectedFile
- Creates a new Encrypted Key-Value store and stores all Key-Value records
contained in the provided .kv plaintext file to the new store
- Parameters
    - Name - String - Name of the Encrypted Key-Value store to create
    - Password - SecureString - Master Password of the Encrypted Key-Value store to create
    - ExportFile - String - Path to unprotected file to import to new Encrypted Key-Value store
    - RemoveFile - SwitchParameter - Remove the unprotected file after importing
    - Force - SwitchParameter - Force creation of the new Encrypted Key-Value store even if such already exists, overwriting it
- Inputs - None
- Outputs - Boolean - Flag which indicates whether the operation was successful

### Rename-EKVStore
Checks whether the provided password is the master password of the provided
Encrypted Key-Value store, and renames it to new provided name.
- Parameters
    - Name - Original name of the Encrypted Key-Value store to rename
    - Password - Master Password of the Encrypted Key-Value store to rename
    - NewName - New name of the Encrypted Key-Value Store
- Inputs - None
- Outputs - Boolean - Flag which indicates whether the operation was successful

### Rename-EKVKey
Checks whether the provided password is the master password of the provided
Encrypted Key-Value store, finds the provided key in given EKV and renames it.
- Parameters
    - Name - Name of the Encrypted Key-Value store to access
    - Password - Master Password of the Encrypted Key-Value store to access
    - Key - Key of the Encrypted Key-Value record to rename
    - NewKey - New key of the Encrypted Key-Value record

### Typical usage

```ps1
PS > Import-Module C:\path\to\EKVStore_PS
Loaded command: Add-EKVRecord.ps1
Loaded command: Copy-EKVStore.ps1
Loaded command: Export-ToUnprotectedFile.ps1
Loaded command: Get-EKVKeys.ps1
Loaded command: Get-EKVRecord.ps1
Loaded command: Get-EKVStores.ps1
Loaded command: Import-FromUnprotectedFile.ps1
Loaded command: New-EKVStore.ps1
Loaded command: Remove-EKVRecord.ps1
Loaded command: Remove-EKVStore.ps1
PS > $ekvpass = Read-Host -AsSecureString
********
PS > New-EKVStore -Name test -Password $ekvpass
Created new empty Encrypted Key-Value store
Successfully created new Encrypted Key-Value store test
True
PS > Add-EKVRecord -Name test -Password $ekvpass -Key testkey1 -RawValue testvalue1
Successfully added Encrypted Key-Value under key testkey1
False
PS > Add-EKVRecord -Name test -Password $ekvpass -Key testkey2 -RawValue testvalue2
Successfully added Encrypted Key-Value under key testkey2
False
PS > $testkey1 = Get-EKVRecord -Name test -Password $ekvpass -Key testkey1
Successfully decrypted Encrypted Key-Value under key testkey1
# testkey1 can now be used in other commands like Invoke-RestMethod
```

## Implementation notes

### Physical storage

New-EKVStore command creates an .ekv file in the directory `X/.ekvs/` where X is the directory in which the command source code is located.

Every .ekv file has two sections:
1. Master Password Line
2. Key-Value Lines

_Master Password Line_ contains the cryptographic hash of the master password for the file obtained by [SHA256 hashing algorithm](https://en.wikipedia.org/wiki/SHA-2). Upon EKV store creation the master password is appended by a randomly generated [_salt_](https://en.wikipedia.org/wiki/Salt_(cryptography)) string before hashing. _Salt_ is stored next to the cryptographic hash in the _Master Password Line_ in UTF-8 encoded plaintext delimited from the hash by a single whitespace. Cryptographic hash is stored as UTF-8 encoded string of hexadecimal characters corresponding to the obtained hash bytes.

Each _Key-Value Line_ contains a UTF-8 encoded plaintext key followed by a whitespace and a string of UTF-8 encoded hexadecimal characters corresponding to the output bytes of the cryptographic encoding algorithm.

Example .ekv file:
```
FF442C18CE6AEE420A80FE1D584BC038A460DCC24C16E75EC05B1937E7CD5EC5 6M+//ZMgkPE=
testkey1 9FBD7F9320A1FC753619DA7788CD97DC
testkey2 02556F5344F24154CE034C87600DE636
```

### Master password check

Master password check is performed using the following procedure:
1. Concatenate the provided password and salt obtained from the _Master Password Line_ of the .ekv file
2. Convert the concatenated password to bytes using UTF-8 encoding
3. Create an instance of SHA256 cryptographic hashing algorithm
    - .NET class used is [System.Security.Cryptography.SHA256](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.sha256?view=net-9.0)
4. Obtain the cryptographic hash
    - Cryptographic hash is obtained using [ComputHash](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.hashalgorithm.computehash?view=net-9.0#system-security-cryptography-hashalgorithm-computehash(system-byte())) method call
5. Convert the obtained hash bytes to UTF-8 encoded hexadecimal character string
6. Compare the obtained hexadecimal character string to a master password hash hexadecimal character string obtained from the _Master Password Line_
7. Accept or reject the user provided password

### Record encryption

Each value is encrypted using the [AES cryptographic encoding](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard) encryption algorithm using the following procedure:
1. Generate an Encryption Key and Initialization Vector (IV) for AES encryption algorithm using a Key Derivation Function (KDF)
    - It is important that the KDF is deterministic so that the produced Key and IV values are always the same for the same input parameters
        - KDF used is [PBKDF2](https://datatracker.ietf.org/doc/html/rfc2898#section-5.2) specified by [RFC 2898](https://datatracker.ietf.org/doc/html/rfc2898) standard
        - Input parameters for PBKDF2 are: master password, salt, iteration number (8192) and an underlying pseudorandom number generator function
        - .NET class used as KDF is [System.Security.Cryptography.Rfc2898DeriveBytes](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.rfc2898derivebytes?view=net-9.0)
    - Generated key is 32 bytes long while the IV is 16
2. Create an instance of AES algorithm 
    - .NET class used as an encoder is [System.Security.Cryptography.Aes](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.aes?view=net-9.0)
        - Key Size (property KeySize) is set to 256
        - Mode of operation for symmetric algorithm (property Mode) is set to CBC - [System.Security.Cryptography.CipherMode](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.ciphermode?view=net-9.0)
        - Padding mode for symmetric algorithm (property Padding) is set to PKCS7 - [System.Security.Cryptography.PaddingMode](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.paddingmode?view=net-9.0)
        - Key and Iv properties are set to previously generated Key and IV
3. Create an AES encryptor
    - .NET class used implements the [System.Security.Cryptography.ICryptoTransform](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.icryptotransform?view=net-9.0) interface
    - Obtained by [CreateEncryptor](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.symmetricalgorithm.createencryptor?view=net-9.0#system-security-cryptography-symmetricalgorithm-createencryptor) method call
4. Transform the provided string value to bytes using UTF-8 encoding
5. Encode the value bytes using obtained AES Encryptor
    - Encoded value is obtained using the [TransformFinalBlock](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.icryptotransform.transformfinalblock?view=net-9.0#system-security-cryptography-icryptotransform-transformfinalblock(system-byte()-system-int32-system-int32)) method call
6. Convert the obtained bytes into a hexadecimal character string

### Record decryption

Each value is decrypted using the previously explained AES encoding encryption algorithm using the following procedure:
1. Generate an Encryption Key and Initialization Vector (in the same way as for encryption)
2. Create an instance of AES algorithm (in the same way as for encryption)
3. Create an AES decryptor
    - .NET class used implements the previously mentioned ICryptoTransform interface
    - Obtained by [CreateDecryptor](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.symmetricalgorithm.createdecryptor?view=net-9.0#system-security-cryptography-symmetricalgorithm-createdecryptor) method call
4. Convert the UTF-8 encoded hexadecimal value string to bytes
5. Decode the value bytes using obtained AES Decryptor
    - Decoded value is obtained using the previously mentioned TransformFinalBlock method call
6. Convert the obtained bytes into a UTF-8 encoded plaintext character string

## Author
Petar Železnjak

Zagreb, Croatia, 2025

## Changelog

### v1.2.0
- Added following Cmdlets
    - Rename-EKVStore
    - Rename-EKVKey

### v1.1.1
- Added flag -RemoveFile to Export-FromUnprotectedFile
- Fixed forgotten Cmdlet bindings in:
    - Export-ToUnprotectedFile
    - Get-EKVStores
    - Import-FromUnprotectedFile

### v1.1.0

Added following Cmdlets:
- Copy-EKVStore
- Get-EKVStores
- Export-ToUnprotectedFile
- Import-FromUnprotectedFile

### v1.0.0

Contains Powershell Module with following Cmdlets:
- New-EKVStore
- Add-EKVRecord
- Get-EKVRecord
- Get-EKVKeys
- Remove-EKVRecord
- Remove-EKVStore