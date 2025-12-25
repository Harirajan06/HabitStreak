import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../services/widget_service.dart';
import '../habits/add_habit_screen.dart';

class HabitSelectionScreen extends StatefulWidget {
  final int appWidgetId;

  const HabitSelectionScreen({super.key, required this.appWidgetId});

  @override
  State<HabitSelectionScreen> createState() => _HabitSelectionScreenState();
}

class _HabitSelectionScreenState extends State<HabitSelectionScreen> {
  bool _hasNavigatedToCreate = false;

  @override
  void initState() {
    super.initState();
    // Check if we need to navigate to create habit screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndNavigateToCreate();
    });
  }

  Future<void> _checkAndNavigateToCreate() async {
    if (_hasNavigatedToCreate) return;

    final habitProvider = Provider.of<HabitProvider>(context, listen: false);

    if (habitProvider.habits.isEmpty) {
      _hasNavigatedToCreate = true;
      debugPrint("--- No habits found, navigating to AddHabitScreen ---");

      // Navigate to AddHabitScreen
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AddHabitScreen(),
        ),
      );

      // If user created a habit, map it to the widget
      if (result == true && mounted) {
        // Reload habits to get the newly created one
        await habitProvider.loadHabits();

        if (habitProvider.habits.isNotEmpty && mounted) {
          // Get the most recently created habit (last in list)
          final newHabit = habitProvider.habits.last;

          debugPrint(
              "--- Auto-mapping newly created habit: ${newHabit.name} ---");

          // Finish configuration with the new habit
          await WidgetService().finishWithSelectedHabit(
            widget.appWidgetId,
            newHabit.id,
            newHabit,
          );

          // Close this screen
          if (mounted) {
            Navigator.of(context).pop();
          }
        } else {
          // No habit was created, close configuration
          debugPrint("--- No habit created, closing configuration ---");
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      } else {
        // User cancelled, close configuration
        debugPrint(
            "--- User cancelled habit creation, closing configuration ---");
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Habit for Widget"),
      ),
      body: Consumer<HabitProvider>(
        builder: (context, habitProvider, child) {
          if (habitProvider.habits.isEmpty) {
            // Show loading indicator while navigating
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView.builder(
            itemCount: habitProvider.habits.length,
            itemBuilder: (ctx, index) {
              final habit = habitProvider.habits[index];
              return ListTile(
                title: Text(habit.name),
                subtitle: Text(habit.description),
                leading: CircleAvatar(
                  backgroundColor: habit.color,
                  child: Icon(habit.icon, color: Colors.white),
                ),
                onTap: () async {
                  debugPrint("--- Selected habit: ${habit.name} ---");

                  // Call native method to finish configuration
                  await WidgetService().finishWithSelectedHabit(
                    widget.appWidgetId,
                    habit.id,
                    habit,
                  );

                  // Close the selection screen
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
