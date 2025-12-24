import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/habit.dart';
import '../utils/icon_renderer.dart';

class WidgetService {
  static const MethodChannel _channel =
      MethodChannel('com.harirajan.streakly/widget_v2');

  /// Initialize listener for updates from native side
  void initialize(Function(String) onWidgetAction) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onWidgetAction') {
        final String habitId = call.arguments as String;
        debugPrint("WidgetService: Received update for habit $habitId");
        onWidgetAction(habitId);
      }
    });
  }

  /// Helper to add icon image data to the habit JSON
  Future<Map<String, dynamic>> _enrichHabitData(Habit habit,
      {bool isDarkMode = true}) async {
    final Map<String, dynamic> data = habit.toWidgetJson();
    data['isDarkMode'] = isDarkMode; // Inject theme
    try {
      final Uint8List? iconBytes = await IconRenderer.renderIconToPng(
        habit.icon,
        habit.color,
        size: 100, // Reasonable resolution for widget
      );

      if (iconBytes != null) {
        data['iconBase64'] = base64Encode(iconBytes);
      }
    } catch (e) {
      debugPrint('Error rendering icon for widget: $e');
    }
    return data;
  }

  /// Set the mapping for a specific widget instance to a habit
  Future<void> setWidgetMapping(int appWidgetId, Habit habit,
      {bool isDarkMode = true}) async {
    try {
      final enrichedData =
          await _enrichHabitData(habit, isDarkMode: isDarkMode);
      await _channel.invokeMethod('setWidgetMapping', {
        'appWidgetId': appWidgetId,
        'habit': jsonEncode(enrichedData),
      });
    } catch (e) {
      print('Failed to set widget mapping: $e');
    }
  }

  /// Update all widgets mapped to this habit
  Future<void> updateWidgetForHabit(Habit habit,
      {bool isDarkMode = true}) async {
    try {
      final enrichedData =
          await _enrichHabitData(habit, isDarkMode: isDarkMode);
      await _channel.invokeMethod('updateWidgetForHabit', {
        'habitId': habit.id,
        'habit': jsonEncode(enrichedData),
      });
    } catch (e) {
      print('Failed to update widget for habit: $e');
    }
  }

  /// Remove mapping for a specific widget ID
  Future<void> clearWidgetMapping(int appWidgetId) async {
    try {
      await _channel.invokeMethod('clearWidgetMapping', {
        'appWidgetId': appWidgetId,
      });
    } catch (e) {
      print('Failed to clear widget mapping: $e');
    }
  }

  Future<List<String>> getPendingWidgetActions() async {
    try {
      final List<dynamic>? result =
          await _channel.invokeMethod('getPendingActions');
      if (result != null) {
        return result.cast<String>();
      }
    } catch (e) {
      debugPrint('Error getting pending widget actions: $e');
    }
    return [];
  }

  Future<void> clearPendingWidgetActions() async {
    try {
      await _channel.invokeMethod('clearPendingActions');
    } catch (e) {
      debugPrint('Error clearing pending widget actions: $e');
    }
  }

  /// Notify native that a habit was deleted (to clear any widgets mapped to it)
  Future<void> notifyHabitDeleted(String habitId) async {
    try {
      await _channel.invokeMethod('notifyHabitDeleted', {
        'habitId': habitId,
      });
    } catch (e) {
      debugPrint('Error notifying habit deletion: $e');
    }
  }

  /// Sync list of valid habit IDs to clean up "zombies" from widget storage
  Future<void> syncValidHabitIds(List<String> validIds) async {
    try {
      debugPrint(
          'WidgetService: Syncing ${validIds.length} valid habits to native');
      await _channel.invokeMethod('syncValidHabitIds', {
        'validIds': validIds,
      });
    } catch (e) {
      debugPrint('Error syncing valid habit IDs: $e');
    }
  }

  /// Finish widget configuration with selected habit
  Future<void> finishWithSelectedHabit(
      int appWidgetId, String habitId, Habit habit) async {
    try {
      debugPrint(
          '🔵 finishWithSelectedHabit called: appWidgetId=$appWidgetId, habitId=$habitId, habitName=${habit.name}');

      final enrichedData = await _enrichHabitData(habit);
      debugPrint('🔵 Enriched data prepared, calling native method...');

      await _channel.invokeMethod('finishWithSelectedHabit', {
        'habitId': habit.id,
        'habit': jsonEncode(enrichedData),
        'appWidgetId': appWidgetId,
      });

      debugPrint('✅ finishWithSelectedHabit completed successfully');
    } catch (e) {
      debugPrint('❌ Error finishing widget configuration: $e');
    }
  }

  /// Get widget configuration launch details (if any)
  Future<Map<String, dynamic>?> getWidgetConfig() async {
    try {
      final result = await _channel.invokeMethod('getWidgetConfig');
      if (result != null && result is Map) {
        return Map<String, dynamic>.from(result);
      }
    } catch (e) {
      debugPrint('Error getting widget config: $e');
    }
    return null;
  }
}
