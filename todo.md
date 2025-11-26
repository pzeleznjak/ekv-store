# EKV STORE
## TO DO

1. Protect all input values with secure string or prompt with Read-Host -AsSecureString
2. Add key validation - must not contain whitespace and ','
3. Add Export-ToUnprotectedFile
    - decrypts all records from a store and saves them in a provided .kv file
4. Add Import-FromUnprotectedFile
    - creates a new store and stores all records from provided .kv file
5. Edit Get-Help to display as much help as possible
6. Create new Release v1.1.0
7. Disable duplicate key insertion
    - key list after master password - key names are separated by ','
    - each value is in its own line
    - index of key in key list is index of value
8. Enable record grouping
    - group test_account contains test_user and test_password
    - group definitions are in the beginning of .ekv after master password and key list
9. Write README.md
10. Edit .psm1 file to include all needed fields
11. Add all cmdlet metadata/headers/comments/descriptions
12. Implement in C#