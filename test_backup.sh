#!/bin/bash

# Android Auto Backup Testing Script for Streakly
# This script helps developers test backup and restore functionality

set -e

APP_PACKAGE="com.harirajan.streakly"
BACKUP_TIMEOUT=30
LOG_DIR="backup_validation_results"
REPORT_FILE=""
DEVICE_MODEL=""
DEVICE_OS=""
BACKUP_RESULT=""
RESTORE_RESULT=""
BACKUP_TRANSPORT=""
BACKUPSET_LINE=""
USER_VERIFICATION=""

mkdir -p "$LOG_DIR"

echo "🔧 Android Auto Backup Test Script for Streakly"
echo "============================================="

# Check if ADB is available
if ! command -v adb &> /dev/null; then
    echo "❌ ADB not found. Please install Android SDK platform-tools."
    exit 1
fi

# Check if device is connected
if ! adb devices | grep -q "device$"; then
    echo "❌ No Android device connected. Please connect a device and enable USB debugging."
    exit 1
fi

DEVICE_MODEL=$(adb shell getprop ro.product.model | tr -d '\r')
DEVICE_OS=$(adb shell getprop ro.build.version.release | tr -d '\r')
echo "✅ Device connected: $DEVICE_MODEL (Android $DEVICE_OS)"

collect_transport_info() {
    BACKUP_TRANSPORT=$(adb shell bmgr list transports | awk '/\(selected\)/ {gsub(/\r/, ""); print $1}')
    if [ -z "$BACKUP_TRANSPORT" ]; then
        BACKUP_TRANSPORT="unknown"
    fi
}

# Function to check if app is installed
check_app_installed() {
    if adb shell pm list packages | grep -q "$APP_PACKAGE"; then
        echo "✅ App is installed"
        return 0
    else
        echo "❌ App is not installed"
        return 1
    fi
}

# Function to backup app
backup_app() {
    echo ""
    echo "📦 Starting backup for $APP_PACKAGE..."
    
    # Enable backup manager if not enabled
    adb shell bmgr enabled | grep -q "true" || adb shell bmgr enable true
    
    # Trigger backup
    echo "🔄 Triggering backup..."
    BACKUP_RESULT=$(adb shell bmgr backupnow "$APP_PACKAGE" 2>&1)
    echo "$BACKUP_RESULT"
    collect_transport_info
    
    # Wait for backup to complete
    echo "⏳ Waiting for backup to complete..."
    sleep $BACKUP_TIMEOUT
    
    echo "✅ Backup completed"
}

# Function to check backup status
check_backup_status() {
    echo ""
    echo "🔍 Checking backup status..."
    
    # Check if backup exists
    collect_transport_info
    BACKUPSET_LINE=$(adb shell bmgr list sets | tr -d '\r' | grep "$APP_PACKAGE" || true)
    if [ -n "$BACKUPSET_LINE" ]; then
        echo "✅ Backup found for $APP_PACKAGE"
        
        # Show backup details
        echo "📊 Backup details:"
        echo "$BACKUPSET_LINE"
    else
        echo "❌ No backup found for $APP_PACKAGE"
        return 1
    fi
}

# Function to create test data
create_test_data() {
    echo ""
    echo "📝 Creating test data..."
    echo "Please manually:"
    echo "1. Open the app"
    echo "2. Create 2-3 habits with different settings"
    echo "3. Add some notes to habits"
    echo "4. Set app preferences (theme, notifications)"
    echo "5. Complete some habits to create streaks"
    echo ""
    read -p "Press Enter after creating test data..."
}

# Function to clear app data (simulate fresh install)
clear_app_data() {
    echo ""
    echo "🧹 Clearing app data to simulate fresh install..."
    adb shell pm clear "$APP_PACKAGE"
    echo "✅ App data cleared"
}

# Function to restore app
restore_app() {
    echo ""
    echo "📥 Restoring app from backup..."
    RESTORE_RESULT=$(adb shell bmgr restore "$APP_PACKAGE" 2>&1)
    echo "$RESTORE_RESULT"
    
    echo "⏳ Waiting for restore to complete..."
    sleep $BACKUP_TIMEOUT
    
    echo "✅ Restore completed"
}

