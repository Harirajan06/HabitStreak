import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../providers/habit_provider.dart';

class HeroStatsCard extends StatelessWidget {
  final int currentStreak;
  final int weeklyCompletionPercentage;
  final HabitProvider habitProvider;

  const HeroStatsCard({
    super.key,
    required this.currentStreak,
    required this.weeklyCompletionPercentage,
    required this.habitProvider,
  });

  String _getMotivationalMessage() {
    if (weeklyCompletionPercentage >= 90) {
      return "You're on fire! Incredible work!";
    } else if (weeklyCompletionPercentage >= 70) {
      return "Great job! Keep pushing forward!";
    } else if (weeklyCompletionPercentage >= 50) {
      return "Good progress! Stay consistent!";
    } else if (weeklyCompletionPercentage >= 30) {
      return "Getting started! Keep it up!";
    } else {
      return "Every journey starts with a step!";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final isMediumScreen = size.width < 600;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withAlpha((0.2 * 255).toInt()),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Streak Section
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Flame Animation
                SizedBox(
                  width: isSmallScreen ? 50 : 60,
                  height: isSmallScreen ? 50 : 60,
                  child: currentStreak > 0
                      ? Builder(builder: (context) {
                          // Compute best all-habits streak from provider
                          final activeHabits = habitProvider.activeHabits;
                          int bestStreak = 0;
                          if (activeHabits.isNotEmpty) {
                            final today = DateTime.now();
                            DateTime earliestDate = today;
                            for (var habit in activeHabits) {
                              if (habit.createdAt.isBefore(earliestDate)) {
                                earliestDate = habit.createdAt;
                              }
                            }

                            int current = 0;
                            for (int daysFromStart = 0;
                                daysFromStart <=
                                    today.difference(earliestDate).inDays;
                                daysFromStart++) {
                              final checkDate = earliestDate
                                  .add(Duration(days: daysFromStart));
                              bool allHabitsCompleted = true;

                              // Get habits that existed on this date
                              List habitsOnDate = activeHabits
                                  .where((habit) =>
                                      !habit.createdAt.isAfter(checkDate))
                                  .toList();

                              if (habitsOnDate.isEmpty) {
                                current = 0;
                                continue;
                              }

                              for (var habit in habitsOnDate) {
                                bool habitCompleted = habit.completedDates.any(
                                    (date) =>
                                        date.year == checkDate.year &&
                                        date.month == checkDate.month &&
                                        date.day == checkDate.day);
                                if (!habitCompleted) {
                                  allHabitsCompleted = false;
                                  break;
                                }
                              }

                              if (allHabitsCompleted) {
                                current++;
                                if (current > bestStreak) bestStreak = current;
                              } else {
                                current = 0;
                              }
                            }
                          }

                          // Show gold flame only when user reaches a 10-day streak
                          final bool isGold = currentStreak >= 10;

                          final lottie = Lottie.asset(
                            'assets/animations/Flame animation(1).json',
                            fit: BoxFit.contain,
                            repeat: true,
                          );

                          if (isGold) {
                            // Tint the animation to gold using ShaderMask
                            return ShaderMask(
                              blendMode: BlendMode.srcATop,
                              shaderCallback: (rect) =>
                                  const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFD700)],
                              ).createShader(rect),
                              child: lottie,
                            );
                          }

                          return lottie;
                        })
                      : Icon(
                          Icons.local_fire_department_outlined,
                          size: isSmallScreen ? 40 : 50,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Streak',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                        fontSize: isSmallScreen ? 13 : null,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 2 : 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$currentStreak',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            fontSize: isSmallScreen ? 32 : null,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 4 : 6),
                        Padding(
                          padding:
                              EdgeInsets.only(bottom: isSmallScreen ? 4 : 6),
                          child: Text(
                            'days',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 14 : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),

          // Divider
          Container(
            height: 1,
            margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 10 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  theme.colorScheme.primary.withAlpha((0.5 * 255).toInt()),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 16 : 20),

          // Weekly Completion Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly Progress',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                  fontSize: isSmallScreen ? 11 : null,
                ),
              ),
              SizedBox(height: isSmallScreen ? 8 : 10),
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    Container(
                      height: isSmallScreen ? 10 : 12,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.08 * 255).toInt()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: weeklyCompletionPercentage / 100,
                      child: Container(
                        height: isSmallScreen ? 10 : 12,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withAlpha((0.7 * 255).toInt()),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withAlpha((0.5 * 255).toInt()),
                              blurRadius: 8,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmallScreen ? 6 : 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '$weeklyCompletionPercentage% Complete',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: isSmallScreen ? 11 : null,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '${habitProvider.completedTodayCount}/${habitProvider.activeHabits.length} Today',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 11 : null,
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),

          // Motivational Message
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: isSmallScreen ? 10 : 14,
              horizontal: isSmallScreen ? 12 : 16,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha((0.12 * 255).toInt()),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withAlpha((0.25 * 255).toInt()),
                width: 1,
              ),
            ),
            child: Text(
              _getMotivationalMessage(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withAlpha((0.95 * 255).toInt()),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                fontSize: isSmallScreen ? 12 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
