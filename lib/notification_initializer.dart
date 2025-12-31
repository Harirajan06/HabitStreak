import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/notification_service.dart';
import 'services/hive_service.dart';

/// Initializes Hive and the NotificationService and schedules saved reminders.
Future<void> initializeNotificationService() async {
  try {
    // Ensure Hive boxes are opened before scheduling reminders
    await HiveService.instance.init();

    // Check if user has seen onboarding
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    // Initialize notifications (creates channels, timezone)
    // Defer permissions if user hasn't seen onboarding yet
    await NotificationService().initNotifications(
      requestPermissions: hasSeenOnboarding,
    );

    // Schedule reminders for all saved habits that have reminders configured
    await NotificationService().scheduleAllSavedHabits();
  } catch (e) {
    debugPrint('⚠️ initializeNotificationService failed: $e');
  }
}
