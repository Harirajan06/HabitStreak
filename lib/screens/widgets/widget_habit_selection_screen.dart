import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/widget_service.dart';
import '../subscription/subscription_plans_screen.dart';

class WidgetHabitSelectionScreen extends StatelessWidget {
  final int appWidgetId;

  const WidgetHabitSelectionScreen({super.key, required this.appWidgetId});

  @override
  Widget build(BuildContext context) {
    // Check premium status
    final isPremium =
        context.read<AuthProvider>().currentUser?.premium ?? false;

    if (!isPremium) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Select a Habit'),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.widgets,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Premium Feature',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Home screen widgets are available exclusively for Pro users.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionPlansScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9B5DE5),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Upgrade to Pro'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Just close the activity if they don't want to upgrade
                    // We can't really "cancel" meaningfully since it was launched from widget
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
