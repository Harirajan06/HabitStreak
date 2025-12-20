import 'package:flutter/material.dart';
import 'services/notification_service.dart';
import 'services/hive_service.dart';

/// Initializes Hive and the NotificationService and schedules saved reminders.
Future<void> initializeNotificationService() async {
  try {
    // Ensure Hive boxes are opened before scheduling reminders
    await HiveService.instance.init();

    // Initialize notifications (creates channels, timezone, requests permissions)
    await NotificationService().initNotifications();

    // Schedule reminders for all saved habits that have reminders configured
    await NotificationService().scheduleAllSavedHabits();
  } catch (e) {
    debugPrint('⚠️ initializeNotificationService failed: $e');
  }
}
