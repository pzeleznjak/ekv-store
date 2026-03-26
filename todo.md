# EKV STORE

## TO DO

1. Rewrite in C#
2. Refactor rewritten code
3. Check return values
4. Modify .ekv so that first line denotes a .ekv version
5. Create an .ekv version migrating tool

   * ability to translate between versions of .ekv files
6. Disable duplicate key insertion

   * key list after master password - key names are separated by ','
   * each value is in its own line
   * index of key in key list is index of value
7. Enable record grouping

   * group test\_account contains test\_user and test\_password
   * group definitions are in the beginning of .ekv after master password and key list
8. Add .ekv metadata after master password line

   * date created
   * created by
   * description
9. Implement Get-EKVStoreMetadata
10. Add metadata to EKV records

    * date created
    * description
11. Forbid any and all non-alphanumeric characters for key name except - and \_
12. Create a release v2.0.0
13. Fix CopyName default value in Copy-EKVStore in Powershell
14. Fix ToClipboard returning value in Get-EKVRecord
15. Create release v1.2.2
16. Implement loading in-memory
17. Implement Get-EKVRecord with filter (regex)
18. Create a release v2.1.0
19. Write README.md section about theory behind cryptographic hashing, salt and encoding

