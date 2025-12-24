import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../screens/widgets/habit_selection_screen.dart';

/// Mixin to handle connection with Android Widgets.
/// 1. Listens for App Resume to sync widget actions (completions).
/// 2. Checks on startup if the app was launched to configure a widget.
mixin WidgetLogicMixin<T extends StatefulWidget> on State<T> {
  static const MethodChannel _widgetChannel =
      MethodChannel('com.harirajan.streakly/widget');

  @override
  void initState() {
    super.initState();
    if (this is WidgetsBindingObserver) {
      WidgetsBinding.instance.addObserver(this as WidgetsBindingObserver);
    }

    // Listen for widget configuration triggers from native side
    _widgetChannel.setMethodCallHandler((call) async {
      if (call.method == 'triggerWidgetConfig') {
        debugPrint('--- Received triggerWidgetConfig from native ---');
        if (mounted) {
          _checkWidgetConfiguration();
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkWidgetConfiguration();
      // Also sync immediately when this screen loads (post-splash)
      if (mounted) {
        Provider.of<HabitProvider>(context, listen: false).syncWidgetActions();
      }
    });
  }

  @override
  void dispose() {
    if (this is WidgetsBindingObserver) {
      WidgetsBinding.instance.removeObserver(this as WidgetsBindingObserver);
    }
    super.dispose();
  }

  // Expects the consuming class to mixin WidgetsBindingObserver
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("--- APP RESUMED (Mixin): Syncing Widget Actions ---");
      if (mounted) {
        Provider.of<HabitProvider>(context, listen: false).syncWidgetActions();
        _checkWidgetConfiguration();
      }
    }
  }

  Future<void> _checkWidgetConfiguration() async {
    try {
      final result = await _widgetChannel.invokeMethod('getWidgetConfig');
      if (result is Map) {
        final mode = result['mode'] as bool? ?? false;
        final appWidgetId = result['appWidgetId'] as int? ?? -1;

        if (mode && appWidgetId != -1) {
          debugPrint(
              "--- Widget Configuration Mode Detected for ID: $appWidgetId ---");
          if (!mounted) {
            debugPrint("--- Context not mounted, aborting navigation ---");
            return;
          }

          final habitProvider =
              Provider.of<HabitProvider>(context, listen: false);
          // If habits are not loaded yet, wait a moment
          if (habitProvider.habits.isEmpty) {
            debugPrint("--- Habits empty, forcing load... ---");
            await habitProvider.loadHabits();
            debugPrint(
                "--- Habits loaded. Count: ${habitProvider.habits.length} ---");
          } else {
            debugPrint(
                "--- Habits already loaded. Count: ${habitProvider.habits.length} ---");
          }

          if (!mounted) {
            debugPrint(
                "--- Context not mounted after load, aborting navigation ---");
            return;
          }

          debugPrint("--- Navigating to HabitSelectionScreen... ---");
          // Navigate to Selection Screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HabitSelectionScreen(appWidgetId: appWidgetId),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Widget channel error: $e');
    }
  }
}
