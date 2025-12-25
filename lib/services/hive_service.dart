import 'package:hive_flutter/hive_flutter.dart';
import 'hive_adapters.dart';

import '../models/habit.dart';
import '../models/note.dart';
import '../models/user.dart';

class HiveService {
  static HiveService? _instance;
  static HiveService get instance => _instance ??= HiveService._();

  HiveService._();

  late Box _habitsBox;
  late Box _notesBox;
  late Box _usersBox;
  late Box _settingsBox;
  late Box _moodsBox;

  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters (simple JSON-backed adapters)
    try {
      Hive.registerAdapter(HabitAdapter());
      Hive.registerAdapter(NoteAdapter());
      Hive.registerAdapter(AppUserAdapter());
      Hive.registerAdapter(SettingsAdapter());
    } catch (_) {
      // Adapter may already be registered in hot-reload environments.
    }

    _habitsBox = await Hive.openBox('habits_box');
    _notesBox = await Hive.openBox('notes_box');
    _usersBox = await Hive.openBox('users_box');
    _settingsBox = await Hive.openBox('settings_box');
    _moodsBox = await Hive.openBox('moods_box');
    // Open purchases box for local purchase records and entitlements
    await Hive.openBox('purchases_box');
  }

  // Habits
  List<Habit> getHabits() {
    return _habitsBox.values
        .map((e) => Habit.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> addHabit(Habit habit) async {
    await _habitsBox.put(habit.id, habit.toJson());
  }

  Future<void> updateHabit(Habit habit) async {
    await _habitsBox.put(habit.id, habit.toJson());
  }

  Future<void> deleteHabit(String habitId) async {
    await _habitsBox.delete(habitId);
    // Also delete notes linked to habit
    final keysToDelete = <dynamic>[];
    for (final kv in _notesBox.toMap().entries) {
      final note = Note.fromJson(Map<String, dynamic>.from(kv.value));
      if (note.habitId == habitId) keysToDelete.add(kv.key);
    }
    for (final k in keysToDelete) {
      await _notesBox.delete(k);
    }
  }

  Future<void> recordCompletion(String habitId, DateTime date,
      {int count = 1}) async {
    final data = _habitsBox.get(habitId);
    if (data == null) return;
    final habit = Habit.fromJson(Map<String, dynamic>.from(data));

    final dateKey = _getDateKey(date);
    final daily = Map<String, int>.from(habit.dailyCompletions);
    daily[dateKey] = count;

    final completedDates = habit.completedDates.toList();
    if (!completedDates.any((d) => _isSameDay(d, date))) {
      completedDates.add(date);
    }

    final updated =
        habit.copyWith(completedDates: completedDates, dailyCompletions: daily);
    await updateHabit(updated);
  }

  Future<void> removeCompletion(String habitId, DateTime date) async {
    final data = _habitsBox.get(habitId);
    if (data == null) return;
    final habit = Habit.fromJson(Map<String, dynamic>.from(data));
    final dateKey = _getDateKey(date);

    final daily = Map<String, int>.from(habit.dailyCompletions);
    daily.remove(dateKey);

    final completedDates =
        habit.completedDates.where((d) => !_isSameDay(d, date)).toList();

    final updated =
        habit.copyWith(completedDates: completedDates, dailyCompletions: daily);
    await updateHabit(updated);
  }

  // Notes
  List<Note> getNotes() {
    return _notesBox.values
        .map((e) => Note.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> addNote(Note note) async {
    await _notesBox.put(note.id, note.toJson());
  }

  Future<void> updateNote(Note note) async {
    await _notesBox.put(note.id, note.toJson());
  }

  Future<void> deleteNote(String noteId) async {
    await _notesBox.delete(noteId);
  }

  List<Note> getNotesForHabit(String habitId) {
    return _notesBox.values
        .map((e) => Note.fromJson(Map<String, dynamic>.from(e)))
        .where((n) => n.habitId == habitId)
        .toList();
  }

  // Users
  List<AppUser> getUsers() {
    return _usersBox.values
        .map((e) => AppUser.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> addUser(AppUser user) async {
    await _usersBox.put(user.id, user.toJson());
  }

  Future<void> updateUser(AppUser user) async {
    await _usersBox.put(user.id, user.toJson());
  }

  Future<void> deleteUser(String userId) async {
    await _usersBox.delete(userId);
  }

  // Settings
  Map<String, dynamic> getSettings() {
    return Map<String, dynamic>.from(
        _settingsBox.get('settings', defaultValue: {}) as Map);
  }

  Future<void> setSettings(Map<String, dynamic> settings) async {
    await _settingsBox.put('settings', settings);
  }

  Future<void> clearAll() async {
    await _habitsBox.clear();
    await _notesBox.clear();
    await _usersBox.clear();
    await _settingsBox.clear();
    await _moodsBox.clear();
  }

  // Helpers
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Raw export helpers
  Map<String, dynamic> exportAllAsJson() {
    return {
      'meta': {'exportedAt': DateTime.now().toIso8601String()},
      'users':
          _usersBox.values.map((e) => Map<String, dynamic>.from(e)).toList(),
      'habits':
          _habitsBox.values.map((e) => Map<String, dynamic>.from(e)).toList(),
      'notes':
          _notesBox.values.map((e) => Map<String, dynamic>.from(e)).toList(),
      'moods':
          _moodsBox.values.map((e) => Map<String, dynamic>.from(e)).toList(),
      'settings': getSettings(),
    };
  }

  Future<void> importJson(Map<String, dynamic> data,
      {bool overwrite = false}) async {
    if (overwrite) {
      await clearAll();
    }

    final users = (data['users'] as List?) ?? [];
    final habits = (data['habits'] as List?) ?? [];
    final notes = (data['notes'] as List?) ?? [];
    final moods = (data['moods'] as List?) ?? [];
    final settings = (data['settings'] as Map<String, dynamic>?) ?? {};

    for (final u in users) {
      final map = Map<String, dynamic>.from(u);
      final user = AppUser.fromJson(map);
      await addUser(user);
    }

    for (final h in habits) {
      final map = Map<String, dynamic>.from(h);
      final habit = Habit.fromJson(map);
      await addHabit(habit);
    }

    for (final n in notes) {
      final map = Map<String, dynamic>.from(n);
      final note = Note.fromJson(map);
      await addNote(note);
    }

    for (final m in moods) {
      final map = Map<String, dynamic>.from(m);
      // MoodEntry uses date string as key/id
      final id = map['id'] as String;
      await _moodsBox.put(id, map);
    }

    if (settings.isNotEmpty) {
      await setSettings(settings);
    }
  }
}
