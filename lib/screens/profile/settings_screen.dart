import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../services/export_import_service.dart';
import '../../providers/habit_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/modern_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
              ),
              child: Icon(Icons.tune, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Text(
              'Settings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildSectionCard(
            context,
            title: 'Notifications',
            icon: Icons.notifications_active_outlined,
            accent: Colors.orangeAccent,
            children: [
              _buildToggleTile(
                context,
                title: 'Push Notifications',
                subtitle: 'Receive habit reminders',
                icon: Icons.notifications,
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
              _buildToggleTile(
                context,
                title: 'Sound',
                subtitle: 'Play notification sounds',
                icon: Icons.volume_up,
                value: _soundEnabled,
                enabled: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _soundEnabled = value;
                  });
                },
              ),
              _buildToggleTile(
                context,
                title: 'Vibration',
                subtitle: 'Vibrate for notifications',
                icon: Icons.vibration,
                value: _vibrationEnabled,
                enabled: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _vibrationEnabled = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildSectionCard(
            context,
            title: 'General',
            icon: Icons.settings_outlined,
            accent: Color(0xFF9B5DE5),
            children: [
              _buildActionTile(
                context,
                title: 'Language',
                subtitle: _selectedLanguage,
                icon: Icons.language,
                onTap: _showLanguageDialog,
              ),
              _buildActionTile(
                context,
                title: 'Export Data',
                subtitle: 'Export your habit data',
                icon: Icons.download,
                onTap: _showExportDialog,
              ),
              _buildActionTile(
                context,
                title: 'Import Data',
                subtitle: 'Import app data from JSON file',
                icon: Icons.upload_file,
                onTap: _showImportDialog,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildSectionCard(
            context,
            title: 'Privacy & Security',
            icon: Icons.lock_outline,
            accent: Color(0xFF9B5DE5),
            children: [
              _buildActionTile(
                context,
                title: 'PIN & Security',
                subtitle: 'Set / change / remove app PIN and manage biometrics',
                icon: Icons.lock,
                onTap: () => _showPinManagementDialog(context),
              ),
              const SizedBox(height: 6),
              _buildActionTile(
                context,
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                icon: Icons.privacy_tip_outlined,
                onTap: () {
                  // TODO: Show privacy policy
                },
              ),
              _buildActionTile(
                context,
                title: 'Terms of Service',
                subtitle: 'Read our terms of service',
                icon: Icons.description_outlined,
                onTap: () {
                  // TODO: Show terms of service
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildSectionCard(
            context,
            title: 'Account',
            icon: Icons.person_outline,
            accent: Colors.redAccent,
            children: [
              _buildActionTile(
                context,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account',
                icon: Icons.delete_forever,
                onTap: _showDeleteAccountDialog,
                isDestructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPinManagementDialog(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final hasPin = await auth.hasPin();
    if (!mounted) return;

    if (!hasPin) {
        // Offer to set PIN
        final result = await showDialog<bool>(
        context: navigator.context,
        builder: (context) {
          final controller = TextEditingController();
          final confirmController = TextEditingController();
          String? error;
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: const Text('Set PIN'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Enter new PIN'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirm PIN'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                ElevatedButton(onPressed: () async {
                  final navigator = Navigator.of(context);
                  final pin = controller.text.trim();
                  final confirm = confirmController.text.trim();
                  if (pin.isEmpty || pin.length < 4) {
                    setState(() { error = 'PIN must be at least 4 digits'; });
                    return;
                  }
                  if (pin != confirm) {
                    setState(() { error = 'PINs do not match'; });
                    return;
                  }
                  final ok = await auth.setPin(pin);
                  navigator.pop(ok);
                }, child: const Text('Set PIN')),
              ],
            );
          });
        },
      );

      if (!mounted) return;
      if (result == true) {
        messenger.showSnackBar(const SnackBar(content: Text('PIN set successfully')));
      }
      return;
    }

    // If PIN exists, offer change or remove
    if (!mounted) return;

    final action = await showModalBottomSheet<String?>(
      context: navigator.context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(leading: const Icon(Icons.edit), title: const Text('Change PIN'), onTap: () => Navigator.of(context).pop('change')),
          ListTile(leading: const Icon(Icons.delete), title: const Text('Remove PIN'), onTap: () => Navigator.of(context).pop('remove')),
        ],
      ),
    );

    if (!mounted) return;

    if (action == 'change') {
        // Change PIN: verify current then set new
        final res = await showDialog<bool>(
        context: navigator.context,
        builder: (context) {
          final current = TextEditingController();
          final next = TextEditingController();
          final confirm = TextEditingController();
          String? error;
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change PIN'),
              content: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(controller: current, keyboardType: TextInputType.number, obscureText: true, decoration: const InputDecoration(labelText: 'Current PIN')),
                  const SizedBox(height: 8),
                  TextField(controller: next, keyboardType: TextInputType.number, obscureText: true, decoration: const InputDecoration(labelText: 'New PIN')),
                  const SizedBox(height: 8),
                  TextField(controller: confirm, keyboardType: TextInputType.number, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm New PIN')),
                  if (error != null) ...[const SizedBox(height: 8), Text(error!, style: const TextStyle(color: Colors.red))],
                ]),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                ElevatedButton(onPressed: () async {
                  final navigator = Navigator.of(context);
                  final cur = current.text.trim();
                  final n = next.text.trim();
                  final c = confirm.text.trim();
                  if (cur.isEmpty) { setState(() { error = 'Enter current PIN'; }); return; }
                  if (n.length < 4) { setState(() { error = 'New PIN must be at least 4 digits'; }); return; }
                  if (n != c) { setState(() { error = 'New PINs do not match'; }); return; }
                  final okCur = await auth.verifyPin(cur);
                  if (!okCur) { setState(() { error = 'Current PIN invalid'; }); return; }
                  final ok = await auth.setPin(n);
                  navigator.pop(ok);
                }, child: const Text('Change')),
              ],
            );
          });
        },
      );

      if (!mounted) return;
      if (res == true) messenger.showSnackBar(const SnackBar(content: Text('PIN changed')));
      return;
    }

    if (action == 'remove') {
        final confirmed = await showDialog<bool>(
        context: navigator.context,
        builder: (context) {
          final controller = TextEditingController();
          String? error;
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: const Text('Remove PIN'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Enter current PIN to remove it'),
                const SizedBox(height: 8),
                TextField(controller: controller, keyboardType: TextInputType.number, obscureText: true, decoration: const InputDecoration(labelText: 'Current PIN')),
                if (error != null) ...[const SizedBox(height: 8), Text(error!, style: const TextStyle(color: Colors.red))],
              ]),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                ElevatedButton(onPressed: () async {
                  final navigator = Navigator.of(context);
                  final cur = controller.text.trim();
                  if (cur.isEmpty) { setState(() { error = 'Enter current PIN'; }); return; }
                  final ok = await auth.verifyPin(cur);
                  if (!ok) { setState(() { error = 'Invalid PIN'; }); return; }
                  final removed = await auth.removePin();
                  navigator.pop(removed);
                }, child: const Text('Remove')),
              ],
            );
          });
        },
      );

      if (!mounted) return;
      if (confirmed == true) messenger.showSnackBar(const SnackBar(content: Text('PIN removed')));
      return;
    }
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color accent,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                color: theme.colorScheme.outline.withOpacity(0.2),
                height: 1,
              ),
            children[i],
          ],
        ],
      ),
    );
  }

  Widget _buildToggleTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: theme.colorScheme.onSurface, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: enabled ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(enabled ? 0.6 : 0.3),
                  ),
                ),
              ],
            ),
          ),
          Opacity(
            opacity: enabled ? 1 : 0.5,
            child: Switch.adaptive(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeColor: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);

    final iconColor = isDestructive ? Colors.redAccent : theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isDestructive ? Colors.redAccent : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
  void _showLanguageDialog() {
    final languages = ['English', 'Spanish', 'French', 'German', 'Chinese'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((language) {
            return RadioListTile<String>(
              title: Text(language),
              value: language,
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      final habits = habitProvider.activeHabits;
      
      if (habits.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No habits to export')),
        );
        return;
      }
      
      // Create CSV content
      String csvContent = 'Habit Name,Description,Color,Frequency,Time of Day,Current Streak,Longest Streak,Completion Rate,Completed Dates\n';
      
      for (final habit in habits) {
        final completedDatesStr = habit.completedDates.map((d) => d.toIso8601String()).join(';');
        csvContent += '"${habit.name}","${habit.description}","${habit.color.value}","${habit.frequency.name}","${habit.timeOfDay.name}","${habit.currentStreak}","${habit.longestStreak}","${(habit.completionRate * 100).toStringAsFixed(1)}%","$completedDatesStr"\n';
      }
      
      final messenger = ScaffoldMessenger.of(context);

      // Get downloads directory
      final directory = await getDownloadsDirectory();
      if (directory != null) {
        final file = File('${directory.path}/streakly_habits_export_${DateTime.now().millisecondsSinceEpoch}.csv');
        await file.writeAsString(csvContent);
        
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text('Data exported to ${file.path}')),
        );
      } else {
        throw Exception('Could not access downloads folder');
      }
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Export Data'),
        content: const Text('Export your habit data as a CSV file?'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: ModernButton(
                    text: 'Cancel',
                    type: ModernButtonType.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ModernButton(
                    text: 'Export',
                    type: ModernButtonType.primary,
                    icon: Icons.download,
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      navigator.pop();
                      await _exportData();
                      final file = await ExportImportService.instance.exportToFile();
                      if (!mounted) return;
                      messenger.showSnackBar(SnackBar(content: Text('JSON export saved to ${file.path}')));
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showImportDialog() async {
    try {
      final messenger = ScaffoldMessenger.of(context);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;
      final path = result.files.first.path;
      if (path == null) return;

      final file = File(path);
      final content = await file.readAsString();

      final res = await ExportImportService.instance.importFromJsonString(content, overwrite: false);
      if (!mounted) return;
      if (res['success'] == true) {
        // Refresh habits data after successful import
        await Provider.of<HabitProvider>(context, listen: false).loadHabits();
        messenger.showSnackBar(SnackBar(content: Text('Import successful. Backup: ${res['backup']}')));
      } else {
        messenger.showSnackBar(SnackBar(content: Text('Import failed: ${res['error']} (backup: ${res['backup']})'), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red));
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: ModernButton(
                    text: 'Cancel',
                    type: ModernButtonType.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ModernButton(
                    text: 'Delete',
                    type: ModernButtonType.destructive,
                    icon: Icons.delete_forever,
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Account deletion is not implemented in this demo.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
