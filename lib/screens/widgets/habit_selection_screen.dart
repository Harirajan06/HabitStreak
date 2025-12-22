import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../services/widget_service.dart';

class HabitSelectionScreen extends StatelessWidget {
  final int appWidgetId;

  const HabitSelectionScreen({super.key, required this.appWidgetId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Habit for Widget"),
      ),
      body: Consumer<HabitProvider>(
        builder: (context, habitProvider, child) {
          if (habitProvider.habits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("No habits found"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Finish with empty to cancel/exit
                      WidgetService()
                          .finishWithSelectedHabit(appWidgetId, '', {});
                      // If we are deep in nav, maybe we shouldn't pop app?
                      // Native side will finish activity.
                    },
                    child: const Text("Close"),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: habitProvider.habits.length,
            itemBuilder: (context, index) {
              final habit = habitProvider.habits[index];
              return ListTile(
                title: Text(habit.name),
                subtitle: Text(habit.description),
                leading: CircleAvatar(
                  backgroundColor: habit.color,
                  child: Icon(habit.icon, color: Colors.white),
                ),
                onTap: () async {
                  // Call native method
                  await WidgetService().finishWithSelectedHabit(
                    appWidgetId,
                    habit.id,
                    habit.toMap(),
                  );
                  // The native activity will finish, which should bring us back?
                  // Actually, WidgetConfigureActivity launched MainActivity.
                  // If MainActivity finishes, the app closes?
                  // No, WidgetConfigureActivity started MainActivity with startActivityForResult (maybe?) or just startActivity?
                  // Wait, check HabitWidgetProvider.
                  // It calls `WidgetConfigureActivity`.
                  // `WidgetConfigureActivity` calls `MainActivity`.
                  // `MainActivity` calls `finishWithSelectedHabit`.
                  // `MainActivity` sets result and finishes.
                  // So YES, the app activity will close.
                  // But wait, the user is in the app.
                  // If we are in the app normally, we don't want to close the app?
                  // `getWidgetConfig` returns mode=true ONLY if launched via intent?
                  // Yes.
                  // So closing the app is correct behavior for the configuration flow.
                },
              );
            },
          );
        },
      ),
    );
  }
}
