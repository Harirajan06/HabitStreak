import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';

import '../../models/habit.dart';
import '../../models/note.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/note_provider.dart';
import 'add_habit_screen.dart';
import '../../widgets/modern_button.dart';

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  static void show(BuildContext context, Habit habit) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HabitDetailScreen(habit: habit),
      ),
    );
  }

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  List<Note> _recentNotes = [];
  bool _isLoadingNotes = true;
  DateTime _focusedDay = DateTime.now();
  final CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    final notes = await noteProvider.getNotesForHabit(widget.habit.id);
    if (mounted) {
      setState(() {
        _recentNotes = notes.take(3).toList(); // Show last 3 notes
        _isLoadingNotes = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isPremium = authProvider.currentUser?.premium ?? false;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Habit Details',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              size: 20, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz, color: theme.colorScheme.onSurface),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) {
              if (value == 'edit') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AddHabitScreen(habitToEdit: widget.habit),
                  ),
                );
              } else if (value == 'delete') {
                _confirmDeletion(context, widget.habit, isPremium);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit,
                        size: 20, color: theme.colorScheme.onSurface),
                    const SizedBox(width: 12),
                    Text('Edit Habit', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: const [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Delete Habit', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Consumer<HabitProvider>(
                  builder: (context, habitProvider, _) {
                    final latestHabit =
                        habitProvider.getHabitById(widget.habit.id) ??
                            widget.habit;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        _buildModernHeader(latestHabit, theme),
                        const SizedBox(height: 32),

                        // Compact Stats Row (with Completion % instead of Total)
                        _buildCompactStatsRow(latestHabit, theme),
                        const SizedBox(height: 32),

                        // Recent Activity / Notes
                        _buildSectionHeader(theme, 'Recent Notes',
                            action: IconButton(
                              icon: Icon(Icons.add_circle_outline,
                                  color: latestHabit.color),
                              onPressed: () =>
                                  _showAddNoteDialog(context, latestHabit),
                            )),
                        _buildNotesList(theme, latestHabit),
                        const SizedBox(height: 32),

                        // Calendar Section
                        _buildCalendarSection(latestHabit, theme),

                        const SizedBox(height: 32),

                        // Frequency Info
                        _buildInfoSection(latestHabit, theme),

                        const SizedBox(height: 120), // Bottom spacing for FAB
                      ],
                    );
                  },
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.scaffoldBackgroundColor.withOpacity(0.0),
                      theme.scaffoldBackgroundColor,
                      theme.scaffoldBackgroundColor,
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Consumer<HabitProvider>(
        builder: (context, habitProvider, _) {
          final latestHabit =
              habitProvider.getHabitById(widget.habit.id) ?? widget.habit;
          final isComplete = latestHabit.isFullyCompletedToday();

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            width: double.infinity,
            child: IgnorePointer(
              ignoring: isComplete,
              child: ModernButton(
                text: isComplete ? 'Completed Today' : 'Mark Complete',
                icon: isComplete ? Icons.check : Icons.flash_on,
                customColor: latestHabit.color,
                fullWidth: true,
                size: ModernButtonSize.large,
                onPressed: isComplete
                    ? () {}
                    : () async {
                        await habitProvider.toggleHabitCompletion(
                          latestHabit.id,
                          context,
                          isPremium,
                        );
                        if (mounted) setState(() {}); // Refresh UI
                      },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernHeader(Habit habit, ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: habit.color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(habit.icon, size: 40, color: habit.color),
        ),
        const SizedBox(height: 16),
        Text(
          habit.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.repeat,
                size: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Text(
                '${habit.frequency.name[0].toUpperCase()}${habit.frequency.name.substring(1)} • ${habit.timeOfDay.name[0].toUpperCase()}${habit.timeOfDay.name.substring(1)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStatsRow(Habit habit, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(theme, '${habit.currentStreak}', 'Streak',
              Icons.local_fire_department, Colors.orange),
          _buildVerticalDivider(theme),
          _buildStatItem(theme, '${habit.longestStreak}', 'Best',
              Icons.emoji_events, Colors.amber),
          _buildVerticalDivider(theme),
          // Changed Total to Completion Rate
          _buildStatItem(theme, '${(habit.completionRate * 100).toInt()}%',
              'Completion', Icons.pie_chart, Colors.teal),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider(ThemeData theme) {
    return Container(
      height: 32,
      width: 1,
      color: theme.colorScheme.outline.withOpacity(0.2),
    );
  }

  Widget _buildStatItem(
      ThemeData theme, String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarSection(Habit habit, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Text(
              'History',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TableCalendar(
            firstDay: habit.createdAt.subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 30)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            availableCalendarFormats: const {CalendarFormat.month: 'Month'},
            daysOfWeekHeight: 24,
            rowHeight: 48, // More breathing room
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: theme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              leftChevronIcon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chevron_left,
                    size: 20, color: theme.colorScheme.onSurface),
              ),
              rightChevronIcon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chevron_right,
                    size: 20, color: theme.colorScheme.onSurface),
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: theme.textTheme.labelSmall!.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: theme.textTheme.labelSmall!.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                fontWeight: FontWeight.w600,
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              cellMargin: const EdgeInsets.all(4),
            ),
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final isCompleted =
                    habit.completedDates.any((d) => isSameDay(d, day));
                if (isCompleted) {
                  return _buildCalendarDay(theme, day, habit.color,
                      isFilled: true);
                }
                return Center(
                  child: Text(
                    '${day.day}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
              todayBuilder: (context, day, focusedDay) {
                final isCompleted =
                    habit.completedDates.any((d) => isSameDay(d, day));
                if (isCompleted) {
                  return _buildCalendarDay(theme, day, habit.color,
                      isFilled: true, isToday: true);
                }
                return _buildCalendarDay(theme, day, habit.color,
                    isFilled: false, isToday: true);
              },
              disabledBuilder: (context, day, focusedDay) {
                return Center(
                  child: Text(
                    '${day.day}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarDay(ThemeData theme, DateTime day, Color color,
      {required bool isFilled, bool isToday = false}) {
    return Container(
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isFilled ? color : Colors.transparent,
        shape: BoxShape.circle,
        border: isToday && !isFilled
            ? Border.all(color: color, width: 2)
            : isToday
                ? Border.all(color: theme.colorScheme.surface, width: 2)
                : null,
      ),
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: isFilled ? Colors.white : theme.colorScheme.onSurface,
          fontWeight: isToday || isFilled ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, {Widget? action}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (action != null) action,
      ],
    );
  }

  Widget _buildNotesList(ThemeData theme, Habit habit) {
    if (_isLoadingNotes) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    }

    if (_recentNotes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(Icons.edit_note,
                size: 40, color: theme.colorScheme.onSurface.withOpacity(0.2)),
            const SizedBox(height: 12),
            Text(
              'No notes yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _recentNotes
          .map((note) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(note.createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        Icon(Icons.sticky_note_2_outlined,
                            size: 16, color: habit.color.withOpacity(0.6)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (note.title.isNotEmpty)
                      Text(
                        note.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (note.content.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          note.content,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${date.day}/${date.month}';
  }

  Widget _buildInfoSection(Habit habit, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, 'Goal Settings'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              _buildInfoItem(theme, Icons.notifications_none,
                  '${habit.remindersPerDay} Daily', 'Reminders'),
              const SizedBox(width: 24),
              _buildInfoItem(
                  theme, Icons.calendar_today, 'Every Day', 'Frequency'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
      ThemeData theme, IconData icon, String value, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.onSurface),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5))),
          ],
        ),
      ],
    );
  }

  void _showAddNoteDialog(BuildContext context, Habit habit) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: theme.scaffoldBackgroundColor,
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Note',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Title',
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: habit.color, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 4,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Content',
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: habit.color, width: 1.5),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.isNotEmpty) {
                        await _saveNote(context, habit, titleController.text,
                            contentController.text);
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                        _loadNotes(); // Refresh list
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: habit.color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveNote(
      BuildContext context, Habit habit, String title, String content) async {
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

  void _confirmDeletion(BuildContext context, Habit habit, bool isPremium) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Habit'),
          content: Text('Are you sure you want to delete "${habit.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                final habitProvider =
                    Provider.of<HabitProvider>(context, listen: false);
                await habitProvider.deleteHabit(habit.id, isPremium: isPremium);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop(); // Dialog
                }
                if (context.mounted) {
                  Navigator.of(context).pop(); // Screen
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
