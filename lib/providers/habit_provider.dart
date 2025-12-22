import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../widgets/congratulations_popup.dart';
import '../services/hive_service.dart';
import '../services/admob_service.dart'; // Import AdmobService
import '../services/widget_service.dart';

class HabitProvider with ChangeNotifier, WidgetsBindingObserver {
  final List<Habit> _habits = [];

  bool _isLoading = false;
  String? _errorMessage;
  final AdmobService _admobService;
  final WidgetService _widgetService = WidgetService();

  List<Habit> get habits => _habits;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Habit> get activeHabits =>
      _habits.where((habit) => habit.isActive).toList();

  List<Habit> get temporaryHabits =>
      _habits.where((habit) => habit.isTemporary == true).toList();

  List<Habit> get permanentHabits =>
      _habits.where((habit) => habit.isTemporary != true).toList();

  List<Habit> getHabitsByTimeOfDay(HabitTimeOfDay timeOfDay) {
    return activeHabits.where((habit) => habit.timeOfDay == timeOfDay).toList();
  }

  int get totalStreaks {
    return activeHabits.fold(0, (sum, habit) => sum + habit.currentStreak);
  }

  int get completedTodayCount {
    return activeHabits.where((habit) => habit.isCompletedToday()).length;
  }

  double get todayProgress {
    if (activeHabits.isEmpty) return 0.0;
    return completedTodayCount / activeHabits.length;
  }

