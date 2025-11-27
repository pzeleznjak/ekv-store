# EKV STORE
## TO DO

1. Add key validation - must not contain whitespace and ','
2. Add Export-ToUnprotectedFile
    - decrypts all records from a store and saves them in a provided .kv file
3. Add Import-FromUnprotectedFile
    - creates a new store and stores all records from provided .kv file
4. Edit Get-Help to display as much help as possible
5. Create new Release v1.1.0
6. Disable duplicate key insertion
    - key list after master password - key names are separated by ','
    - each value is in its own line
    - index of key in key list is index of value
7. Enable record grouping
    - group test_account contains test_user and test_password
    - group definitions are in the beginning of .ekv after master password and key list
8. Write README.md
9. Edit .psm1 file to include all needed fields
10. Add all cmdlet metadata/headers/comments/descriptions
11. Implement in C#