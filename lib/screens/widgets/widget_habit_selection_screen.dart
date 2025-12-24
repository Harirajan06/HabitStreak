import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../services/widget_service.dart';

class WidgetHabitSelectionScreen extends StatelessWidget {
  final int appWidgetId;

  const WidgetHabitSelectionScreen({super.key, required this.appWidgetId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Habit'),
        automaticallyImplyLeading:
            false, // Don't allow going back to "home" in this mode if it's confusing
      ),
      body: Consumer<HabitProvider>(
        builder: (context, habitProvider, child) {
          final habits = habitProvider.habits;

          if (habits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No habits found',
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Allow them to exit cleanly? Or create a habit?
                      // For now just exit.
                      Navigator.of(context).pop();
                    },
                    child: const Text('Close'),
                  )
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: habit.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(habit.icon, color: habit.color),
                ),
                title: Text(habit.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(habit.description.isNotEmpty
                    ? habit.description
                    : 'No description'),
                onTap: () {
                  WidgetService()
                      .finishWithSelectedHabit(appWidgetId, habit.id, habit);
                  // The native side "finish()" will likely kill this activity,
                  // but we should arguably wait or show a loading indicator.
                  // Since finishWithSelectedHabit is async but fast (invokeMethod),
                  // we can just wait and maybe pop if necessary, though native finish is best.
                },
              );
            },
          );
        },
      ),
    );
  }
}
