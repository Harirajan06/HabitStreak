// lib/screens/habits/add_habit_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/habit_provider.dart';
import '../../models/habit.dart';
import '../../widgets/modern_button.dart';
import '../../widgets/review_dialog.dart';
// NotificationService and timezone removed — reminders are stored but not scheduled
import '../../providers/auth_provider.dart'; // Import AuthProvider
import '../../services/notification_service.dart';

class AddHabitScreen extends StatefulWidget {
  final Habit? habitToEdit;

  const AddHabitScreen({super.key, this.habitToEdit});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _uuid = const Uuid();

  IconData _selectedIcon = Icons.star;
  Color _selectedColor = Colors.blue;
  HabitType _selectedHabitType = HabitType.build;
  List<TimeOfDay> _reminderTimes = [];
  int _remindersPerDay = 1;

  final List<IconData> _availableIcons = [
    Icons.fitness_center,
    Icons.directions_run,
    Icons.directions_walk,
    Icons.pool,
    Icons.sports_gymnastics,
    Icons.sports_tennis,
    Icons.sports_basketball,
    Icons.sports_soccer,
    Icons.self_improvement,
    Icons.spa,
    Icons.local_drink,
    Icons.restaurant,
    Icons.local_cafe,
    Icons.breakfast_dining,
    Icons.lunch_dining,
    Icons.dinner_dining,
    Icons.local_pizza,
    Icons.cake,
    Icons.book,
    Icons.school,
    Icons.work,
    Icons.computer,
    Icons.code,
    Icons.science,
    Icons.calculate,
    Icons.language,
    Icons.psychology,
    Icons.brush,
    Icons.music_note,
    Icons.camera_alt,
    Icons.palette,
    Icons.draw,
    Icons.piano,
    Icons.mic,
    Icons.theater_comedy,
    Icons.bed,
    Icons.alarm,
    Icons.shower,
    Icons.cleaning_services,
    Icons.local_laundry_service,
    Icons.shopping_cart,
    Icons.car_repair,
    Icons.home_repair_service,
    Icons.favorite,
    Icons.favorite_border,
    Icons.mood,
    Icons.sentiment_very_satisfied,
    Icons.local_florist,
    Icons.nature,
    Icons.wb_sunny,
    Icons.nights_stay,
    Icons.family_restroom,
    Icons.people,
    Icons.phone,
    Icons.video_call,
    Icons.chat,
    Icons.volunteer_activism,
    Icons.savings,
    Icons.account_balance_wallet,
    Icons.trending_up,
    Icons.star,
    Icons.flag,
    Icons.lightbulb,
    Icons.emoji_events,
    Icons.workspace_premium,
  ];

