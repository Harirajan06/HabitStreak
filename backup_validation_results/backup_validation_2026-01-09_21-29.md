# Android Backup Validation
- Timestamp: 2026-01-09T21:29:16+05:30
- Device Model: Vivo Y39 5G (V2443)
- Android Version: 15
- Backup Transport: com.google.android.gms/.backup.BackupTransportService
- Package: com.harirajan.streakly
- Manual Verification: success

- Backup Command Output:
```
Backup finished with result: Success
Package com.harirajan.streakly with result: Success
Size: 685056 bytes
```

- Backup Set Entry:
```
33c0c4d5c555a921 : Vivo Y39 5G
```

- Restore Command Output:
```
restoreFinished: 0
done
```

- Notes:
  - Initial test failed due to missing `app_flutter` directory in backup rules.
  - Fixed by adding `<include domain="root" path="app_flutter" />` to `backup_rules.xml` and `data_extraction_rules.xml`.
  - Also explicitly set `disableIfNoEncryptionCapabilities="false"` in `data_extraction_rules.xml` to ensure backup works even if transport doesn't support encryption during testing.
