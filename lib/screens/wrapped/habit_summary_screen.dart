import 'package:flutter/material.dart';

import '../../models/habit.dart';
import '../../services/export_service.dart';
import '../../widgets/wrapped/yearly_wrapped_preview.dart';

class HabitSummaryScreen extends StatefulWidget {
  final Habit habit;
  const HabitSummaryScreen({super.key, required this.habit});

  @override
  State<HabitSummaryScreen> createState() => _HabitSummaryScreenState();
}

class _HabitSummaryScreenState extends State<HabitSummaryScreen> {
  final GlobalKey _previewKey = GlobalKey();
  Color _backdropColor = const Color(0xFF8C00FF);
  bool _darkTheme = true;

  Color get _cardColor => _darkTheme ? Colors.black : Colors.white;
  Color get _textColor => _darkTheme ? Colors.white : Colors.black;

  Future<void> _exportImage() async {
    try {
      await ExportService.exportAndShare(
        _previewKey,
        width: 1080,
        height: 1080,
        filename: 'streakly_habit_${widget.habit.id}_summary.png',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habit = widget.habit;

    return Scaffold(
      appBar: AppBar(
        title: Text('${habit.name} – Summary'),
        backgroundColor: _backdropColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            onPressed: _openShareOptionsAndExport,
          ),
        ],
      ),
      backgroundColor: _backdropColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: RepaintBoundary(
            key: _previewKey,
            child: Stack(
              children: [
                Container(
                  color: _backdropColor,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Center(
                    child: YearlyWrappedPreview(
                      exportKey: null,
                      habits: [habit],
                      backgroundColor: _cardColor,
                      textColor: _textColor,
                    ),
                  ),
                ),
                Positioned(
                  right: 18,
                  bottom: 16,
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: 'Habit',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.35),
                          ),
                        ),
                        TextSpan(
                          text: 'Sensai',
                          style: TextStyle(
                            color: theme.colorScheme.primary
                                .withOpacity(0.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.ios_share),
              label: const Text('Share Summary'),
              onPressed: _openShareOptionsAndExport,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openShareOptionsAndExport() async {
    final result = await showModalBottomSheet<_ShareOptions>(
      context: context,
      builder: (ctx) {
        return _ShareOptionsSheet(
          initialDarkTheme: _darkTheme,
          initialBackdrop: _backdropColor,
        );
      },
    );

    if (result != null) {
      setState(() {
        _darkTheme = result.darkTheme;
        _backdropColor = result.backdropColor;
      });
      await _exportImage();
    }
  }
}

class _ShareOptions {
  final bool darkTheme;
  final Color backdropColor;
  _ShareOptions({required this.darkTheme, required this.backdropColor});
}

class _ShareOptionsSheet extends StatefulWidget {
  final bool initialDarkTheme;
  final Color initialBackdrop;
  const _ShareOptionsSheet({
    super.key,
    required this.initialDarkTheme,
    required this.initialBackdrop,
  });

  @override
  State<_ShareOptionsSheet> createState() => _ShareOptionsSheetState();
}

class _ShareOptionsSheetState extends State<_ShareOptionsSheet> {
  late bool _darkTheme;
  late Color _backdrop;

  final List<Color> _palette = const [
    Color(0xFF8C00FF),
    Color(0xFF0EBE7F),
    Color(0xFF00A2FF),
    Color(0xFFFF7A00),
    Color(0xFFFF4D67),
    Color(0xFF2E2E2E),
    Color(0xFF111111),
    Color(0xFFFFFFFF),
  ];

  @override
  void initState() {
    super.initState();
    _darkTheme = widget.initialDarkTheme;
    _backdrop = widget.initialBackdrop;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Share Options',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Background',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _palette.map((c) {
                final selected = c.value == _backdrop.value;
                return GestureDetector(
                  onTap: () => setState(() => _backdrop = c),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: selected
                              ? Colors.white
                              : Colors.black12,
                          width: 2),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Theme',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Light'),
                  selected: !_darkTheme,
                  onSelected: (_) => setState(() => _darkTheme = false),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Dark'),
                  selected: _darkTheme,
                  onSelected: (_) => setState(() => _darkTheme = true),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                      context,
                      _ShareOptions(
                          darkTheme: _darkTheme, backdropColor: _backdrop));
                },
                child: const Text('Apply & Export'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
