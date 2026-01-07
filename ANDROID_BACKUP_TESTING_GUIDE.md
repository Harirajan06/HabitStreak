# Android Auto Backup Implementation - Testing Guide

## 🎯 Overview

This implementation provides comprehensive Android Auto Backup support for Streakly, ensuring user data is safely backed up while protecting sensitive information like PIN authentication data.

## 📋 What's Included in Backup

### ✅ **Data that WILL be backed up:**
- **Hive Databases** (stored in app's internal storage):
  - `habits_box.hive` - User habits and streak data
  - `notes_box.hive` - Habit notes and reflections
  - `users_box.hive` - User profiles and preferences
  - `settings_box.hive` - App settings and configurations
  - `moods_box.hive` - User mood entries
  - `purchases_box.hive` - Purchase history (but not device-specific entitlements)

- **Shared Preferences**:
  - General app preferences
  - Theme settings
  - Feature toggles

### 🔒 **Data that will NOT be backed up:**
- **Flutter Secure Storage** - PIN authentication data (salt, hash, iterations)
- **Widget Preferences** - Device-specific widget configurations
- **RevenueCat Device Data** - Device-specific purchase entitlements
- **Notification Plugin Data** - Device-specific notification settings
- **Cache Directories** - Temporary files

## 🛠 Implementation Details

### 1. **AndroidManifest.xml Changes**
```xml
<!-- Added for Android 12+ compliance -->
android:dataExtractionRules="@xml/data_extraction_rules"
```

### 2. **backup_rules.xml (Android 11 and lower)**
Enhanced with proper exclusions for sensitive data while maintaining compatibility.

### 3. **data_extraction_rules.xml (Android 12+)**
Separate rules for cloud backup vs device-to-device transfer:
- **Cloud Backup**: More restrictive, requires encryption capabilities
- **Device Transfer**: Slightly more permissive for device migrations

## 🧪 Real-Time Testing Guide

### Prerequisites
1. **Two Android devices** (or emulators) running Android 6.0+
2. **Same Google account** on both devices
3. **Backup enabled** in device settings
4. **WiFi connection** for automatic backups

### Test Scenarios

#### **Scenario 1: Automatic Backup Test**
1. **Setup Initial Data**:
   ```bash
   # Install and open app on Device A
   flutter install
   ```
   - Create 3-5 habits with different reminder times
   - Add notes to some habits
   - Set a PIN lock
   - Change app theme/settings
   - Complete some habits to build streaks

2. **Trigger Backup** (choose one method):
   ```bash
   # Method 1: Manual backup via ADB
   adb shell bmgr backupnow com.harirajan.streakly
   
   # Method 2: Wait for automatic backup (24 hours + idle + WiFi)
   # Method 3: Force backup via developer options
   ```

3. **Verify Backup Status**:
   ```bash
   # Check if backup completed
   adb shell dumpsys backup
   
   # Check backup data size
   adb shell bmgr list transports
   ```

#### **Scenario 2: Restore Test**
1. **Install on Device B**:
   ```bash
   # Install app on Device B (same Google account)
   flutter install
   ```

2. **Check Auto-Restore**:
   - App should automatically restore habits, notes, settings
   - PIN should NOT be restored (user needs to set new PIN)
   - Widget configs should NOT be restored
   - Premium status should be restored but needs re-validation

3. **Verify Data Integrity**:
   - ✅ All habits present with correct names and settings
   - ✅ Habit notes preserved
   - ✅ App theme/settings restored
   - ✅ Streak data preserved
   - ❌ PIN authentication reset (expected)
   - ❌ Widget configurations reset (expected)

#### **Scenario 3: Device-to-Device Transfer Test**
1. **Use Android Setup Transfer**:
   - Factory reset Device B
   - During setup, choose "Copy from another device"
   - Select Device A via cable/wireless

2. **Verify Transfer**:
   - More data should transfer compared to cloud backup
   - Still no PIN/sensitive data transfer
   - Purchase data should transfer better

#### **Scenario 4: Backup Size Test**
1. **Check Backup Size Limits**:
   ```bash
   # Monitor backup size (should be under 25MB)
   adb shell bmgr fullbackup com.harirajan.streakly
   ```

2. **Add Large Data**:
   - Create 100+ habits
   - Add extensive notes
   - Verify backup still works

### Testing Commands

#### **Backup Commands**
```bash
# Enable backup on device
adb shell bmgr enabled

# Trigger immediate backup
adb shell bmgr backupnow com.harirajan.streakly

# Check backup status
adb shell bmgr list sets

# View backup data
adb shell bmgr list transports
```

#### **Restore Commands**
```bash
# Clear app data (simulates fresh install)
adb shell pm clear com.harirajan.streakly

# Trigger restore
adb shell bmgr restore com.harirajan.streakly

# Check restore status
adb shell bmgr list sets
```

#### **Debug Commands**
```bash
# View backup logs
adb logcat -s BackupManagerService

# Check backup files
adb shell run-as com.harirajan.streakly ls -la

# View backup rules
adb shell run-as com.harirajan.streakly cat files/backup_state
```

### Expected Results

#### ✅ **Successful Test Indicators**:
- Habits restore with correct names, frequencies, and reminder times
- Habit notes are preserved
- App theme and settings transfer correctly
- Streak history is maintained
- Premium status is restored (may need re-validation)
- No error logs related to backup/restore
- App launches normally after restore

#### ⚠️ **Expected Behavior**:
- PIN authentication requires re-setup (security feature)
- Widgets need re-configuration (device-specific)
- Notification schedules may need refresh
- First launch after restore may be slightly slower

#### ❌ **Failure Indicators**:
- App crashes after restore
- Missing habit data
- Corrupted database files
- Backup size exceeds 25MB
- Sensitive data inappropriately restored

### Production Validation

#### **Before Release**:
1. Test on multiple Android versions (API 24-35)
2. Test with large datasets (50+ habits)
3. Test backup/restore multiple times
4. Verify no sensitive data in Google Drive backups

#### **Monitoring in Production**:
- Monitor crash reports related to backup/restore
- Check for user reports of data loss
- Monitor backup success rates via analytics

## 🔍 Troubleshooting

### Common Issues:

1. **Backup Not Triggering**:
   - Check WiFi connection
   - Verify backup is enabled in Settings
   - Ensure 24 hours have passed since last backup
   - Try manual trigger via ADB

2. **Restore Not Working**:
   - Verify same Google account
   - Check if app was backed up on original device
   - Clear app data and reinstall

3. **Missing Data After Restore**:
   - Check if data was properly excluded (expected)
   - Verify backup rules syntax
   - Check backup size limits

4. **App Crashes After Restore**:
   - Check for corrupted backup data
   - Verify database compatibility
   - Review backup/restore logs

### Log Analysis:
```bash
# Key logs to monitor
adb logcat -s "BackupManagerService" | grep "streakly"
adb logcat -s "RestoreEngine" | grep "streakly"
```

## 🎉 Success Metrics

Your implementation is successful when:
- ✅ User data seamlessly transfers between devices
- ✅ Sensitive authentication data remains secure (not backed up)
- ✅ Backup size stays under 25MB limit
- ✅ No user complaints about data loss during device transfers
- ✅ App maintains functionality after restore operations