import 'package:flutter/material.dart';
import '../../models/habit.dart';
import 'heatmap_painter.dart';

class YearlyWrappedPreview extends StatelessWidget {
  final List<Habit> habits;
  final Color backgroundColor;
  final GlobalKey? exportKey;
  final double? width;
  final Color textColor;

  const YearlyWrappedPreview(
      {Key? key,
      required this.habits,
      required this.backgroundColor,
      this.exportKey,
      this.width,
      this.textColor = Colors.white})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget buildCard(double cardWidth) {
      final card = Center(
        child: Container(
          width: cardWidth,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Heatmaps
              Column(
                children: habits.map((h) {
                  return Padding(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon and name above the heatmap
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                  color: h.color, shape: BoxShape.circle),
                              child: Icon(
                                h.icon,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(h.name,
                                  style: TextStyle(
                                      color: textColor, fontSize: 14)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        // Heatmap below the name — slightly reduced height to compact rows
                        SizedBox(
                          height: 84,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: HeatmapPainter(
                                completedDates: h.completedDates,
                                createdAt: h.createdAt,
                                color: h.color),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );

      if (exportKey != null) {
        return RepaintBoundary(key: exportKey, child: card);
      }
      return card;
    }

    if (width != null) {
      return buildCard(width!);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth * 0.95;
        return buildCard(cardWidth);
      },
    );
  }
}