  HabitProvider(this._admobService) {
    // Listen for lifecycle changes to sync widget actions on resume
    WidgetsBinding.instance.addObserver(this);

    // Listen for widget updates (instant sync)
    _widgetService.initialize((habitId) {
      debugPrint(
          "HabitProvider: Received widget update for $habitId, syncing...");
      syncWidgetActions(habitId);
    });

    // Update constructor
    loadHabits();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("HabitProvider: App Resumed - Syncing Widget Actions");
      syncWidgetActions();
    }
  }

  Future<void> loadHabits() async {
    if (_isLoading) return; // Prevent concurrent loads

    try {
      _isLoading = true;
      _errorMessage = null;

      final habits = HiveService.instance.getHabits();
      _habits.clear();
      _habits.addAll(habits);
      _isLoading = false;

      await syncWidgetActions();

      // Only notify if we have a widget tree
      if (WidgetsBinding.instance.isRootWidgetAttached) {
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to load habits: $e';
      debugPrint('Error loading habits: $e');
      _isLoading = false;
      if (WidgetsBinding.instance.isRootWidgetAttached) {
        notifyListeners();
      }
    }
  }

  Future<void> addHabit(Habit habit, {bool isPremium = false}) async {
    // Add isPremium parameter
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      if (isHabitNameTaken(habit.name, excludeId: habit.id)) {
        _errorMessage = 'Habit name already exists';
        _isLoading = false;
        notifyListeners();
        return;
      }

      debugPrint('Adding habit: ${habit.name}');
      await HiveService.instance.addHabit(habit);
      _habits.add(habit);
      debugPrint('Habit added successfully: ${habit.id}');

      _admobService.showInterstitialAd(isPremium: isPremium); // Show ad
      _widgetService.updateWidgetForHabit(habit);
      _requestReview();
    } catch (e) {
      _errorMessage = 'Failed to add habit: $e';
      debugPrint('Error adding habit: $e');
      _habits.add(habit);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addTemporaryHabit(Habit habit) {
    debugPrint('Adding temporary habit: ${habit.name}');
    _habits.add(habit);
    notifyListeners();
    debugPrint('Temporary habit added successfully: ${habit.id}');
  }

  Future<void> updateHabit(String id, Habit updatedHabit) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      if (isHabitNameTaken(updatedHabit.name, excludeId: id)) {
        _errorMessage = 'Habit name already exists';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final index = _habits.indexWhere((habit) => habit.id == id);
      if (index != -1) {
        await HiveService.instance.updateHabit(updatedHabit);
        _habits[index] = updatedHabit;
        _widgetService.updateWidgetForHabit(updatedHabit);
      }
    } catch (e) {
      _errorMessage = 'Failed to update habit: $e';
      final index = _habits.indexWhere((habit) => habit.id == id);
      if (index != -1) {
        _habits[index] = updatedHabit;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateTemporaryHabit(String id, Habit updatedHabit) {
    debugPrint('Updating temporary habit: ${updatedHabit.name}');
    final index = _habits.indexWhere((habit) => habit.id == id);
    if (index != -1) {
      _habits[index] = updatedHabit;
      notifyListeners();
      debugPrint('Temporary habit updated successfully: ${updatedHabit.id}');
    }
  }

  Future<void> deleteHabit(String id, {bool isPremium = false}) async {
    // Add isPremium parameter
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await HiveService.instance.deleteHabit(id);
      _habits.removeWhere((habit) => habit.id == id);
      _widgetService.notifyHabitDeleted(id);

      _admobService.showInterstitialAd(isPremium: isPremium); // Show ad
    } catch (e) {
      _errorMessage = 'Failed to delete habit: $e';
      _habits.removeWhere((habit) => habit.id == id);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleHabitCompletion(String id,
      [BuildContext? context, bool isPremium = false]) async {
    // Add isPremium parameter
    final index = _habits.indexWhere((habit) => habit.id == id);
    if (index != -1) {
      final habit = _habits[index];
      final today = DateTime.now();
      final todayKey = _getDateKey(today);
      final currentCount = habit.getTodayCompletionCount();
      final newDailyCompletions = Map<String, int>.from(habit.dailyCompletions);
      final completedDates = List<DateTime>.from(habit.completedDates);

      final wasAllCompleted = _areAllHabitsCompleted();

      if (currentCount >= habit.remindersPerDay) {
        debugPrint(
            '⚠️  Habit "${habit.name}" is fully completed for today. Try again tomorrow!');
        _errorMessage =
            'Habit already completed for today. Come back tomorrow!';
        notifyListeners();
        return; // Exit without making changes
      }

      final newCount = currentCount + 1;
      newDailyCompletions[todayKey] = newCount;

      if (currentCount == 0) {
        completedDates.add(today);
      }

      debugPrint(
          '✅ Habit "${habit.name}" marked complete ($newCount/${habit.remindersPerDay})');

      try {
        await HiveService.instance.recordCompletion(id, today, count: newCount);
      } catch (e) {
        _errorMessage = 'Failed to record completion: $e';
      }

      _habits[index] = habit.copyWith(
        completedDates: completedDates,
        dailyCompletions: newDailyCompletions,
      );
      _widgetService.updateWidgetForHabit(_habits[index]);
      _admobService.showInterstitialAd(isPremium: isPremium); // Show ad

      if (context != null && newCount >= habit.remindersPerDay) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showHabitCompletionPopup(context, habit);
        });
      }

      notifyListeners();
    }
  }

  bool _areAllHabitsCompleted() {
    final activeHabitsList = activeHabits;
    if (activeHabitsList.isEmpty) return false;

    return activeHabitsList.every((habit) => habit.isCompletedToday());
  }

  // Sync actions from widget
  Future<void> syncWidgetActions([String? specificHabitId]) async {
    debugPrint(
        "--- syncWidgetActions Called (Specific ID: $specificHabitId) ---");

    // If we have a specific ID, process it immediately (Instant Sync)
    if (specificHabitId != null) {
      await toggleHabitCompletion(specificHabitId);
      // We don't return here; we still check pending actions just in case
    }

    try {
      final pendingActions = await _widgetService.getPendingWidgetActions();
      debugPrint("--- Pending Actions: $pendingActions ---");
      if (pendingActions.isNotEmpty) {
        bool changed = false;
        for (final habitId in pendingActions) {
          // Avoid double-toggling if we just did it
          if (habitId == specificHabitId) continue;

          debugPrint("--- Processing Action for Habit: $habitId ---");
          final index = _habits.indexWhere((h) => h.id == habitId);
          if (index != -1) {
            await toggleHabitCompletion(habitId);
            changed = true;
          } else {
            debugPrint("--- Habit not found for ID: $habitId ---");
          }
        }
        if (changed) notifyListeners();
        await _widgetService.clearPendingWidgetActions();
      } else {
        debugPrint("--- No Pending Actions ---");
      }
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  void _showHabitCompletionPopup(BuildContext context, Habit habit) {
    showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      builder: (context) => CongratulationsPopup(
        habitName: habit.name,
        customMessage: 'You completed it ${habit.remindersPerDay}x today! 🎉',
        habitIcon: habit.icon,
        habitColor: habit.color,
      ),
    );
  }

  void _showAllHabitsCompletedPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CongratulationsPopup(
        habitName: 'All habits completed',
        customMessage: 'You completed all your habits for today! 🎉',
        habitIcon: Icons.workspace_premium,
        habitColor: Color(0xFF9B5DE5),
      ),
    );
  }

  Future<void> _requestReview() async {
    final prefs = await SharedPreferences.getInstance();
    int habitCreationCount = prefs.getInt('habit_creation_count') ?? 0;
    habitCreationCount++;
    await prefs.setInt('habit_creation_count', habitCreationCount);

    if (habitCreationCount == 2) {
      final InAppReview inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        inAppReview.requestReview();
      }
    }
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Habit? getHabitById(String id) {
    try {
      return _habits.firstWhere((habit) => habit.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Habit> getHabitsCompletedOn(DateTime date) {
    return _habits.where((habit) {
      return habit.completedDates.any((completedDate) =>
          completedDate.year == date.year &&
          completedDate.month == date.month &&
          completedDate.day == date.day);
    }).toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  bool isHabitNameTaken(String name, {String? excludeId}) {
    final normalized = name.trim().toLowerCase();
    return _habits.any((habit) {
      if (excludeId != null && habit.id == excludeId) {
        return false;
      }
      return habit.name.trim().toLowerCase() == normalized;
    });
  }
}
