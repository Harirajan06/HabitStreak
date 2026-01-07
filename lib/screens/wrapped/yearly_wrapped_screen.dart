import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../models/habit.dart';
import '../../widgets/wrapped/yearly_wrapped_preview.dart';
import '../../services/export_service.dart';

class YearlyWrappedScreen extends StatefulWidget {
  static const routeName = '/wrapped/yearly';
  final List<String>? initialSelectedIds;
  const YearlyWrappedScreen({Key? key, this.initialSelectedIds}) : super(key: key);

  @override
  State<YearlyWrappedScreen> createState() => _YearlyWrappedScreenState();
}

class _YearlyWrappedScreenState extends State<YearlyWrappedScreen> {
  final GlobalKey previewKey = GlobalKey();
  List<String> selectedHabitIds = [];
  Color _backdropColor = const Color(0xFF8C00FF);
  bool _darkTheme = true;

  @override
  void initState() {
    super.initState();
    // Default: select up to 3 active habits
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<HabitProvider>(context, listen: false);
      final defaults = widget.initialSelectedIds ??
          provider.activeHabits.take(3).map((h) => h.id).toList();
      setState(() => selectedHabitIds = defaults);
    });
  }

  void _openSelectHabits() async {
    // TODO: implement modal; for now simple multi-select using showModalBottomSheet
    final provider = Provider.of<HabitProvider>(context, listen: false);
    final habits = provider.activeHabits;

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: _SelectHabitsSheet(
            habits: habits,
            initialSelected: selectedHabitIds,
          ),
        );
      },
    );

    if (result != null) {
      setState(() => selectedHabitIds = result);
    }
  }

  Future<void> _exportImage() async {
    try {
      await ExportService.exportAndShare(previewKey,
          width: 1080, height: 1080, filename: 'streakly_wrapped_2025.png');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<HabitProvider>(context);
    final selectedHabits = selectedHabitIds
      .map((id) => provider.getHabitById(id))
      .whereType<Habit>()
      .toList();
    final cardColor = _darkTheme ? Colors.black : Colors.white;
    final textColor = _darkTheme ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Wrapped – ${2025}'),
        backgroundColor: _backdropColor,
      ),
      backgroundColor: _backdropColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: RepaintBoundary(
                  key: previewKey,
                  child: Stack(
                    children: [
                      Container(
                        color: _backdropColor,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Center(
                          child: YearlyWrappedPreview(
                            exportKey: null,
                            habits: selectedHabits,
                            backgroundColor: cardColor,
                            textColor: textColor,
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
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openShareOptionsAndExport,
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Export'),
                ),
              ),
            ),
          ],
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
    Key? key,
    required this.initialDarkTheme,
    required this.initialBackdrop,
  }) : super(key: key);

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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Background', style: TextStyle(fontWeight: FontWeight.w600)),
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
                        color: selected ? Colors.white : Colors.black12,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Theme', style: TextStyle(fontWeight: FontWeight.w600)),
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
                    _ShareOptions(darkTheme: _darkTheme, backdropColor: _backdrop),
                  );
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

class _SelectHabitsSheet extends StatefulWidget {
  final List habits;
  final List<String> initialSelected;
  const _SelectHabitsSheet(
      {Key? key, required this.habits, required this.initialSelected})
      : super(key: key);

  @override
  State<_SelectHabitsSheet> createState() => _SelectHabitsSheetState();
}

class _SelectHabitsSheetState extends State<_SelectHabitsSheet> {
  late List<String> selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initialSelected.toList();
  }

  @override
  Widget build(BuildContext context) {
    // Map selected ids to habit objects
    final selectedHabits = selected
        .map((id) => widget.habits.firstWhere((h) => h.id == id,
            orElse: () => null))
        .where((h) => h != null)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Habits'),
      ),
      body: Column(
        children: [
          // Selected chips with reorder (horizontal ReorderableListView)
          if (selected.isNotEmpty)
            SizedBox(
              height: 120,
              child: ReorderableListView(
                scrollDirection: Axis.horizontal,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = selected.removeAt(oldIndex);
                    selected.insert(newIndex, item);
                  });
                },
                children: selected.map((id) {
                  final habit = widget.habits
                      .firstWhere((h) => h.id == id, orElse: () => null);
                  final label = habit != null ? habit.name : id;
                  return Container(
                    key: ValueKey('sel_$id'),
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(label, style: const TextStyle(color: Colors.white)),
                        const SizedBox(width: 8),
                        const Icon(Icons.drag_handle, color: Colors.white70),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: widget.habits.length,
              itemBuilder: (context, index) {
                final habit = widget.habits[index];
                final id = habit.id as String;
                final name = habit.name as String;
                return CheckboxListTile(
                  value: selected.contains(id),
                  title: Text(name),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        if (selected.length < 5) {
                          selected.add(id);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Maximum 5 habits can be selected')));
                        }
                      } else {
                        selected.remove(id);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(selected),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
