import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../profile/profile_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/mood_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/habit_provider.dart';
import '../../models/habit.dart';
import '../../models/note.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Note> _filteredNotes = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Refresh notes after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _syncMoodNotes();
      if (mounted) {
        await _refreshNotes();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshNotes();
    }
  }

  Future<void> _syncMoodNotes() async {
    if (!mounted) return;
    final moodProvider = Provider.of<MoodProvider>(context, listen: false);
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);

    // Ensure moods and notes are loaded
    if (!moodProvider.isInitialized) {
      await moodProvider.initialize();
    }
    await noteProvider
        .loadNotes(); // Critical: Load notes so we can find duplicates!

    final moods = moodProvider.getAllMoods();

    // Notes to delete (duplicates)
    final notesToDelete = <String>[];

    for (final mood in moods) {
      if (mood.notes.isNotEmpty) {
        final dateKey = _getDateKey(mood.date);
        final noteId = 'mood_$dateKey';

        // 1. Ensure the Canonical Note exists (Upsert)
        final newNote = Note(
          id: noteId,
          title: 'Mood: ${mood.label} ${mood.emoji}',
          content: mood.notes,
          createdAt: mood.date,
          updatedAt: DateTime.now(),
          tags: ['Mood', ...mood.tags],
        );
        await noteProvider
            .addNote(newNote); // Updates if exists, creates if not

        // 2. Identify duplicates for this day
        // We look for notes that:
        // - Are NOT the canonical ID
        // - Have the 'Mood' tag
        // - Have a title starting with 'Mood:'
        // - Match the same date (approximate check via dateKey or simply day matching)

        final duplicates = noteProvider.notes.where((n) {
          if (n.id == noteId) return false; // Don't delete self

          final isMood = n.tags.contains('Mood') || n.title.startsWith('Mood:');
          if (!isMood) return false;

          // Check date match
          final nDateKey = _getDateKey(n.createdAt);
          return nDateKey == dateKey;
        });

        for (final dup in duplicates) {
          if (!notesToDelete.contains(dup.id)) {
            notesToDelete.add(dup.id);
          }
        }
      }
    }

    // Execute deletions
    for (final id in notesToDelete) {
      await noteProvider.deleteNote(id);
    }
  }

  Future<void> _refreshNotes() async {
    if (!mounted) return;
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    await noteProvider.loadNotes();
    if (!mounted) return; // Check mounted again after async operation
    setState(() {
      _filteredNotes = noteProvider.notes;
    });
  }

  void _filterNotes(String query) {
    if (!mounted) return;
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    if (query.isEmpty) {
      setState(() {
        _filteredNotes = noteProvider.notes;
      });
    } else {
      noteProvider.searchNotes(query).then((results) {
        if (!mounted) return; // Check mounted after async operation
        setState(() {
          _filteredNotes = results;
        });
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: theme.colorScheme.outline.withAlpha((0.1 * 255).round())),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withAlpha((0.05 * 255).round()),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.note_add_outlined,
                size: 40,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Notes Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start documenting your habit journey!\nCapture insights, reflections, and progress.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color:
                    theme.colorScheme.onSurface.withAlpha((0.7 * 255).round()),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRoadmapView(BuildContext context) {
    final theme = Theme.of(context);

    // Group notes by date
    final groupedNotes = <String, List<Note>>{};
    for (final note in _filteredNotes) {
      final dateKey = _getDateKey(note.createdAt);
      if (!groupedNotes.containsKey(dateKey)) {
        groupedNotes[dateKey] = [];
      }
      groupedNotes[dateKey]!.add(note);
    }

    final sortedDates = groupedNotes.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Column(
        children: [
          for (int i = 0; i < sortedDates.length; i++)
            _buildDayTimeline(
              context,
              sortedDates[i],
              groupedNotes[sortedDates[i]]!,
              i == sortedDates.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _buildDayTimeline(
      BuildContext context, String dateStr, List<Note> notes, bool isLast) {
    final theme = Theme.of(context);

    // Sort notes: Mood first
    final sortedNotes = List<Note>.from(notes)
      ..sort((a, b) {
        final aIsMood = a.tags.contains('Mood') || a.title.startsWith('Mood:');
        final bIsMood = b.tags.contains('Mood') || b.title.startsWith('Mood:');
        if (aIsMood && !bIsMood) return -1;
        if (!aIsMood && bIsMood) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

    final dateLabel = _formatDateDetailed(dateStr);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Column
          SizedBox(
            width: 24,
            child: Column(
              children: [
                // Dot (Start of Day)
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(
                      vertical: 2), // Align more with card top
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFA855F7), // Purple color
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFA855F7).withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFA855F7), // Purple center
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                // Line (Connects to next day)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.only(top: 4, bottom: 4),
                    decoration: BoxDecoration(
                      gradient: isLast
                          ? null
                          : LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFFA855F7).withOpacity(0.8),
                                const Color(0xFFA855F7).withOpacity(0.3),
                              ],
                            ),
                      color: isLast ? Colors.transparent : null,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notes List (Header removed, integrated into cards)
                for (final note in sortedNotes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildRoadmapNoteCard(context, note, dateLabel),
                  ),

                // Extra spacing if not last
                if (!isLast) const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadmapNoteCard(
      BuildContext context, Note note, String dateLabel) {
    final theme = Theme.of(context);
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    Habit? habit;
    if (note.habitId != null) {
      try {
        habit = habitProvider.habits.firstWhere((h) => h.id == note.habitId);
      } catch (e) {
        habit = null;
      }
    }

    final bool isMoodNote =
        note.tags.contains('Mood') || note.title.startsWith('Mood:');

    Color? moodColor;
    String moodEmoji = '';

    if (isMoodNote) {
      final parts = note.title.split(' ');
      if (parts.length >= 2) {
        final label = parts[1];
        if (parts.length >= 3) {
          moodEmoji = parts.sublist(2).join(' ');
        }

        const moodColors = {
          'Broken': Color(0xFF8B0000),
          'Angry': Color(0xFFFF6B00),
          'Sad': Color(0xFFFFB800),
          'Anxious': Color(0xFF6B4423),
          'Stressed': Color(0xFF5C4033),
          'Tired': Color(0xFF4A5568),
          'Neutral': Color(0xFF718096),
          'Close': Color(0xFFFF69B4),
          'Caring': Color(0xFFFFD700),
          'Love': Color(0xFFFF1493),
          'Energetic': Color(0xFF8B7500),
          'Motivated': Color(0xFF4169E1),
          'Excited': Color(0xFF7CFC00),
          'Relaxed': Color(0xFF20B2AA),
          'Happy': Color(0xFFFFD700),
          'Pleasant': Color(0xFF87CEEB),
        };
        moodColor = moodColors[label];
      }
    }

    final Color accentColor = isMoodNote
        ? (moodColor ?? const Color(0xFF9B5DE5))
        : (habit?.color ?? theme.colorScheme.primary);

    final Color cardBgColor = theme.cardColor;
    final Color headerBgColor = accentColor.withOpacity(0.15);
    final Color cardBorderColor = theme.colorScheme.outline.withOpacity(0.1);

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: headerBgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                if (note.habitId != null && habit != null) ...[
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: habit.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      habit.icon,
                      size: 14,
                      color: habit.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      habit.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: habit.color.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Date for Habit
                  Text(
                    dateLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: habit.color.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else if (isMoodNote) ...[
                  // Date Label (Replacing 'Mood')
                  Text(
                    dateLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: accentColor.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // Emoji (Replacing Icon)
                  if (moodEmoji.isNotEmpty)
                    Text(
                      moodEmoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                ],
              ],
            ),
          ),

          // Body Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.title.isNotEmpty && !isMoodNote)
                  Text(
                    note.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                if (isMoodNote)
                  Text(
                    note.content.isNotEmpty
                        ? note.content
                        : (note.title.split(' ').length > 1
                            ? note.title.split(' ')[1]
                            : ''),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                if (!isMoodNote && note.title.isNotEmpty)
                  const SizedBox(height: 4),
                if (!isMoodNote)
                  Text(
                    note.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      height: 1.3,
                    ),
                  ),
                if (note.tags.isNotEmpty && !isMoodNote) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: note.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateDetailed(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            theme.colorScheme.surface.withAlpha((0.95 * 255).round()),
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 16),
            SizedBox(
              height: 40,
              width: 40,
              child: Lottie.asset(
                'assets/animations/Flame animation(1).json',
                repeat: true,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Streakly',
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
            onPressed: () {},
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
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            splashRadius: 22,
            onPressed: () {
              if (!mounted) return;
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  final noteProvider =
                      Provider.of<NoteProvider>(context, listen: false);
                  _filteredNotes = noteProvider.notes;
                }
              });
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isSearching)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: theme.colorScheme.outline
                          .withAlpha((0.2 * 255).round())),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterNotes,
                  decoration: const InputDecoration(
                    hintText: 'Search notes...',
                    border: InputBorder.none,
                    icon: Icon(Icons.search),
                  ),
                ),
              ),
            // 'Reflect on your progress' card removed per request
            Expanded(
              child: Consumer<NoteProvider>(
                builder: (context, noteProvider, child) {
                  if (noteProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final notesToShow =
                      _isSearching && _searchController.text.isNotEmpty
                          ? _filteredNotes
                          : noteProvider.notes;

                  if (notesToShow.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  // Update filtered notes if not searching
                  if (!_isSearching || _searchController.text.isEmpty) {
                    _filteredNotes = notesToShow;
                  }

                  return _buildRoadmapView(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
