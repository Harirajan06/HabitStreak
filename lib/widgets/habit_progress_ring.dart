import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/habit.dart';

class HabitProgressRing extends StatelessWidget {
  final Habit habit;
  final double size;
  final double strokeWidth;

  const HabitProgressRing({
    super.key,
    required this.habit,
    this.size = 180,
    this.strokeWidth = 14,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayCount = habit.getTodayCompletionCount();
    final requiredCount = habit.remindersPerDay;
    final progress = requiredCount == 0
        ? 0.0
        : (todayCount / requiredCount).clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _HabitProgressRingPainter(
              progress: progress,
              color: habit.color,
              backgroundColor: theme.colorScheme.onSurface.withAlpha((0.1 * 255).round()),
              strokeWidth: strokeWidth,
            ),
          ),
          Container(
            width: size * 0.32,
            height: size * 0.32,
            decoration: BoxDecoration(
              color: habit.color.withAlpha((0.15 * 255).round()),
              shape: BoxShape.circle,
            ),
            child: Icon(
              habit.icon,
              color: habit.color,
              size: size * 0.18,
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final double strokeWidth;

  const _HabitProgressRingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final adjustedRect = rect.deflate(strokeWidth / 2);
    final startAngle = -math.pi / 2;

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Base ring provides subtle context for progress.
    canvas.drawArc(adjustedRect, startAngle, 2 * math.pi, false, backgroundPaint);
    canvas.drawArc(adjustedRect, startAngle, 2 * math.pi * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _HabitProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