  final List<Color> _availableColors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.orange,
    Color(0xFF9B5DE5),
    Colors.pink,
    Colors.teal,
    Colors.indigo,
    Colors.cyan,
    Colors.amber,
    Colors.lime,
    Colors.purple,
    Colors.blueGrey,
    Colors.brown,
    Colors.grey,
    const Color(0xFF6B46C1),
    const Color(0xFF10B981),
    const Color(0xFFF59E0B),
    const Color(0xFFEF4444),
    const Color(0xFF8B5CF6),
    const Color(0xFF06B6D4),
    const Color(0xFFEC4899),
    const Color(0xFF84CC16),
    const Color(0xFFF97316),
    const Color(0xFF3B82F6),
    const Color(0xFF14B8A6),
    const Color(0xFFA855F7),
    const Color(0xFFE11D48),
    const Color(0xFF22C55E),
    const Color(0xFF64748B),
    const Color(0xFF78716C),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.habitToEdit != null) {
      _loadHabitData();
    }
  }

  void _loadHabitData() {
    final habit = widget.habitToEdit!;
    _nameController.text = habit.name;
    _descriptionController.text = habit.description;
    _selectedIcon = habit.icon;
    _selectedColor = habit.color;
    _selectedHabitType = habit.habitType;
    _reminderTimes = List.from(habit.reminderTimes);
    _remindersPerDay = habit.remindersPerDay;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;

    final habitProvider = Provider.of<HabitProvider>(context, listen: false);
    final authProvider =
        Provider.of<AuthProvider>(context, listen: false); // Get AuthProvider
    final isEditing = widget.habitToEdit != null;
    final habitId = widget.habitToEdit?.id ?? _uuid.v4();
    final desiredName = _nameController.text.trim();

    if (habitProvider.isHabitNameTaken(desiredName,
        excludeId: isEditing ? habitId : null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Habit name already exists. Choose a unique name.')),
      );
      return;
    }
    // Ensure stored reminders list size matches remindersPerDay setting
    List<TimeOfDay> validReminders = [];
    if (_reminderTimes.length > _remindersPerDay) {
      validReminders = _reminderTimes.sublist(0, _remindersPerDay);
    } else {
      validReminders = List.from(_reminderTimes);
    }

    final habit = Habit(
      id: habitId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      icon: _selectedIcon,
      color: _selectedColor,
      frequency: HabitFrequency.daily,
      timeOfDay: HabitTimeOfDay.morning,
      habitType: _selectedHabitType,
      createdAt: widget.habitToEdit?.createdAt ?? DateTime.now(),
      completedDates: widget.habitToEdit?.completedDates ?? [],
      reminderTimes: validReminders,
      remindersPerDay: _remindersPerDay,
      dailyCompletions: widget.habitToEdit?.dailyCompletions ?? {},
    );

    // Re-evaluate completion status for today
    // If we increased remindersPerDay, a previously "completed" habit might now be incomplete
    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final currentCount = habit.dailyCompletions[todayKey] ?? 0;

    if (currentCount < habit.remindersPerDay) {
      habit.completedDates.removeWhere((date) =>
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day);
    } else {
      // Should already be there, but just in case logic flipped the other way (decreased reminders)
      bool exists = habit.completedDates.any((date) =>
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day);
      if (!exists) {
        habit.completedDates.add(today);
      }
    }

    final isPremium =
        authProvider.currentUser?.premium ?? false; // Check premium status

    if (isEditing) {
      await habitProvider.updateHabit(habit.id, habit);
      // Reschedule or cancel habit reminder after update
      try {
        if (habit.reminderTimes.isNotEmpty) {
          await NotificationService().scheduleReminderForHabit(habit);
        } else {
          await NotificationService().cancelReminder(habit.id.hashCode);
        }
      } catch (e) {
        debugPrint('⚠️ Failed to (re)schedule notification: $e');
      }
    } else {
      await habitProvider.addHabit(habit,
          isPremium: isPremium); // Pass premium status
      // Schedule reminder for newly created habit (if set)
      try {
        if (habit.reminderTimes.isNotEmpty) {
          await NotificationService().scheduleReminderForHabit(habit);
        }
      } catch (e) {
        debugPrint('⚠️ Failed to schedule notification for new habit: $e');
      }
    }

    await habitProvider.loadHabits();

    if (!isEditing && habitProvider.activeHabits.length == 2) {
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        _showReviewDialog(context);
      }
    } else {
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    }
  }

  void _showReviewDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ReviewDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.habitToEdit != null ? 'Edit Habit' : 'Add New Habit'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 55),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfo(),
              const SizedBox(height: 24),
              _buildIconSelection(),
              const SizedBox(height: 24),
              _buildColorSelection(),
              const SizedBox(height: 24),
              _buildHabitTypeSelection(),
              const SizedBox(height: 24),
              _buildRemindersPerDaySection(),
              const SizedBox(height: 24),
              _buildReminderSection(),
              const SizedBox(height: 48),
              ModernButton(
                text: widget.habitToEdit != null
                    ? 'Update Habit'
                    : 'Create Habit',
                type: ModernButtonType.primary,
                size: ModernButtonSize.large,
                icon: widget.habitToEdit != null ? Icons.update : Icons.add,
                fullWidth: true,
                onPressed: _saveHabit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _buildTextFieldCard(
          controller: _nameController,
          label: 'Habit Name',
          hint: 'e.g., Drink Water, Exercise, Read',
          maxLines: 1,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a habit name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextFieldCard(
          controller: _descriptionController,
          label: 'Description',
          hint: 'What does this habit involve?',
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a description';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildIconSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose an Icon',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withAlpha((0.2 * 255).round())),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _availableIcons.map((icon) {
                final isSelected = icon == _selectedIcon;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIcon = icon;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha((0.18 * 255).round())
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white.withAlpha((0.06 * 255).round()),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withAlpha((0.35 * 255).round()),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha((0.25 * 255).round())
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        size: 24,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withAlpha((0.7 * 255).round()),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose a Color',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withAlpha((0.2 * 255).round())),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _availableColors.map((color) {
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha((0.2 * 255).round())
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white.withAlpha((0.06 * 255).round()),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHabitTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Habit Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
          ),
          child: Row(
            children: HabitType.values.map((habitType) {
              final isSelected = habitType == _selectedHabitType;
              final isBuild = habitType == HabitType.build;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedHabitType = habitType;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isBuild
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2))
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? (isBuild ? Colors.green : Colors.red)
                              : Colors.white.withOpacity(0.06),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: (isBuild ? Colors.green : Colors.red)
                                      .withOpacity(0.25),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            isBuild ? Icons.trending_up : Icons.trending_down,
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.7),
                            size: 24,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getHabitTypeLabel(habitType),
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.7),
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isBuild
                                ? 'Good habits to build'
                                : 'Bad habits to break',
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.8)
                                          : Colors.white.withOpacity(0.5),
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminders',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        if (_remindersPerDay == 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'No reminders enabled.',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          )
        else
          ...List.generate(_remindersPerDay, (index) {
            final time =
                (index < _reminderTimes.length) ? _reminderTimes[index] : null;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ListTile(
                tileColor: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                title: Text(time != null
                    ? 'Reminder ${index + 1}: ${time.format(context)}'
                    : 'Set Reminder ${index + 1}'),
                subtitle: Text(time == null ? 'Tap to set time' : ''),
                leading: const Icon(Icons.notifications),
                trailing: time != null
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() {
                            _reminderTimes.removeAt(index);
                          });
                        },
                      )
                    : null,
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: time ?? TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      if (index < _reminderTimes.length) {
                        _reminderTimes[index] = picked;
                      } else {
                        _reminderTimes.add(picked);
                      }
                      _reminderTimes.sort((a, b) => (a.hour * 60 + a.minute)
                          .compareTo(b.hour * 60 + b.minute));
                    });
                  }
                },
              ),
            );
          }),
      ],
    );
  }

  String _getHabitTypeLabel(HabitType habitType) {
    switch (habitType) {
      case HabitType.build:
        return 'Build';
      case HabitType.breakHabit:
        return 'Break';
    }
  }

  Widget _buildRemindersPerDaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminders Per Day',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Frequency',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Set habit completions per day',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _remindersPerDay > 1
                        ? () {
                            setState(() {
                              _remindersPerDay--;
                              // No need to clear _reminderTimes immediately to be non-destructive
                            });
                          }
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$_remindersPerDay',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _remindersPerDay < 10
                        ? () {
                            setState(() {
                              _remindersPerDay++;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextFieldCard({
    required TextEditingController controller,
    required String label,
    required String hint,
    required int maxLines,
    required String? Function(String?) validator,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outline
                .withAlpha((0.2 * 255).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white.withAlpha((0.85 * 255).round()),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withAlpha((0.2 * 255).round())),
            ),
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              validator: validator,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withAlpha((0.5 * 255).round()),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
