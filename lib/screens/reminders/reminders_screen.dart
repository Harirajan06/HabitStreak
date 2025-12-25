import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../models/habit.dart';
import '../../services/notification_service.dart';
import 'package:intl/intl.dart';
// Test notification screen removed

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primary.withAlpha((0.18 * 255).toInt()),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: theme.colorScheme.outline
                        .withAlpha((0.2 * 255).toInt())),
              ),
              child:
                  Icon(Icons.notifications, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Text(
              'Reminders',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'View scheduled reminders',
            onPressed: () => _showPendingNotifications(context),
            icon: const Icon(Icons.list_alt),
          ),
        ],
      ),
      body: Consumer<HabitProvider>(
        builder: (context, habitProvider, child) {
          final upcomingHabits = _getUpcomingReminders(habitProvider);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: upcomingHabits.isEmpty
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: theme.colorScheme.outline
                                      .withAlpha((0.2 * 255).toInt())),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withAlpha((0.16 * 255).toInt()),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.check_circle_outline,
                                    size: 32,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'All caught up!',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No upcoming reminders for today',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withAlpha((0.6 * 255).toInt()),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: upcomingHabits.length,
                          itemBuilder: (context, index) {
                            final habit = upcomingHabits[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: theme.colorScheme.outline
                                        .withAlpha((0.2 * 255).toInt())),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: habit.color
                                          .withAlpha((0.18 * 255).toInt()),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(habit.icon,
                                        color: habit.color, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          habit.name,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _formatReminderTime(
                                                    habit.reminderTimes),
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: theme
                                                      .colorScheme.onSurface
                                                      .withAlpha(
                                                          (0.6 * 255).toInt()),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _getTimeOfDayLabel(
                                                  habit.timeOfDay),
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: theme
                                                    .colorScheme.onSurface
                                                    .withAlpha(
                                                        (0.6 * 255).toInt()),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: habit.isCompletedToday()
                                              ? Colors.green.withAlpha(
                                                  (0.18 * 255).toInt())
                                              : theme.colorScheme.primary
                                                  .withAlpha(
                                                      (0.18 * 255).toInt()),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          habit.isCompletedToday()
                                              ? 'Done'
                                              : 'Pending',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: habit.isCompletedToday()
                                                ? Colors.green
                                                : theme.colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      PopupMenuButton<String>(
                                        onSelected: (value) async {
                                          final provider =
                                              Provider.of<HabitProvider>(
                                                  context,
                                                  listen: false);
                                          if (value == 'cancel') {
                                            final updated = habit
                                                .copyWith(reminderTimes: []);
                                            await provider.updateHabit(
                                                habit.id, updated);
                                            await NotificationService()
                                                .cancelHabitReminders(habit.id);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Text(
                                                          'Reminders cancelled for ${habit.name}')));
                                            }
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                              value: 'cancel',
                                              child:
                                                  Text('Cancel all reminders')),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Habit> _getUpcomingReminders(HabitProvider habitProvider) {
    // Return habits that have a reminder set and are not completed today
    return habitProvider.activeHabits
        .where((habit) =>
            habit.reminderTimes.isNotEmpty && !habit.isCompletedToday())
        .toList();
  }

  String _getTimeOfDayLabel(HabitTimeOfDay timeOfDay) {
    switch (timeOfDay) {
      case HabitTimeOfDay.morning:
        return 'Morning (6:00 - 12:00)';
      case HabitTimeOfDay.afternoon:
        return 'Afternoon (12:00 - 18:00)';
      case HabitTimeOfDay.evening:
        return 'Evening (18:00 - 24:00)';
      case HabitTimeOfDay.night:
        return 'Night (24:00 - 6:00)';
    }
  }

  String _formatReminderTime(List<TimeOfDay> times) {
    if (times.isEmpty) return 'No time set';
    final now = DateTime.now();
    return times.map((time) {
      final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      return DateFormat.jm().format(dt);
    }).join(', ');
  }

  int _normalizeId(int id) => id & 0x7fffffff;

  Future<void> _showPendingNotifications(BuildContext context) async {
    final service = NotificationService();
    final provider = Provider.of<HabitProvider>(context, listen: false);
    final pending = await service.getPendingNotificationRequests();

    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        builder: (ctx) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('Scheduled reminders (${pending.length})'),
                ),
                if (pending.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('No scheduled notifications found.'),
                  ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: pending.length,
                    itemBuilder: (context, index) {
                      final req = pending[index];
                      Habit? matchedHabit;
                      try {
                        matchedHabit = provider.habits.firstWhere(
                            (h) => _normalizeId(h.id.hashCode) == req.id);
                      } catch (e) {
                        matchedHabit = null;
                      }
                      return ListTile(
                        title: Text(req.title ?? 'Reminder'),
                        subtitle: Text(req.body ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (matchedHabit != null)
                              IconButton(
                                tooltip: 'Go to habit',
                                icon: const Icon(Icons.open_in_new),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  // Optionally navigate to habit details - not implemented
                                },
                              ),
                            IconButton(
                              tooltip: 'Cancel',
                              icon: const Icon(Icons.cancel),
                              onPressed: () async {
                                await service.cancelReminder(req.id);
                                if (matchedHabit != null) {
                                  final updated =
                                      matchedHabit.copyWith(reminderTimes: []);
                                  await provider.updateHabit(
                                      matchedHabit.id, updated);
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Cancelled reminder ${req.title ?? ''}')));
                                }
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }
}
