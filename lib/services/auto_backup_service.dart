import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'export_import_service.dart';
import 'premium_service.dart';

class AutoBackupService {
  static AutoBackupService? _instance;
  static AutoBackupService get instance => _instance ??= AutoBackupService._();

  AutoBackupService._();

  static const String _settingsBoxName = 'settings_box';
  static const String _keyAutoBackupEnabled = 'autoBackupEnabled';
  static const String _keyLastBackupTime = 'lastBackupTime';

  Future<void> init() async {
    // Hive should be initialized before calling this
  }

  bool get isAutoBackupEnabled {
    final box = Hive.box(_settingsBoxName);
    return box.get(_keyAutoBackupEnabled, defaultValue: false);
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    final box = Hive.box(_settingsBoxName);
    await box.put(_keyAutoBackupEnabled, enabled);
  }

  DateTime? get lastBackupTime {
    final box = Hive.box(_settingsBoxName);
    final timeStr = box.get(_keyLastBackupTime);
    if (timeStr != null) {
      return DateTime.tryParse(timeStr);
    }
    return null;
  }

  Future<void> performBackupIfNeeded() async {
    if (!isAutoBackupEnabled) return;

    // Double check premium status to be sure
    if (!PremiumService.instance.isPremium) return;

    final last = lastBackupTime;
    final now = DateTime.now();

    // Check if 24 hours have passed
    if (last == null || now.difference(last).inHours >= 24) {
      try {
        debugPrint('🔄 Performing Auto Backup...');
        final file = await ExportImportService.instance.exportToFile(
          fileName: 'streakly_auto_backup_${now.toIso8601String()}.json',
        );

        final box = Hive.box(_settingsBoxName);
        await box.put(_keyLastBackupTime, now.toIso8601String());

        debugPrint('✅ Auto Backup success: ${file.path}');

        // Optionally clean up old backups here (keep last 5?)
        await _cleanupOldBackups();
      } catch (e) {
        debugPrint('❌ Auto Backup failed: $e');
      }
    } else {
      debugPrint(
          '⏳ Auto Backup skipped (Last backup was ${now.difference(last).inHours} hours ago)');
    }
  }

  Future<void> _cleanupOldBackups() async {
    try {
      final docs = await ExportImportService.instance.getDocumentsDirectory();
      final dir = Directory(docs.path);
      final files = dir.listSync();

      // Filter for auto backup files
      final backupFiles = files.where((f) {
        final name = f.path.split('/').last;
        return name.startsWith('streakly_auto_backup_') &&
            name.endsWith('.json');
      }).toList();

      // Sort by date (newest first)
      backupFiles.sort((a, b) {
        final statA = a.statSync();
        final statB = b.statSync();
        return statB.modified.compareTo(statA.modified);
      });

      // Keep only last 5
      if (backupFiles.length > 5) {
        for (int i = 5; i < backupFiles.length; i++) {
          await backupFiles[i].delete();
          debugPrint('🗑️ Deleted old backup: ${backupFiles[i].path}');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error cleaning old backups: $e');
    }
  }
}
