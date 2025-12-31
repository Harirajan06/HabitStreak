import 'package:flutter/material.dart';
import 'habits/habit_grid_screen.dart';
import 'habits/habits_screen.dart';
import 'notes/notes_screen.dart';
import 'notes/add_note_screen.dart';
import 'habits/add_habit_screen.dart';
import 'profile/analysis_screen.dart';
import 'mood/mood_tracker_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/habit_provider.dart';
import '../widgets/premium_lock_dialog.dart';
import '../services/navigation_service.dart';
import '../mixins/widget_logic_mixin.dart';
import 'mood/mood_entry_screen.dart';
import '../providers/mood_provider.dart';
import '../providers/note_provider.dart';
import '../models/note.dart';

/// MainNavigationScreen provides persistent bottom navigation for the grid view mode
/// This ensures all screens maintain the navigation bar when accessed from grid view

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetLogicMixin {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    // Set current tab in NavigationService
    NavigationService.setCurrentTab(_currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    NavigationService.setCurrentTab(index);
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
          NavigationService.setCurrentTab(index);
        },
        physics:
            const BouncingScrollPhysics(), // Enable smooth scrolling with bounce effect
        allowImplicitScrolling: false,
        children: [
          NavigationService.isGridViewMode
              ? const HabitGridScreen()
              : const HabitsScreen(),
          AnalysisScreen(),
          MoodTrackerScreen(),
          NotesScreen(),
        ],
      ),
      floatingActionButton: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            if (_currentIndex == 3) {
              // Notes Tab - Add Note
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddNoteScreen()),
              );
            } else if (_currentIndex == 2) {
              // Mood Tab - Add Mood
              final moodProvider =
                  Provider.of<MoodProvider>(context, listen: false);
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);

              Navigator.of(context)
                  .push(
                MaterialPageRoute(
                  builder: (_) => MoodEntryScreen(
                    selectedDate: today,
                  ),
                ),
              )
                  .then((result) async {
                if (result != null && result is Map) {
                  await moodProvider.saveMood(
                    date: today,
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
                      if (!context.mounted) return;
                      final noteProvider =
                          Provider.of<NoteProvider>(context, listen: false);
                      final dateKey =
                          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
                      final newNote = Note(
                        id: 'mood_$dateKey',
                        title: 'Mood: ${result['label']} ${result['emoji']}',
                        content: result['notes'],
                        createdAt: today,
                        updatedAt: DateTime.now(),
                        tags: [
                          'Mood',
                          ...(result['tags'] as List<dynamic>).cast<String>()
                        ],
                      );
                      await noteProvider.addNote(newNote);
                    } catch (e) {
                      debugPrint('Error syncing mood note: $e');
                    }
                  }
                }
              });
            } else {
              // Other Tabs - Add Habit
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              final habitProvider =
                  Provider.of<HabitProvider>(context, listen: false);

              final isPremium = authProvider.currentUser?.premium ?? false;
              final habitCount = habitProvider.habits.length;

              if (!isPremium && habitCount >= 3) {
                showPremiumLockDialog(context,
                    'Free plan is limited to 3 habits. Upgrade to Pro for unlimited habits!');
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddHabitScreen()),
                );
              }
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(
            _currentIndex == 3
                ? Icons.note_add
                : (_currentIndex == 2 ? Icons.mood : Icons.add),
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
      floatingActionButtonLocation: MediaQuery.of(context).viewInsets.bottom > 0
          ? FloatingActionButtonLocation.endFloat
          : FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomAppBar(
          elevation: 0,
          color: Theme.of(context).bottomAppBarTheme.color,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          child: SizedBox(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                    child: _buildNavItem(0, Icons.track_changes_outlined,
                        Icons.track_changes, 'Habits')),
                Expanded(
                    child: _buildNavItem(1, Icons.bar_chart,
                        Icons.bar_chart_rounded, 'Analysis')),
                const SizedBox(width: 60), // Space for FAB
                Expanded(
                    child: _buildNavItem(
                        2, Icons.mood_outlined, Icons.mood, 'Mood')),
                Expanded(
                    child: _buildNavItem(
                        3, Icons.note_outlined, Icons.note, 'Notes')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData icon, IconData selectedIcon, String label) {
    final isSelected = index == _currentIndex;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              size: 22,
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
