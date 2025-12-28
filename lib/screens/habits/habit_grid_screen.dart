import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import 'habit_detail_screen.dart'; // Add this import
import '../../widgets/habit_note_icon_button.dart';
import '../../widgets/multi_completion_button.dart';
import '../main_navigation_screen.dart';
import '../profile/profile_screen.dart';
import '../../services/navigation_service.dart';
import '../subscription/subscription_plans_screen.dart';
import '../../providers/auth_provider.dart'; // Import AuthProvider
import '../../widgets/marquee_widget.dart';

class HabitGridScreen extends StatefulWidget {
  const HabitGridScreen({super.key});

  @override
  State<HabitGridScreen> createState() => _HabitGridScreenState();
}

class _HabitGridScreenState extends State<HabitGridScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HabitProvider>(context, listen: false).loadHabits();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            theme.colorScheme.surface.withAlpha((0.95 * 255).round()),
        elevation: 0,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
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
            RichText(
              text: TextSpan(
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: 'Habit',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  TextSpan(
                    text: ' Sensai',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_module),
            onPressed: () => _showViewOptionsBottomSheet(context),
          ),
          IconButton(
            icon: Icon(
              Icons.workspace_premium,
              color: const Color(0xFFFFD700), // Gold color
              size: 28,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SubscriptionPlansScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, size: 24),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<HabitProvider>(
          builder: (context, habitProvider, child) {
            if (habitProvider.isLoading) {
              return Center(
                child:
                    CircularProgressIndicator(color: theme.colorScheme.primary),
              );
            }

            if (habitProvider.habits.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.track_changes,
                        size: 80,
                        color: theme.colorScheme.onSurface
                            .withAlpha((0.3 * 255).round())),
                    const SizedBox(height: 16),
                    Text(
                      'No habits found',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withAlpha((0.6 * 255).round()),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add some habits to see your progress grid',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withAlpha((0.4 * 255).round()),
                      ),
                    ),
                  ],
                ),
              );
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 20, 12, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == 0) {
                          final now = DateTime.now();
                          final day = now.day;
                          final monthNames = [
                            '',
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
                          String getDaySuffix(int d) {
                            if (d >= 11 && d <= 13) return 'th';
                            switch (d % 10) {
                              case 1:
                                return 'st';
                              case 2:
                                return 'nd';
                              case 3:
                                return 'rd';
                              default:
                                return 'th';
                            }
                          }

                          final todayString =
                              'Today, $day${getDaySuffix(day)} ${monthNames[now.month]}';
                          return Padding(
                            padding: const EdgeInsets.only(
                                bottom: 14, left: 4, right: 4, top: 2),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Today, ',
                                    style:
                                        theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 26,
                                    ),
                                  ),
                                  TextSpan(
                                    text: todayString.substring(7),
                                    style:
                                        theme.textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w400,
                                      color: theme.colorScheme.primary
                                          .withAlpha((0.8 * 255).round()),
                                      fontSize: 26,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        final habit = habitProvider.habits[index - 1];
                        return _buildHabitCard(habit, theme);
                      },
                      childCount: habitProvider.habits.length + 1,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHabitCard(Habit habit, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10), // Reduced margin
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => HabitDetailScreen.show(context, habit),
          onLongPress: () => _showHabitOptionsMenu(habit),
          child: Container(
            padding: const EdgeInsets.all(10), // Reduced padding
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      // Constrain the left side to available space
                      child: Row(
                        children: [
                          Container(
                            width: 38, // Reduced size
                            height: 38, // Reduced size
                            decoration: BoxDecoration(
                              color: Color.lerp(habit.color, Colors.grey, 0.3)!
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              habit.icon,
                              color: Color.lerp(habit.color, Colors.grey, 0.3),
                              size: 20, // Reduced icon size
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            // Constrain the text column
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MarqueeWidget(
                                  // Auto-scrolls if too long
                                  child: Text(
                                    habit.name,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    maxLines:
                                        1, // Ensure single line for marquee
                                  ),
                                ),
                                Row(
                                  children: [
                                    ShaderMask(
                                      shaderCallback: (Rect bounds) {
                                        return LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0xFFD0A9F5),
                                            Color(0xFF9B5DE5),
                                          ],
                                        ).createShader(bounds);
                                      },
                                      child: const Icon(
                                        Icons.local_fire_department,
                                        color: Colors.white,
                                        size: 14, // Reduced size
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_calculateCurrentStreak(habit)} day streak',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11, // Slightly smaller text
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                        width: 8), // Spacing between text and buttons
                    Row(
                      mainAxisSize: MainAxisSize.min, // Keep buttons tight
                      children: [
                        HabitNoteIconButton(
                            habit: habit,
                            size: 38,
                            isSquare: true), // Reduced size
                        const SizedBox(width: 6),
                        MultiCompletionButton(
                            habit: habit,
                            size: 38,
                            isSquare: true), // Reduced size
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8), // Reduced spacing
                _buildYearGrid(habit, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildYearGrid(Habit habit, ThemeData theme) {
    const int rows = 7;
    const double cellSize = 10.0;
    const double spacing = 2.0;

    final now = DateTime.now();

    // Rolling Grid Logic:
    // 1. End point: "Today" is in the last (right-most) column.
    // 2. Start point: habit.createdAt (or at least ~20 weeks back for looks).
    // 3. Columns: Calculate total weeks needed.

    // Calculate Week Start (Sunday) for 'Now'
    final currentWeekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday == 7 ? 0 : now.weekday));

    // Calculate Week Start (Sunday) for 'CreatedAt'
    final createdWeekStart = DateTime(
            habit.createdAt.year, habit.createdAt.month, habit.createdAt.day)
        .subtract(Duration(
            days: habit.createdAt.weekday == 7 ? 0 : habit.createdAt.weekday));

    // Calculate total weeks
    // Calculate total weeks
    final daysDiff = currentWeekStart.difference(createdWeekStart).inDays;
    int totalWeeks = (daysDiff / 7).ceil() + 1; // +1 to include current week

    // Ensure minimum visual width to fill grid (e.g., 52 weeks ~ 1 year)
    // This fills the space on the left side with past weeks, keeping "Today" pinned to the right.
    if (totalWeeks < 52) totalWeeks = 52;

    // For Left-to-Right growth (Oldest -> Newest):
    // Start drawing from createdWeekStart (or further back if using min visual width).
    // Actually, if we want to ensure 'totalWeeks' matches the visual,
    // we should base start date on 'end date - totalWeeks'.
    final effectiveStartDate =
        currentWeekStart.subtract(Duration(days: (totalWeeks - 1) * 7));

    // Controller for auto-scroll to end (Today)
    final ScrollController scrollController = ScrollController();

    // Schedule scroll to end after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: rows * (cellSize + spacing),
          child: SingleChildScrollView(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            reverse: false, // Standard Left-to-Right
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start, // Align to left
              children: List.generate(totalWeeks, (weekIndex) {
                // weekIndex 0 = Oldest displayed week

                final weekStart =
                    effectiveStartDate.add(Duration(days: weekIndex * 7));

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Column(
                    children: List.generate(rows, (dayOffset) {
                      // 0=Sun, 1=Mon...
                      final cellDate = weekStart.add(Duration(days: dayOffset));

                      // Key
                      final dateKey =
                          '${cellDate.year}-${cellDate.month.toString().padLeft(2, '0')}-${cellDate.day.toString().padLeft(2, '0')}';
                      final int completionCount =
                          habit.dailyCompletions[dateKey] ?? 0;
                      final int target =
                          habit.remindersPerDay > 0 ? habit.remindersPerDay : 1;

                      // Date Checks
                      final today = DateTime(now.year, now.month, now.day);
                      final isFutureDate = cellDate.isAfter(today);
                      final isPreCreation = cellDate.isBefore(DateTime(
                          habit.createdAt.year,
                          habit.createdAt.month,
                          habit.createdAt.day));

                      Color cellColor;

                      if (completionCount > 0) {
                        double opacity =
                            (completionCount / target).clamp(0.0, 1.0);
                        cellColor = habit.color.withOpacity(opacity);
                      } else if (isFutureDate) {
                        cellColor = habit.color.withOpacity(0.15);
                      } else if (isPreCreation) {
                        cellColor = habit.color.withOpacity(0.15);
                      } else {
                        cellColor = habit.color.withOpacity(0.40);
                      }

                      final isToday = cellDate.year == now.year &&
                          cellDate.month == now.month &&
                          cellDate.day == now.day;

                      return GestureDetector(
                        onTap: () => _onGridCellTap(habit, cellDate),
                        child: Container(
                          margin: EdgeInsets.all(spacing / 2),
                          width: cellSize,
                          height: cellSize,
                          decoration: BoxDecoration(
                            color: cellColor,
                            borderRadius: BorderRadius.circular(2),
                            border: isToday
                                ? Border.all(
                                    color: Colors.orangeAccent, width: 1.2)
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  void _onGridCellTap(Habit habit, DateTime date) {
    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tapped = DateTime(date.year, date.month, date.day);

    if (tapped.isAtSameMomentAs(today)) {
      final isPremium = authProvider.currentUser?.premium ?? false;
      habitProvider.toggleHabitCompletion(habit.id, context, isPremium);
    }
  }

  int _calculateCurrentStreak(Habit habit) {
    if (habit.completedDates.isEmpty) return 0;

    final sortedDates = habit.completedDates.toList()
      ..sort((a, b) => b.compareTo(a));

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    int streak = 0;
    DateTime? lastDate;

    for (var date in sortedDates) {
      final currentDate = DateTime(date.year, date.month, date.day);

      if (lastDate == null) {
        if (currentDate.isAfter(todayDate)) continue;
        lastDate = currentDate;
        streak = 1;
        continue;
      }

      final difference = lastDate.difference(currentDate).inDays;
      if (difference == 1) {
        streak++;
        lastDate = currentDate;
      } else {
        break;
      }
    }

    return streak;
  }

  void _showHabitOptionsMenu(Habit habit) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface
                      .withAlpha((0.3 * 255).round()),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                habit.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.widgets_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: const Text('Show Widget ID'),
                subtitle: const Text('Copy ID to configure widget'),
                onTap: () {
                  Navigator.pop(context);
                  _showWidgetIdDialog(habit);
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
                title: const Text('Delete Habit'),
                subtitle: const Text('Remove this habit permanently'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmationDialog(habit);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showWidgetIdDialog(Habit habit) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.widgets, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Widget ID'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Use this ID to configure your widget:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      habit.id,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      // Copy to clipboard
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Widget ID copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Copy ID',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'How to use:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '1. Long-press the widget on your home screen\n'
              '2. Tap "Edit Widget"\n'
              '3. Paste this ID in the "Habit ID" field',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(Habit habit) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isPremium = authProvider.currentUser?.premium ?? false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: const Text('Are you sure you want to delete this habit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<HabitProvider>(context, listen: false)
                  .deleteHabit(habit.id, isPremium: isPremium);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showViewOptionsBottomSheet(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface
                      .withAlpha((0.3 * 255).round()),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Choose View',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.list_alt,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: const Text('List View'),
                subtitle: const Text('View habits as cards'),
                trailing: Icon(
                  !NavigationService.isGridViewMode
                      ? Icons.check_circle
                      : Icons.chevron_right,
                  color: !NavigationService.isGridViewMode
                      ? theme.colorScheme.primary
                      : null,
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await NavigationService.setGridViewMode(false);
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) =>
                              const MainNavigationScreen(initialIndex: 0)),
                    );
                  }
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.grid_view,
                    color: Colors.orange,
                  ),
                ),
                title: const Text('Grid View'),
                subtitle: const Text('View habits with yearly progress'),
                trailing: Icon(
                  NavigationService.isGridViewMode
                      ? Icons.check_circle
                      : Icons.chevron_right,
                  color: NavigationService.isGridViewMode
                      ? theme.colorScheme.primary
                      : null,
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await NavigationService.setGridViewMode(true);
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => const MainNavigationScreen()),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
