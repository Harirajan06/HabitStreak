import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import 'marquee_widget.dart';

class ModernHabitCard extends StatelessWidget {
  final Habit habit;
  final int daysToShow;

  const ModernHabitCard({
    super.key,
    required this.habit,
    this.daysToShow = 30,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = habit.isCompletedToday();
    final isFullyCompleted = habit.isFullyCompletedToday();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Dismissible(
        key: ValueKey(habit.id),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            // Swipe left - Delete
            final habitProvider =
                Provider.of<HabitProvider>(context, listen: false);
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Habit'),
                content:
                    Text('Are you sure you want to delete "${habit.name}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              habitProvider.deleteHabit(habit.id);
              return true; // Allow dismiss
            }
            return false; // Cancel dismiss
          } else if (direction == DismissDirection.startToEnd) {
            // Swipe right - Quick complete (if not fully completed)
            if (!isFullyCompleted) {
              Provider.of<HabitProvider>(context, listen: false)
                  .toggleHabitCompletion(habit.id, context);
            }
            return false; // Don't dismiss
          }
          return false;
        },
        background: Container(
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isFullyCompleted
                    ? Icons.check_circle
                    : Icons.check_circle_outline,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(height: 4),
              Text(
                isFullyCompleted ? 'Completed' : 'Complete',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        secondaryBackground: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.delete,
                color: Colors.white,
                size: 32,
              ),
              SizedBox(height: 4),
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.1 * 255).round()),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Section - Header
                _buildHeader(context, isCompleted),
                const SizedBox(height: 16),

                // Main Section - Calendar Grid
                _buildCalendarGrid(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isCompleted) {
    final isFullyCompleted = habit.isFullyCompletedToday();
    final completionCount = habit.getTodayCompletionCount();
    final totalRequired = habit.remindersPerDay;

    return Row(
      children: [
        // Habit Icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: habit.color.withAlpha((0.2 * 255).round()),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            habit.icon,
            color: habit.color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),

        // Title and Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MarqueeWidget(
                child: Text(
                  habit.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    'Streak: ${habit.currentStreak}',
                    style: TextStyle(
                      color: Colors.white.withAlpha((0.7 * 255).round()),
                      fontSize: 12,
                    ),
                  ),
                  if (totalRequired > 1) ...[
                    const SizedBox(width: 8),
                    Text(
                      '• $completionCount/$totalRequired today',
                      style: TextStyle(
                        color: isFullyCompleted
                            ? Colors.green
                            : Colors.white.withAlpha((0.7 * 255).round()),
                        fontSize: 12,
                        fontWeight: isFullyCompleted
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        // Completion Status
        Consumer<HabitProvider>(
          builder: (context, habitProvider, child) {
            return GestureDetector(
              onTap: isFullyCompleted
                  ? null // Disable tap when fully completed
                  : () {
                      habitProvider.toggleHabitCompletion(habit.id, context);
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isFullyCompleted
                      ? Colors.green
                      : isCompleted
                          ? Colors.green.withAlpha((0.5 * 255).round())
                          : Colors.transparent,
                  border: Border.all(
                    color: isFullyCompleted
                        ? Colors.green
                        : isCompleted
                            ? Colors.green.withAlpha((0.5 * 255).round())
                            : Colors.white.withAlpha((0.3 * 255).round()),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: isCompleted
                    ? Icon(
                        isFullyCompleted ? Icons.check : Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final now = DateTime.now();
    final startDate = now.subtract(
        Duration(days: daysToShow - 7)); // Show past days + future days
    final days = <DateTime>[];

    // Generate days for the grid
    for (int i = 0; i < daysToShow; i++) {
      days.add(startDate.add(Duration(days: i)));
    }

    final orderedDays =
        days.reversed.toList(); // Recent dates should appear first visually.

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate how many cells can fit in a row
        const cellSize = 24.0;
        const spacing = 4.0;
        final availableWidth = constraints.maxWidth;
        final cellsPerRow =
            ((availableWidth + spacing) / (cellSize + spacing)).floor();

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          textDirection: TextDirection.ltr,
          children: orderedDays
              .map((day) => _buildDayCell(day, now, cellSize))
              .toList(),
        );
      },
    );
  }

  Widget _buildDayCell(DateTime day, DateTime now, double size) {
    final isToday = _isSameDay(day, now);
    final isFuture = day.isAfter(now);
    final isCompleted =
        habit.completedDates.any((date) => _isSameDay(date, day));
    final isMissed = !isFuture && !isCompleted && !isToday;

    Color cellColor;
    Color? borderColor;

    if (isFuture) {
      cellColor = Colors.grey.withAlpha((0.3 * 255).round());
    } else if (isCompleted) {
      cellColor = Colors.green;
    } else if (isMissed) {
      cellColor = Colors.red.withAlpha((0.8 * 255).round());
    } else {
      // Today but not completed
      cellColor = Colors.grey.withAlpha((0.3 * 255).round());
      borderColor = Colors.white.withAlpha((0.5 * 255).round());
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cellColor,
        borderRadius: BorderRadius.circular(4),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1)
            : null,
      ),
      child: isToday && !isCompleted
          ? Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
