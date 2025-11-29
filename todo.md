# EKV STORE
## TO DO

1. Create new Release v1.1.0
2. Disable duplicate key insertion
    - key list after master password - key names are separated by ','
    - each value is in its own line
    - index of key in key list is index of value
3. Enable record grouping
    - group test_account contains test_user and test_password
    - group definitions are in the beginning of .ekv after master password and key list
4. Edit .psm1 file to include all needed fields
5. Add all cmdlet metadata/headers/comments/descriptions
6. Implement in C#
7. Write README.md section about theory behind cryptographic hashing, salt and encoding