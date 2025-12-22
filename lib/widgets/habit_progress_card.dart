import 'package:flutter/material.dart';
import '../models/habit.dart';
import 'habit_detail_bottom_sheet.dart';
import 'habit_note_icon_button.dart';
import 'multi_completion_button.dart';
import 'marquee_widget.dart';

class HabitProgressCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback? onPressed;

  const HabitProgressCard({
    super.key,
    required this.habit,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed ?? () => HabitDetailBottomSheet.show(context, habit),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: habit.color.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      habit.icon,
                      color: habit.color,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarqueeWidget(
                        child: Text(
                          habit.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Habit Type Indicator (Linear Design)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: habit.habitType == HabitType.build
                                  ? Colors.green
                                  : Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            habit.habitType == HabitType.build
                                ? 'Build'
                                : 'Break',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: habit.habitType == HabitType.build
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Streak Badge
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
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${habit.currentStreak} day streak',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HabitNoteIconButton(habit: habit),
                    const SizedBox(width: 6),
                    MultiCompletionButton(habit: habit),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
