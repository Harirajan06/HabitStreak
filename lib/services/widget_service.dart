import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/habit.dart';

class WidgetService {
  static const MethodChannel _channel =
      MethodChannel('com.example.Streakly/widget');

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

  /// Set the mapping for a specific widget instance to a habit
  Future<void> setWidgetMapping(int appWidgetId, Habit habit) async {
    try {
      await _channel.invokeMethod('setWidgetMapping', {
        'appWidgetId': appWidgetId,
        'habit': jsonEncode(habit.toWidgetJson()),
      });
    } catch (e) {
      print('Failed to set widget mapping: $e');
    }
  }

  /// Update all widgets mapped to this habit
  Future<void> updateWidgetForHabit(Habit habit) async {
    try {
      await _channel.invokeMethod('updateWidgetForHabit', {
        'habitId': habit.id,
        'habit': jsonEncode(habit.toWidgetJson()),
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

  /// Finish widget configuration with selected habit
  Future<void> finishWithSelectedHabit(
      int appWidgetId, String habitId, Map<String, dynamic> habitData) async {
    try {
      await _channel.invokeMethod('finishWithSelectedHabit', {
        'habitId': habitId,
        'habit': jsonEncode(habitData),
        'appWidgetId': appWidgetId,
      });
    } catch (e) {
      debugPrint('Error finishing widget configuration: $e');
    }
  }
}
