# EKV STORE
## TO DO

1. Implement in C#
4. Check return values
4. Modify .ekv so that first line denotes a .ekv version
5. Create an .ekv version migrating tool
    - ability to translate between versions of .ekv files
6. Disable duplicate key insertion
    - key list after master password - key names are separated by ','
    - each value is in its own line
    - index of key in key list is index of value
7. Enable record grouping
    - group test_account contains test_user and test_password
    - group definitions are in the beginning of .ekv after master password and key list
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
14. Implement loading in-memory
15. Create a release v2.1.0
14. Write README.md section about theory behind cryptographic hashing, salt and encoding