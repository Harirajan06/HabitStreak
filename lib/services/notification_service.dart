import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../services/hive_service.dart';
import '../models/habit.dart';

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService _instance =
      NotificationService._privateConstructor();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'streakly_daily_channel';
  static const String _channelName = 'Streakly Reminders';
  static const String _channelDescription =
      'Daily habit reminders from Streakly';

  Future<void> initNotifications({bool requestPermissions = true}) async {
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();

      const initSettings =
          InitializationSettings(android: androidInit, iOS: iosInit);

      await _plugin.initialize(initSettings);

      // Timezone setup using flutter_timezone
      try {
        tzdata.initializeTimeZones();
        String localTz = 'UTC';
        try {
          localTz = await FlutterTimezone.getLocalTimezone();
          debugPrint('📍 Device timezone: $localTz');
        } catch (e) {
          debugPrint('⚠️ Could not get device timezone, using UTC: $e');
        }

        try {
          tz.setLocalLocation(tz.getLocation(localTz));
          debugPrint('✅ Timezone set to $localTz');
        } catch (e) {
          // Fallback to UTC
          tz.setLocalLocation(tz.UTC);
          debugPrint('⚠️ Failed to set $localTz, using UTC: $e');
        }
      } catch (e) {
        debugPrint('⚠️ Timezone initialization failed: $e');
      }

      // Create Android channel
      const androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
      );

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // Request platform permissions if requested
      if (requestPermissions) {
        await this.requestPermissions();
      }
      debugPrint('✅ NotificationService initialized');
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
    }
  }

  Future<void> requestPermissions() async {
    await _requestPermissions();
    await _requestAndroidPermissions(requestExactAlarm: true);
  }

  Future<void> _requestAndroidPermissions(
      {bool requestExactAlarm = false}) async {
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      // Request the runtime notification permission on Android 13+
      try {
        await androidImpl?.requestNotificationsPermission();
        debugPrint('✅ Requested Android notification permission');
      } catch (e) {
        debugPrint(
            '⚠️ Android notification permission request not available: $e');
      }

      // If the app needs exact alarms, prompt the user via the plugin helper.
      if (requestExactAlarm) {
        try {
          debugPrint('➡️ Invoking requestExactAlarmsPermission()');
          await androidImpl?.requestExactAlarmsPermission();
          debugPrint('✅ Requested Android exact alarms permission');
        } catch (e) {
          debugPrint('⚠️ Exact alarms permission request not available: $e');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Failed to request Android permissions: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      // Android permissions are managed via AndroidManifest or platform channels.
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('⚠️ Error requesting notification permissions: $e');
    }
  }

  int _normalizeId(int id) => id & 0x7fffffff;

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      ),
    );
  }

  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
  }) async {
    try {
      await _plugin.show(id, title, body, _notificationDetails(),
          payload: payload);
    } catch (e) {
      debugPrint('❌ Failed to show notification: $e');
    }
  }

  Future<void> scheduleNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
    required DateTime scheduledDateTime,
    DateTimeComponents? matchComponents,
  }) async {
    try {
      final tzDateTime = tz.TZDateTime.from(scheduledDateTime, tz.local);
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDateTime,
        _notificationDetails(),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchComponents,
      );
    } catch (e) {
      debugPrint('❌ Failed to schedule notification: $e');
    }
  }

  int _generateNotificationId(String habitId, int index) {
    // Combine habitId hash and index to generate unique ID
    return _normalizeId(habitId.hashCode ^ (index * 397));
  }

  Future<void> scheduleHabitReminder(
      int id, String title, String body, TimeOfDay time,
      {bool forceNextDay = false}) async {
    try {
      final now = DateTime.now();
      var scheduled =
          DateTime(now.year, now.month, now.day, time.hour, time.minute);

      // If time has passed OR we want to force next day (e.g. habit completed today)
      if (forceNextDay || !scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await scheduleNotification(
        id: id,
        title: title,
        body: body,
        scheduledDateTime: scheduled,
        matchComponents: DateTimeComponents.time,
      );

      debugPrint(
          '🗓️ Scheduled reminder id=$id at ${scheduled.toString()} (forceNextDay: $forceNextDay)');
    } catch (e) {
      debugPrint('❌ Failed to schedule reminder $id: $e');
    }
  }

  Future<void> scheduleReminderForHabit(Habit habit) async {
    // Cancel existing reminders for this habit first
    await cancelHabitReminders(habit.id);

    if (habit.reminderTimes.isEmpty) return;

    final isCompleted = habit.isFullyCompletedToday();

    if (isCompleted) {
      debugPrint(
          '🔕 Habit ${habit.id} is fully completed today; skipping reminder scheduling.');
      return;
    }

    for (int i = 0; i < habit.reminderTimes.length; i++) {
      final time = habit.reminderTimes[i];
      final id = _generateNotificationId(habit.id, i);
      final title = habit.name;
      final body = 'Time to complete your habit: ${habit.name}';

      await scheduleHabitReminder(id, title, body, time,
          forceNextDay: false);
    }
  }

  Future<void> cancelHabitReminders(String habitId) async {
    // Try cancelling potential IDs (assuming max 20 reminders per habit to be safe)
    for (int i = 0; i < 20; i++) {
      try {
        final id = _generateNotificationId(habitId, i);
        // We cancel blindly; if it doesn't exist, it's fine.
        await _plugin.cancel(id);
      } catch (e) {
        // Ignore
      }
    }
    // Also try cancelling old single reminder ID style just in case of migration
    try {
      await _plugin.cancel(_normalizeId(habitId.hashCode));
    } catch (_) {}

    debugPrint('🛑 Cancelled reminders for habit $habitId');
  }

  // Deprecated single ID cancel, kept for compatibility if called elsewhere but redirected
  Future<void> cancelReminder(int habitIdHash) async {
    await _plugin.cancel(_normalizeId(habitIdHash));
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
      debugPrint('🧹 Cancelled all notifications');
    } catch (e) {
      debugPrint('❌ Failed to cancel all notifications: $e');
    }
  }

  /// Schedule reminders for all saved habits that have reminderTime set.
  Future<void> scheduleAllSavedHabits() async {
    try {
      final habits = HiveService.instance.getHabits();
      for (final habit in habits) {
        if (habit.reminderTimes.isNotEmpty) {
          await scheduleReminderForHabit(habit);
        }
      }
      debugPrint('✅ Scheduled reminders for saved habits');
    } catch (e) {
      debugPrint('⚠️ Failed to schedule saved habit reminders: $e');
    }
  }

  /// Returns the list of pending scheduled notification requests from the plugin.
  /// Returns an empty list on error.
  Future<List<PendingNotificationRequest>>
      getPendingNotificationRequests() async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending;
    } catch (e) {
      debugPrint('⚠️ Failed to fetch pending notifications: $e');
      return <PendingNotificationRequest>[];
    }
  }
}
