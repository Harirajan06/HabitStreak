import 'package:flutter/material.dart';

enum HabitFrequency { daily, weekly, monthly }

enum HabitTimeOfDay { morning, afternoon, evening, night }

enum HabitType { build, breakHabit }

class Habit {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final HabitFrequency frequency;
  final HabitTimeOfDay timeOfDay;
  final HabitType habitType;
  final DateTime createdAt;
  final List<DateTime> completedDates;
  final bool isActive;
  final List<TimeOfDay> reminderTimes;
  final int remindersPerDay;
  final Map<String, int> dailyCompletions; // date string -> completion count
  final bool? isTemporary;

  Habit({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.frequency,
    required this.timeOfDay,
    required this.habitType,
    required this.createdAt,
    required this.completedDates,
    this.isActive = true,
    this.reminderTimes = const [],
    this.remindersPerDay = 1,
    this.dailyCompletions = const {},
    this.isTemporary,
  });

  int get currentStreak {
    if (completedDates.isEmpty) return 0;

    // Sort dates in descending order (most recent first)
    final sortedDates = completedDates.toList()..sort((a, b) => b.compareTo(a));

    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    // Check if the most recent completion was today or yesterday
    final mostRecentDate = sortedDates.first;
    DateTime startDate;

    if (_isSameDay(mostRecentDate, today)) {
      startDate = today;
    } else if (_isSameDay(mostRecentDate, yesterday)) {
      startDate = yesterday;
    } else {
      // Most recent completion is older than yesterday, so current streak is 0
      return 0;
    }

    // Count consecutive days backwards from startDate
    int streak = 0;
    DateTime checkDate = startDate;

    for (final completedDate in sortedDates) {
      if (_isSameDay(completedDate, checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        // Gap found, streak ends
        break;
      }
    }

    return streak;
  }

  int get longestStreak {
    if (completedDates.isEmpty) return 0;
    if (completedDates.length == 1) return 1;

    // Sort dates in ascending order
    final sortedDates = completedDates.toList()..sort();

    int bestStreak = 1;
    int tempStreak = 1;

    // Algorithm: Find longest consecutive sequence
    for (int i = 1; i < sortedDates.length; i++) {
      final prevDate = sortedDates[i - 1];
      final currentDate = sortedDates[i];

      // Check if current date is exactly 1 day after previous date
      if (currentDate.difference(prevDate).inDays == 1) {
        tempStreak += 1;
      } else {
        bestStreak = bestStreak > tempStreak ? bestStreak : tempStreak;
        tempStreak = 1;
      }
    }

    // Don't forget to check the last streak
    bestStreak = bestStreak > tempStreak ? bestStreak : tempStreak;

    return bestStreak;
  }

  double get completionRate {
    if (completedDates.isEmpty) return 0.0;

    final daysSinceCreated = DateTime.now().difference(createdAt).inDays + 1;
    return (completedDates.length / daysSinceCreated).clamp(0.0, 1.0);
  }

  int get score {
    if (completedDates.isEmpty) return 0;

    // Basic scoring: Each completed day = 1 point
    int basicScore = completedDates.length;

    // Advanced scoring with streak bonuses
    final sortedDates = completedDates.toList()..sort();
    int bonusScore = 0;
    int streak = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      final prevDate = sortedDates[i - 1];
      final currentDate = sortedDates[i];

      if (currentDate.difference(prevDate).inDays == 1) {
        streak += 1;
      } else {
        // Add streak bonus: +5 points for every 7-day streak
        if (streak >= 7) {
          bonusScore += (streak ~/ 7) * 5;
        }
        streak = 1;
      }
    }

    // Don't forget to check the last streak for bonus
    if (streak >= 7) {
      bonusScore += (streak ~/ 7) * 5;
    }

    return basicScore + bonusScore;
  }

  bool isCompletedToday() {
    final today = DateTime.now();
    return completedDates.any((date) => _isSameDay(date, today));
  }

