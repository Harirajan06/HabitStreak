import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/habit.dart';
import '../models/note.dart';
import '../providers/auth_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/note_provider.dart';
import '../screens/habits/add_habit_screen.dart';
import 'habit_progress_ring.dart';
import 'modern_button.dart';

class HabitDetailBottomSheet extends StatelessWidget {
  final Habit habit;

  const HabitDetailBottomSheet({super.key, required this.habit});

  static Future<void> show(BuildContext context, Habit habit) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HabitDetailBottomSheet(habit: habit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isPremium = authProvider.currentUser?.premium ?? false;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        color: Colors.transparent,
        child: FractionallySizedBox(
          heightFactor: 0.9,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Consumer<HabitProvider>(
                  builder: (context, habitProvider, _) {
                    final latestHabit =
                        habitProvider.getHabitById(habit.id) ?? habit;
                    final isComplete = latestHabit.isFullyCompletedToday();

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHandle(theme),
                          const SizedBox(height: 16),
                          _buildHeader(latestHabit, theme),
                          const SizedBox(height: 24),
                          Center(
                            child: HabitProgressRing(habit: latestHabit),
                          ),
                          const SizedBox(height: 24),
                          _buildStatsWrap(latestHabit, theme),
                          const SizedBox(height: 20),
                          _buildInfoTiles(latestHabit, theme),
                          const SizedBox(height: 24),
                          ModernButton(
                            text: isComplete
                                ? 'Completed for Today'
                                : 'Mark Complete',
                            icon: isComplete
                                ? Icons.check_circle
                                : Icons.flash_on,
                            fullWidth: true,
                            size: ModernButtonSize.large,
                            customColor: latestHabit.color,
                            onPressed: isComplete
                                ? null
                                : () async {
                                    await habitProvider.toggleHabitCompletion(
                                      latestHabit.id,
                                      context,
                                      isPremium,
                                    );
                                  },
                          ),
                          const SizedBox(height: 12),
                          ModernButton(
                            text: 'Add Note',
                            type: ModernButtonType.secondary,
                            icon: Icons.edit_note,
                            fullWidth: true,
                            onPressed: () => _showAddNoteDialog(
                              context,
                              latestHabit,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ModernButton(
                            text: 'Delete Habit',
                            type: ModernButtonType.destructive,
                            icon: Icons.delete_forever,
                            fullWidth: true,
                            onPressed: () => _confirmDeletion(
                              context,
                              latestHabit,
                              isPremium,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AddHabitScreen(
                                    habitToEdit: latestHabit,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.tune),
                            label: const Text('Edit habit'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHandle(ThemeData theme) {
    return Center(
      child: Container(
        width: 46,
        height: 4,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withAlpha((0.2 * 255).round()),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(Habit habit, ThemeData theme) {
    final isBuildHabit = habit.habitType == HabitType.build;
    final typeColor = isBuildHabit ? Colors.green : Colors.redAccent;

    return Row(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: habit.color.withAlpha((0.15 * 255).round()),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            habit.icon,
            size: 30,
            color: habit.color,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                habit.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    isBuildHabit
                        ? Icons.auto_awesome
                        : Icons.do_not_disturb_on_total_silence,
                    size: 16,
                    color: typeColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isBuildHabit ? 'Build habit' : 'Break habit',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: typeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsWrap(Habit habit, ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatChipWidget(
                stat: _StatChip(
                  label: 'Current streak',
                  value: '${habit.currentStreak} days',
                  icon: Icons.local_fire_department,
                ),
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatChipWidget(
                stat: _StatChip(
                  label: 'Longest streak',
                  value: '${habit.longestStreak} days',
                  icon: Icons.leaderboard,
                ),
                theme: theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatChipWidget(
          stat: _StatChip(
            label: 'Completion rate',
            value: '${(habit.completionRate * 100).toInt()}%',
            icon: Icons.percent,
          ),
          theme: theme,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildInfoTiles(Habit habit, ThemeData theme) {
    String titleCase(String value) {
      if (value.isEmpty) return value;
      return value[0].toUpperCase() + value.substring(1).toLowerCase();
    }

    final frequencyLabel = habit.frequency.name.replaceAll('_', ' ');
    final timeOfDayLabel = habit.timeOfDay.name.replaceAll('_', ' ');

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                icon: Icons.schedule,
                label: 'Time of day',
                value: titleCase(timeOfDayLabel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoTile(
                icon: Icons.repeat,
                label: 'Frequency',
                value: titleCase(frequencyLabel),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _InfoTile(
          icon: Icons.notifications_active,
          label: 'Reminders per day',
          value: habit.remindersPerDay.toString(),
        ),
      ],
    );
  }

  void _showAddNoteDialog(BuildContext context, Habit habit) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final content = contentController.text.trim();
              if (title.isEmpty || content.isEmpty) {
                return;
              }
              await _saveNote(context, habit, title, content);
              if (context.mounted) {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Note saved successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNote(
    BuildContext context,
    Habit habit,
    String title,
    String content,
  ) async {
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    final note = Note(
      id: const Uuid().v4(),
      title: title,
      content: content,
      habitId: habit.id,
      habitName: habit.name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: const [],
    );
    await noteProvider.addNote(note);
  }

  void _confirmDeletion(
    BuildContext context,
    Habit habit,
    bool isPremium,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Habit'),
          content: Text('Are you sure you want to delete "${habit.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final habitProvider =
                    Provider.of<HabitProvider>(context, listen: false);
                await habitProvider.deleteHabit(
                  habit.id,
                  isPremium: isPremium,
                );
                if (context.mounted) {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class _StatChip {
  final String label;
  final String value;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _StatChipWidget extends StatelessWidget {
  final _StatChip stat;
  final ThemeData theme;
  final bool isFullWidth;

  const _StatChipWidget({required this.stat, required this.theme, this.isFullWidth = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
          border: Border.all(
          color: theme.colorScheme.onSurface.withAlpha((0.08 * 255).round()),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha((0.08 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(stat.icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stat.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).round()),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat.value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
          border: Border.all(
          color: theme.colorScheme.onSurface.withAlpha((0.08 * 255).round()),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha((0.08 * 255).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha((0.7 * 255).round()),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
