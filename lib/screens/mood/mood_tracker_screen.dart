import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'mood_entry_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/mood_details_bottom_sheet.dart';
import '../../providers/mood_provider.dart';
import '../../providers/note_provider.dart';
import '../../models/note.dart';
import 'mood_analysis_screen.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Initialize MoodProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MoodProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<MoodProvider>(
      builder: (context, moodProvider, _) {
        final now = DateTime.now();
        // Just checking today's date
        final todayMood =
            moodProvider.getMoodForDate(DateTime(now.year, now.month, now.day));

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor:
                theme.colorScheme.surface.withAlpha((0.95 * 255).round()),
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9B5DE5).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mood,
                    color: Color(0xFF9B5DE5),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Mood',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.workspace_premium),
                color: theme.colorScheme.onSurface,
                onPressed: () {
                  // TODO: Premium feature
                },
              ),
              IconButton(
                icon: const Icon(Icons.person_outline),
                color: theme.colorScheme.onSurface,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildCalendar(theme),
                const SizedBox(height: 20),
                _buildMoodEntryCard(theme),
                const SizedBox(height: 16),
                _buildMoodAnalysisCard(theme),
                const SizedBox(height: 100), // Bottom padding for nav bar
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendar(ThemeData theme) {
    return Consumer<MoodProvider>(
      builder: (context, moodProvider, _) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.15),
            ),
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: theme.colorScheme.onSurface,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface,
              ),
              titleTextStyle: theme.textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              headerPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: theme.textTheme.bodySmall!.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
              weekendStyle: theme.textTheme.bodySmall!.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            calendarStyle: CalendarStyle(
              cellMargin:
                  const EdgeInsets.all(2), // Reduced margin for larger circles
              defaultDecoration: BoxDecoration(
                color: const Color(0xFF9B5DE5).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF9B5DE5).withOpacity(0.3),
              ),
              todayDecoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF9B5DE5),
                  width: 2,
                ),
              ),
              outsideDecoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              weekendDecoration: BoxDecoration(
                color: const Color(0xFF9B5DE5).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              defaultTextStyle: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              weekendTextStyle: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              selectedTextStyle: theme.textTheme.bodyMedium!.copyWith(
                color: const Color(0xFF9B5DE5),
                fontWeight: FontWeight.bold,
              ),
              todayTextStyle: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              outsideTextStyle: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final moodProvider =
                    Provider.of<MoodProvider>(context, listen: false);
                if (moodProvider.hasMoodForDate(day)) {
                  final moodEntry = moodProvider.getMoodForDate(day)!;
                  return Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        moodEntry.emoji,
                        style: const TextStyle(fontSize: 34),
                      ),
                    ),
                  );
                }
                return null;
              },
              todayBuilder: (context, day, focusedDay) {
                final moodProvider =
                    Provider.of<MoodProvider>(context, listen: false);
                if (moodProvider.hasMoodForDate(day)) {
                  final moodEntry = moodProvider.getMoodForDate(day)!;
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF9B5DE5).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        moodEntry.emoji,
                        style: const TextStyle(fontSize: 34),
                      ),
                    ),
                  );
                }
                return null;
              },
              selectedBuilder: (context, day, focusedDay) {
                final moodProvider =
                    Provider.of<MoodProvider>(context, listen: false);
                if (moodProvider.hasMoodForDate(day)) {
                  final moodEntry = moodProvider.getMoodForDate(day)!;
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF9B5DE5),
                        width: 2,
                      ),
                      color: theme.colorScheme.surface,
                    ),
                    child: Center(
                      child: Text(
                        moodEntry.emoji,
                        style: const TextStyle(fontSize: 34),
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });

              final moodProvider =
                  Provider.of<MoodProvider>(context, listen: false);
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final selected = DateTime(
                  selectedDay.year, selectedDay.month, selectedDay.day);

              // Block future dates
              if (selected.isAfter(today)) {
                _showFloatingWarning(
                    context, 'Cannot create mood for future dates');
                return;
              }

              // Check if this day has a saved mood entry
              // Check if this day has a saved mood entry
              if (moodProvider.hasMoodForDate(selectedDay)) {
                // Show existing mood details
                final moodEntry = moodProvider.getMoodForDate(selectedDay)!;
                MoodDetailsBottomSheet.show(
                  context,
                  date: selectedDay,
                  moodEmoji: moodEntry.emoji,
                  moodLabel: moodEntry.label,
                  tags: moodEntry.tags,
                  notes: moodEntry.notes,
                  onEdit: () async {
                    Navigator.pop(context); // Close bottom sheet
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MoodEntryScreen(
                          selectedDate: selectedDay,
                          initialMood: moodEntry.label,
                          initialTags: moodEntry.tags,
                          initialNotes: moodEntry.notes,
                        ),
                      ),
                    );

                    if (result != null && result is Map) {
                      await moodProvider.saveMood(
                        date: selectedDay,
                        emoji: result['emoji'],
                        label: result['label'],
                        tags: (result['tags'] as List<dynamic>).cast<String>(),
                        notes: result['notes'],
                        score: result['score'] ?? 0,
                      );

                      // Sync Note
                      if (result['notes'] != null &&
                          result['notes'].toString().isNotEmpty) {
                        try {
                          final noteProvider =
                              Provider.of<NoteProvider>(context, listen: false);
                          final dateKey =
                              '${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}';
                          final newNote = Note(
                            id: 'mood_$dateKey',
                            title:
                                'Mood: ${result['label']} ${result['emoji']}',
                            content: result['notes'],
                            createdAt: selectedDay,
                            updatedAt: DateTime.now(),
                            tags: [
                              'Mood',
                              ...(result['tags'] as List<dynamic>)
                                  .cast<String>()
                            ],
                          );
                          await noteProvider.addNote(newNote);
                        } catch (e) {
                          debugPrint('Error syncing mood note: $e');
                        }
                      }
                    }
                  },
                );
              } else {
                // Open mood entry screen to create new entry
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                    builder: (_) => MoodEntryScreen(
                      selectedDate: selectedDay,
                    ),
                  ),
                )
                    .then((result) async {
                  // Handle saved mood data if returned
                  if (result != null && result is Map<String, dynamic>) {
                    await moodProvider.saveMood(
                      date: selectedDay,
                      emoji: result['emoji'] as String,
                      label: result['label'] as String,
                      tags: List<String>.from(result['tags'] as List),
                      notes: result['notes'] as String,
                      score: result['score'] as int? ?? 0,
                    );

                    // Sync Note
                    if (result['notes'] != null &&
                        result['notes'].toString().isNotEmpty) {
                      try {
                        final noteProvider =
                            Provider.of<NoteProvider>(context, listen: false);
                        final dateKey =
                            '${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}';
                        final newNote = Note(
                          id: 'mood_$dateKey',
                          title: 'Mood: ${result['label']} ${result['emoji']}',
                          content: result['notes'],
                          createdAt: selectedDay,
                          updatedAt: DateTime.now(),
                          tags: [
                            'Mood',
                            ...List<String>.from(result['tags'] as List)
                          ],
                        );
                        await noteProvider.addNote(newNote);
                      } catch (e) {
                        debugPrint('Error syncing mood note: $e');
                      }
                    }
                  }
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
        );
      },
    );
  }

  Widget _buildMoodEntryCard(ThemeData theme) {
    return Consumer<MoodProvider>(
      builder: (context, moodProvider, _) {
        final now = DateTime.now();
        final todayMood =
            moodProvider.getMoodForDate(DateTime(now.year, now.month, now.day));

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF9B5DE5).withOpacity(0.8),
                const Color(0xFF9B5DE5).withOpacity(0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MoodEntryScreen(
                      selectedDate: _selectedDay ?? DateTime.now(),
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: todayMood != null
                              ? Text(
                                  todayMood.emoji,
                                  style: const TextStyle(fontSize: 28),
                                )
                              : const Icon(
                                  Icons.mood,
                                  color: Colors.white,
                                  size: 28,
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                todayMood != null
                                    ? 'Your mood today matters!'
                                    : 'How was your day today?',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                todayMood != null
                                    ? 'Keep tracking your journey'
                                    : 'Take a moment to reflect',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        final hasMood = todayMood != null;
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MoodEntryScreen(
                              selectedDate:
                                  DateTime(now.year, now.month, now.day),
                              initialMood: hasMood ? todayMood.label : null,
                              initialTags: hasMood ? todayMood.tags : null,
                              initialNotes: hasMood ? todayMood.notes : null,
                            ),
                          ),
                        );

                        if (result != null && result is Map) {
                          await moodProvider.saveMood(
                            date: DateTime(now.year, now.month, now.day),
                            emoji: result['emoji'],
                            label: result['label'],
                            tags: (result['tags'] as List<dynamic>)
                                .cast<String>(),
                            notes: result['notes'],
                            score: result['score'] ?? 0,
                          );

                          // Sync Note
                          if (result['notes'] != null &&
                              result['notes'].toString().isNotEmpty) {
                            try {
                              final noteProvider = Provider.of<NoteProvider>(
                                  context,
                                  listen: false);
                              final today =
                                  DateTime(now.year, now.month, now.day);
                              final dateKey =
                                  '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
                              final newNote = Note(
                                id: 'mood_$dateKey',
                                title:
                                    'Mood: ${result['label']} ${result['emoji']}',
                                content: result['notes'],
                                createdAt:
                                    DateTime(now.year, now.month, now.day),
                                updatedAt: DateTime.now(),
                                tags: [
                                  'Mood',
                                  ...(result['tags'] as List<dynamic>)
                                      .cast<String>()
                                ],
                              );
                              await noteProvider.addNote(newNote);
                            } catch (e) {
                              debugPrint('Error syncing mood note: $e');
                            }
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          todayMood != null
                              ? 'Update if feelings changed'
                              : 'Log Mood',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoodAnalysisCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF9B5DE5).withOpacity(0.6), // Purple
            const Color(0xFFFFD700).withOpacity(0.6), // Yellow
            const Color(0xFF1A1A1A).withOpacity(0.8), // Black
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MoodAnalysisScreen(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Color(0xFF9B5DE5),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mood Analysis',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Monthly summary & daily trends',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9B5DE5).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'View',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF9B5DE5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF9B5DE5),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFloatingWarning(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final theme = Theme.of(context);

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF9B5DE5), // App theme purple
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Colors.white, // White icon for contrast
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white, // White text for contrast
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Remove after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      overlayEntry.remove();
    });
  }
}