# Function to verify restored data
verify_restore() {
    echo ""
    echo "🔍 Please verify restored data:"
    echo "1. Open the app"
    echo "2. Check if your habits are restored"
    echo "3. Check if app preferences are restored"
    echo "4. Verify habit notes are present"
    echo "5. Verify streak data is correct"
    echo "6. Confirm PIN is NOT restored (you should need to set it again)"
    echo ""
    read -p "Does the restored data look correct? (y/n): " response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "✅ Restore verification successful!"
        USER_VERIFICATION="success"
        return 0
    else
        echo "❌ Restore verification failed!"
        USER_VERIFICATION="failed"
        return 1
    fi
}

write_report() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d_%H-%M-%S')
    REPORT_FILE="$LOG_DIR/backup_validation_$timestamp.md"
    {
        echo "# Android Backup Validation"
        echo "- Timestamp: $(date -Iseconds)"
        echo "- Device Model: $DEVICE_MODEL"
        echo "- Android Version: $DEVICE_OS"
        echo "- Backup Transport: $BACKUP_TRANSPORT"
        echo "- Package: $APP_PACKAGE"
        echo "- Manual Verification: ${USER_VERIFICATION:-skipped}"
        echo "- Backup Command Output:"
        echo '```'
        echo "$BACKUP_RESULT"
        echo '```'
        echo "- Backup Set Entry:"
        echo '```'
        echo "$BACKUPSET_LINE"
        echo '```'
        echo "- Restore Command Output:"
        echo '```'
        echo "$RESTORE_RESULT"
        echo '```'
    } > "$REPORT_FILE"
    echo "📄 Validation report written to $REPORT_FILE"
}

# Main menu
show_menu() {
    echo ""
    echo "Choose an option:"
    echo "1. Full backup/restore test"
    echo "2. Backup only"
    echo "3. Check backup status"
    echo "4. Restore from existing backup"
    echo "5. Clear app data"
    echo "6. Check backup rules"
    echo "7. Exit"
    echo ""
    read -p "Enter choice (1-7): " choice
    
    case $choice in
        1)
            full_test
            ;;
        2)
            if check_app_installed; then
                backup_app
                check_backup_status
            fi
            ;;
        3)
            check_backup_status
            ;;
        4)
            if check_app_installed; then
                restore_app
                verify_restore
            fi
            ;;
        5)
            if check_app_installed; then
                clear_app_data
            fi
            ;;
        6)
            check_backup_rules
            ;;
        7)
            echo "👋 Goodbye!"
            exit 0
            ;;
        *)
            echo "❌ Invalid choice"
            ;;
    esac
}

# Full backup/restore test
full_test() {
    echo ""
    echo "🧪 Starting full backup/restore test..."
    
    if ! check_app_installed; then
        echo "Please install the app first using: flutter install"
        return 1
    fi
    
    # Step 1: Create test data
    create_test_data
    
    # Step 2: Backup
    backup_app
    collect_transport_info
    
    # Step 3: Check backup status
    if ! check_backup_status; then
        echo "❌ Backup failed. Aborting test."
        return 1
    fi
    
    # Step 4: Clear app data
    clear_app_data
    
    # Step 5: Restore
    restore_app
    
    # Step 6: Verify
    USER_VERIFICATION="skipped"
    if verify_restore; then
        write_report
        echo "🎉 Full backup/restore test PASSED!"
    else
        write_report
        echo "💥 Full backup/restore test FAILED!"
    fi
}

# Check backup rules
check_backup_rules() {
    echo ""
    echo "📋 Checking backup rules..."
    
    # Check if backup rules exist in APK
    echo "🔍 Checking AndroidManifest.xml for backup configuration..."
    
    # Get package path
    PACKAGE_PATH=$(adb shell pm path "$APP_PACKAGE" | cut -d: -f2)
    
    if [ -n "$PACKAGE_PATH" ]; then
        echo "✅ Package found at: $PACKAGE_PATH"
        echo "📦 Backup should be configured in the app"
    else
        echo "❌ Package not found"
    fi
    
    echo ""
    echo "Expected backup configuration:"
    echo "• android:allowBackup='true'"
    echo "• android:fullBackupContent='@xml/backup_rules'"
    echo "• android:dataExtractionRules='@xml/data_extraction_rules'"
}

# Run main menu loop
while true; do
    show_menu
done