  int getTodayCompletionCount() {
    final todayKey = _getDateKey(DateTime.now());
    return dailyCompletions[todayKey] ?? 0;
  }

  bool isFullyCompletedToday() {
    return getTodayCompletionCount() >= remindersPerDay;
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Map<String, dynamic> toWidgetJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon.codePoint,
      'color': color.value,
      'currentStreak': currentStreak,
      'isCompletedToday': isCompletedToday(),
      'remindersPerDay': remindersPerDay,
      'dailyCompletions': getTodayCompletionCount(),
      'progressPercent': remindersPerDay > 0
          ? (getTodayCompletionCount() / remindersPerDay).clamp(0.0, 1.0)
          : 0.0,
    };
  }

  Habit copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    Color? color,
    HabitFrequency? frequency,
    HabitTimeOfDay? timeOfDay,
    HabitType? habitType,
    DateTime? createdAt,
    List<DateTime>? completedDates,
    bool? isActive,
    List<TimeOfDay>? reminderTimes,
    int? remindersPerDay,
    Map<String, int>? dailyCompletions,
    bool? isTemporary,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      frequency: frequency ?? this.frequency,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      habitType: habitType ?? this.habitType,
      createdAt: createdAt ?? this.createdAt,
      completedDates: completedDates ?? this.completedDates,
      isActive: isActive ?? this.isActive,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      remindersPerDay: remindersPerDay ?? this.remindersPerDay,
      dailyCompletions: dailyCompletions ?? this.dailyCompletions,
      isTemporary: isTemporary ?? this.isTemporary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon.codePoint,
      'color': color.value,
      'frequency': frequency.index,
      'timeOfDay': timeOfDay.index,
      'habitType': habitType.index,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedDates':
          completedDates.map((date) => date.millisecondsSinceEpoch).toList(),
      'isActive': isActive,
      'reminderTimes': reminderTimes
          .map((t) => {'hour': t.hour, 'minute': t.minute})
          .toList(),
      'remindersPerDay': remindersPerDay,
      'dailyCompletions': dailyCompletions,
      'isTemporary': isTemporary,
    };
  }

  // ... (keep toWidgetJson same or update if needed? Widget doesn't seem to use reminderTime)

  factory Habit.fromJson(Map<String, dynamic> json) {
    // Migration: Check for old single 'reminderTime'
    List<TimeOfDay> reminders = [];
    if (json['reminderTimes'] != null) {
      reminders = (json['reminderTimes'] as List)
          .map((t) => TimeOfDay(hour: t['hour'], minute: t['minute']))
          .toList();
    } else if (json['reminderTime'] != null) {
      // Backward compatibility
      reminders.add(TimeOfDay(
        hour: json['reminderTime']['hour'],
        minute: json['reminderTime']['minute'],
      ));
    }

    return Habit(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
      color: Color(json['color']),
      frequency: HabitFrequency.values[json['frequency']],
      timeOfDay: HabitTimeOfDay.values[json['timeOfDay']],
      habitType: HabitType.values[json['habitType'] ?? 0],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      completedDates: (json['completedDates'] as List)
          .map((timestamp) => DateTime.fromMillisecondsSinceEpoch(timestamp))
          .toList(),
      isActive: json['isActive'] ?? true,
      reminderTimes: reminders,
      remindersPerDay: json['remindersPerDay'] ?? 1,
      dailyCompletions: Map<String, int>.from(json['dailyCompletions'] ?? {}),
      isTemporary: json['isTemporary'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color.value,
      'currentStreak': currentStreak,
      'isCompletedToday': isCompletedToday(),
      'remindersPerDay': remindersPerDay,
      'dailyCompletions': getTodayCompletionCount(),
      'progressPercent': remindersPerDay > 0
          ? (getTodayCompletionCount() / remindersPerDay)
          : 0.0,
    };
  }
}
