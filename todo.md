# EKV STORE
## TO DO

1. Add -Force to Remove-EKVStore
2. Edit Get-Help to display as much help as possible
3. Create new Release v1.1.0
4. Disable duplicate key insertion
    - key list after master password - key names are separated by ','
    - each value is in its own line
    - index of key in key list is index of value
5. Enable record grouping
    - group test_account contains test_user and test_password
    - group definitions are in the beginning of .ekv after master password and key list
6. Write README.md
7. Edit .psm1 file to include all needed fields
8. Add all cmdlet metadata/headers/comments/descriptions
9. Implement in C#