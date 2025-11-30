# EKV STORE
## TO DO

1. Add -RemoveFile flag to Import-FromUnprotected file which removes the import .kv file
2. Create a release v1.1.1
3. Disable duplicate key insertion
    - key list after master password - key names are separated by ','
    - each value is in its own line
    - index of key in key list is index of value
4. Enable record grouping
    - group test_account contains test_user and test_password
    - group definitions are in the beginning of .ekv after master password and key list
5. Rename Export-EKVToUnprotectedFile and Import-EKVFromUnprotectedFile
6. Create a release v1.2.0
7. Implement in C#
8. Create a release v2.0.0
9. Write README.md section about theory behind cryptographic hashing, salt and encoding