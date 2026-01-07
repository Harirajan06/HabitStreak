import 'package:flutter/material.dart';

class HeatmapPainter extends CustomPainter {
  final List<DateTime> completedDates;
  final DateTime createdAt;
  final Color color;

  HeatmapPainter(
      {required this.completedDates, required this.createdAt, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw a GitHub-style 7xN weeks heatmap horizontally.
    // Compute week grid for the current year and fit it into `size`.
    final paintFilled = Paint()..color = color;
    final paintEmpty = Paint()..color = color.withOpacity(0.30);

    final year = DateTime.now().year;
    final startOfYear = DateTime(year, 1, 1);
    // Align start to previous Sunday so columns represent full weeks
    int startOffset = startOfYear.weekday % 7; // Sunday==0
    final gridStart = startOfYear.subtract(Duration(days: startOffset));

    final endOfYear = DateTime(year, 12, 31);
    final totalDays = endOfYear.difference(gridStart).inDays + 1;
    final weekCount = (totalDays / 7).ceil();

    // Spacing and dot size calculated to fit available size
    final maxSpacing = 2.5;
    final maxDot = 14.0;
    final horizontalAvailable = size.width;
    final verticalAvailable = size.height;

    final computedDot = (horizontalAvailable - (weekCount - 1) * maxSpacing) / weekCount;
    final computedDotVert = (verticalAvailable - (7 - 1) * maxSpacing) / 7;
    final dotSize = computedDot.clamp(4.0, maxDot).clamp(0.0, computedDotVert);
    final spacing = maxSpacing;

    // Build a set of completion keys for quick lookup
    final completedSet = <String>{};
    for (final d in completedDates) {
      completedSet.add('${d.year}-${d.month}-${d.day}');
    }

    // Draw month labels at the top of the painter and adjust grid start
    final textStyle = TextStyle(color: Colors.white70, fontSize: 9);
    final tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = const TextSpan(text: 'M', style: TextStyle(fontSize: 10));
    tp.layout();
    final topOffset = tp.height + 4.0;

    for (int m = 1; m <= 12; m++) {
      final firstOfMonth = DateTime(year, m, 1);
      final dayIndex = firstOfMonth.difference(gridStart).inDays;
      final weekIndex = (dayIndex / 7).floor();
      final dx = weekIndex * (dotSize + spacing);
      tp.text = TextSpan(text: _monthShort(m), style: textStyle);
      tp.layout();
      tp.paint(canvas, Offset(dx, 0));
    }

    // Render dots
    for (int week = 0; week < weekCount; week++) {
      for (int weekday = 0; weekday < 7; weekday++) {
        final dayIndex = week * 7 + weekday;
        final date = gridStart.add(Duration(days: dayIndex));
        final dx = week * (dotSize + spacing);
        final dy = weekday * (dotSize + spacing) + topOffset;

        final rect = Rect.fromLTWH(dx, dy, dotSize, dotSize);
        final rrect = RRect.fromRectAndRadius(rect, Radius.circular(dotSize * 0.12));

        if (date.isBefore(createdAt) || date.isAfter(endOfYear)) {
          // future or pre-created dates at 30% opacity of habit color
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(dotSize / 4)),
            paintEmpty,
          );
          continue;
        }

        final key = '${date.year}-${date.month}-${date.day}';
        final filled = completedSet.contains(key);

        if (filled) {
          // glow
          final glowPaint = Paint()
            ..color = color.withOpacity(0.28)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, dotSize / 1.2);
          canvas.drawRRect(rrect.inflate(dotSize * 0.12), glowPaint);

          // filled square
          canvas.drawRRect(rrect, paintFilled);
        } else {
          // empty square using habit color at 30% opacity, no border
          canvas.drawRRect(rrect, paintEmpty);
        }
      }
    }
  }

  String _monthShort(int m) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[m - 1];
  }

  @override
  bool shouldRepaint(covariant HeatmapPainter oldDelegate) {
    return oldDelegate.completedDates != completedDates ||
        oldDelegate.createdAt != createdAt ||
        oldDelegate.color != color;
  }
}
