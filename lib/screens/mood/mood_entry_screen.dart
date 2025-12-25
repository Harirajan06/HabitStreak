import 'package:flutter/material.dart';

class MoodEntryScreen extends StatefulWidget {
  final DateTime selectedDate;
  final String? initialMood;
  final List<String>? initialTags;
  final String? initialNotes;

  const MoodEntryScreen({
    super.key,
    required this.selectedDate,
    this.initialMood,
    this.initialTags,
    this.initialNotes,
  });

  @override
  State<MoodEntryScreen> createState() => _MoodEntryScreenState();
}

class _MoodEntryScreenState extends State<MoodEntryScreen> {
  String? _selectedMood;
  final Set<String> _selectedTags = {};
  final TextEditingController _notesController = TextEditingController();

  final List<Map<String, dynamic>> _moods = [
    {'emoji': '💔', 'label': 'Broken', 'color': Color(0xFF8B0000), 'score': 1},
    {'emoji': '😡', 'label': 'Angry', 'color': Color(0xFFFF6B00), 'score': 2},
    {'emoji': '😢', 'label': 'Sad', 'color': Color(0xFFFFB800), 'score': 3},
    {'emoji': '😰', 'label': 'Anxious', 'color': Color(0xFF6B4423), 'score': 4},
    {
      'emoji': '😣',
      'label': 'Stressed',
      'color': Color(0xFF5C4033),
      'score': 5
    },
    {'emoji': '😴', 'label': 'Tired', 'color': Color(0xFF4A5568), 'score': 6},
    {'emoji': '😐', 'label': 'Neutral', 'color': Color(0xFF718096), 'score': 7},
    {'emoji': '💕', 'label': 'Close', 'color': Color(0xFFFF69B4), 'score': 8},
    {'emoji': '🤗', 'label': 'Caring', 'color': Color(0xFFFFD700), 'score': 9},
    {'emoji': '🥰', 'label': 'Love', 'color': Color(0xFFFF1493), 'score': 10},
    {
      'emoji': '⚡',
      'label': 'Energetic',
      'color': Color(0xFF8B7500),
      'score': 11
    },
    {
      'emoji': '💪',
      'label': 'Motivated',
      'color': Color(0xFF4169E1),
      'score': 12
    },
    {
      'emoji': '🤩',
      'label': 'Excited',
      'color': Color(0xFF7CFC00),
      'score': 13
    },
    {
      'emoji': '😌',
      'label': 'Relaxed',
      'color': Color(0xFF20B2AA),
      'score': 14
    },
    {'emoji': '😊', 'label': 'Happy', 'color': Color(0xFFFFD700), 'score': 15},
    {
      'emoji': '😇',
      'label': 'Pleasant',
      'color': Color(0xFF87CEEB),
      'score': 16
    },
  ];

  final Map<String, List<String>> _moodTags = {
    'Broken': [
      'heartbroken',
      'loss',
      'emotional pain',
      'disappointment',
      'low phase'
    ],
    'Angry': ['frustration', 'irritation', 'rage', 'conflict', 'tension'],
    'Sad': ['low mood', 'unhappiness', 'emotional', 'lonely', 'down'],
    'Anxious': ['worry', 'nervous', 'overthinking', 'fear', 'uneasy'],
    'Stressed': [
      'pressure',
      'overwhelmed',
      'burnout',
      'mental load',
      'exhaustion'
    ],
    'Tired': ['fatigue', 'sleepy', 'drained', 'low energy', 'exhausted'],
    'Neutral': ['balanced', 'okay', 'steady', 'normal', 'calm state'],
    'Close': ['connected', 'bonded', 'trust', 'intimacy', 'togetherness'],
    'Caring': ['kindness', 'support', 'empathy', 'compassion', 'warmth'],
    'Love': ['affection', 'joy', 'attachment', 'happiness', 'emotional warmth'],
    'Energetic': ['active', 'lively', 'charged', 'productive', 'high energy'],
    'Motivated': [
      'driven',
      'focused',
      'determined',
      'goal-oriented',
      'disciplined'
    ],
    'Excited': [
      'thrilled',
      'enthusiastic',
      'anticipation',
      'celebration',
      'joyful energy'
    ],
    'Relaxed': ['peaceful', 'stress-free', 'calm', 'mindful', 'rested'],
    'Happy': ['joy', 'cheerful', 'positive', 'smiling', 'content'],
    'Pleasant': [
      'comfortable',
      'satisfied',
      'gentle joy',
      'positive mood',
      'ease'
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.initialMood ?? 'Pleasant'; // Use initial if provided
    if (widget.initialTags != null) {
      _selectedTags.addAll(widget.initialTags!);
    }
    if (widget.initialNotes != null) {
      _notesController.text = widget.initialNotes!;
    }

    _notesController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'How was your day?',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      '${widget.selectedDate.day.toString().padLeft(2, '0')}/${widget.selectedDate.month.toString().padLeft(2, '0')}/${widget.selectedDate.year}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildMoodGrid(theme),
                  const SizedBox(height: 32),
                  _buildTagsSection(theme),
                  const SizedBox(height: 24),
                  _buildNotesSection(theme),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _buildSaveButton(theme),
        ],
      ),
    );
  }

  Widget _buildMoodGrid(ThemeData theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8, // Adjusted to prevent overflow
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _moods.length,
      itemBuilder: (context, index) {
        final mood = _moods[index];
        final isSelected = _selectedMood == mood['label'];

        return GestureDetector(
          onTap: () {
            setState(() {
              if (_selectedMood != mood['label']) {
                _selectedMood = mood['label'] as String;
                _selectedTags.clear(); // Clear tags when switching mood
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? (mood['color'] as Color).withOpacity(0.3)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(
                      color: mood['color'] as Color,
                      width: 2,
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10), // Reduced padding
                  decoration: BoxDecoration(
                    color: (mood['color'] as Color).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    mood['emoji'] as String,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(height: 4), // Reduced spacing
                Text(
                  mood['label'] as String,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTagsSection(ThemeData theme) {
    // Get tags for selected mood or empty list if none selected
    final currentTags =
        _selectedMood != null ? (_moodTags[_selectedMood] ?? []) : <String>[];

    // Correcting the last tag for Pleasant to 'ease' from 'easesee' in case I made a typo,
    // but code above uses the map.
    // Wait, the map I added in Step 1 has 'easesee' (maybe typo in prompt).
    // I shall fix it to 'ease' in the map definition if I could, but here I just use the map.

    if (currentTags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What was it about?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: currentTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedTags.remove(tag);
                  } else {
                    _selectedTags.add(tag);
                  }
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF9B5DE5).withOpacity(0.2)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? Border.all(color: const Color(0xFF9B5DE5), width: 1.5)
                      : Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                ),
                child: Text(
                  tag,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? const Color(0xFF9B5DE5)
                        : theme.colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (required)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 6,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Write about your day...',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _selectedMood != null && _notesController.text.isNotEmpty
                ? () {
                    // Find the selected mood emoji
                    final selectedMoodData = _moods.firstWhere(
                      (m) => m['label'] == _selectedMood,
                    );

                    // Return mood data to parent screen
                    Navigator.pop(context, {
                      'emoji': selectedMoodData['emoji'],
                      'label': _selectedMood,
                      'tags': _selectedTags.toList(),
                      'notes': _notesController.text,
                      'score': selectedMoodData['score'],
                    });
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B5DE5),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF9B5DE5).withOpacity(0.3),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Save',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
