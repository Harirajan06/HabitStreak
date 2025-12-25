import 'package:flutter/material.dart';

class MoodDetailsBottomSheet extends StatelessWidget {
  final DateTime date;
  final String moodEmoji;
  final String moodLabel;
  final List<String> tags;
  final VoidCallback? onEdit;
  final String notes;

  const MoodDetailsBottomSheet({
    super.key,
    required this.date,
    required this.moodEmoji,
    required this.moodLabel,
    required this.tags,
    required this.notes,
    this.onEdit,
  });

  static void show(
    BuildContext context, {
    required DateTime date,
    required String moodEmoji,
    required String moodLabel,
    required List<String> tags,
    required String notes,
    VoidCallback? onEdit,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MoodDetailsBottomSheet(
        date: date,
        moodEmoji: moodEmoji,
        moodLabel: moodLabel,
        tags: tags,
        notes: notes,
        onEdit: onEdit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme, monthNames),
                  const SizedBox(height: 32),
                  _buildFeelingsSection(theme),
                  const SizedBox(height: 32),
                  _buildNotesSection(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, List<String> monthNames) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${monthNames[date.month - 1]} ${date.day}',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Row(
          children: [
            if (onEdit != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                moodEmoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeelingsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I was feeling',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Text(
                tag,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Mood colors mapping
  static const Map<String, Color> _moodColors = {
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

  Widget _buildNotesSection(ThemeData theme) {
    // Determine color based on mood label
    final moodColor = _moodColors[moodLabel] ?? const Color(0xFF9B5DE5);

    // Split notes into entries if there are multiple (for demo purposes)
    // In real implementation, you'd have a list of note entries
    final noteEntries = [
      {
        'title': moodLabel.toUpperCase(),
        'content': notes,
        'color': moodColor, // Use dynamic mood color
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What Happened', // Fixed typo
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 12),
        ...noteEntries.map((entry) => _buildNoteCard(
              theme,
              entry['title'] as String,
              entry['content'] as String,
              entry['color']
                  as Color, // Pass base color, opacity handled in _buildNoteCard
            )),
      ],
    );
  }

  Widget _buildNoteCard(
      ThemeData theme, String title, String content, Color bgColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_forward,
              color: theme.colorScheme.onSurface,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
