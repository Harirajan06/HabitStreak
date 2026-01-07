import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/mood_entry.dart';

class MoodProvider extends ChangeNotifier {
  static const String _boxName = 'moods_box';
  Box? _moodBox;
  Map<String, MoodEntry> _moods = {};
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _moodBox = await Hive.openBox(_boxName);
      await loadMoods();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing MoodProvider: $e');
    }
  }

  Future<void> loadMoods() async {
    // Ensure box is open (lazy open if needed)
    if (_moodBox == null) {
      try {
        _moodBox = await Hive.openBox(_boxName);
      } catch (e) {
        debugPrint('Error opening moods box: $e');
        return;
      }
    }

    try {
      _moods = {};
      for (var entry in _moodBox!.values) {
        final moodEntry =
            MoodEntry.fromJson(Map<String, dynamic>.from(entry as Map));
        final dateKey = _getDateKey(moodEntry.date);
        _moods[dateKey] = moodEntry;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading moods: $e');
    }
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool hasMoodForDate(DateTime date) {
    return _moods.containsKey(_getDateKey(date));
  }

  MoodEntry? getMoodForDate(DateTime date) {
    return _moods[_getDateKey(date)];
  }

  Future<void> saveMood({
    required DateTime date,
    required String emoji,
    required String label,
    required List<String> tags,
    required String notes,
    int score = 0,
  }) async {
    // Ensure box is open (lazy open if needed)
    if (_moodBox == null) {
      try {
        _moodBox = await Hive.openBox(_boxName);
      } catch (e) {
        debugPrint('Error opening moods box before save: $e');
        return;
      }
    }

    try {
      final dateKey = _getDateKey(date);
      final id = dateKey; // Use date key as ID

      final moodEntry = MoodEntry(
        id: id,
        date: date,
        emoji: emoji,
        label: label,
        tags: tags,
        notes: notes,
        score: score,
      );

      await _moodBox!.put(id, moodEntry.toJson());
      _moods[dateKey] = moodEntry;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving mood: $e');
    }
  }

  Future<void> deleteMood(DateTime date) async {
    // Ensure box is open (lazy open if needed)
    if (_moodBox == null) {
      try {
        _moodBox = await Hive.openBox(_boxName);
      } catch (e) {
        debugPrint('Error opening moods box before delete: $e');
        return;
      }
    }

    try {
      final dateKey = _getDateKey(date);
      await _moodBox!.delete(dateKey);
      _moods.remove(dateKey);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting mood: $e');
    }
  }

  List<MoodEntry> getAllMoods() {
    return _moods.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }
}
