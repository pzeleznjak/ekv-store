# EKV STORE
## TO DO

2. Create a release v1.2.0
3. Implement in C#
4. Check return values
4. Modify .ekv so that first line denotes a .ekv version
5. Create a .ekv version migrating tool
6. Disable duplicate key insertion
    - key list after master password - key names are separated by ','
    - each value is in its own line
    - index of key in key list is index of value
7. Enable record grouping
    - group test_account contains test_user and test_password
    - group definitions are in the beginning of .ekv after master password and key list
8. Rename Export-EKVToUnprotectedFile and Import-EKVFromUnprotectedFile
9. Add .ekv metadata after master password line
    - date created
    - created by
    - description
10. Implement Get-EKVStoreMetadata
11. Add metadata to EKV records
    - date created
    - description
12. Forbid any and all non-alphanumeric characters for key name
13. Create a release v2.0.0
14. Write README.md section about theory behind cryptographic hashing, salt and encoding