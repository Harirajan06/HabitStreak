import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart'; // This is still needed for sharing
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/theme_provider.dart'; // Import ThemeProvider
import '../../models/habit.dart';
import '../../services/export_import_service.dart';
import '../../widgets/modern_button.dart';
import '../main/main_navigation.dart';
import '../auth/splash_screen.dart';
import 'analysis_screen.dart';
import '../subscription/subscription_plans_screen.dart';
import '../../widgets/hero_stats_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            theme.colorScheme.surface.withAlpha((0.95 * 255).round()),
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(
                Icons.workspace_premium,
                color: Color(0xFFFFD700), // Gold color
                size: 28,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionPlansScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 100, // Added more bottom padding
        ),
        child: Column(
          children: [
            _buildHeroStatsCard(context),
            const SizedBox(height: 20),
            _buildMenuSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStatsCard(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        // Calculate current streak
        int currentStreak = _calculateCurrentAllHabitsStreak(habitProvider);

        // Calculate weekly completion percentage
        int weeklyCompletionPercentage =
            _calculateWeeklyCompletionPercentage(habitProvider);

        return HeroStatsCard(
          currentStreak: currentStreak,
          weeklyCompletionPercentage: weeklyCompletionPercentage,
          habitProvider: habitProvider,
        );
      },
    );
  }

  int _calculateWeeklyCompletionPercentage(HabitProvider habitProvider) {
    final activeHabits = habitProvider.activeHabits;
    if (activeHabits.isEmpty) return 0;

    final today = DateTime.now();
    int totalPossibleCompletions = 0;
    int actualCompletions = 0;

    // Check last 7 days
    for (int daysBack = 0; daysBack < 7; daysBack++) {
      final checkDate = today.subtract(Duration(days: daysBack));

      // Get habits that existed on this date
      List<Habit> habitsOnDate = activeHabits
          .where((habit) => !habit.createdAt.isAfter(checkDate))
          .toList();

      totalPossibleCompletions += habitsOnDate.length;

      // Count completions on this date
      for (var habit in habitsOnDate) {
        bool habitCompleted = habit.completedDates.any((date) =>
            date.year == checkDate.year &&
            date.month == checkDate.month &&
            date.day == checkDate.day);

        if (habitCompleted) {
          actualCompletions++;
        }
      }
    }

    if (totalPossibleCompletions == 0) return 0;
    return ((actualCompletions / totalPossibleCompletions) * 100).round();
  }

  Widget _buildNewStatsSection(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        // Ensure we have a valid habit provider
        int currentAllHabitsStreak =
            _calculateCurrentAllHabitsStreak(habitProvider);

        // Calculate best all-habits streak in history
        int bestAllHabitsStreak = _calculateBestAllHabitsStreak(habitProvider);

        // Calculate score: +50 points for each day ALL habits were completed
        int score = _calculateTotalScore(habitProvider);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Current Streaks',
                  value: '$currentAllHabitsStreak',
                  icon: Icons.local_fire_department,
                  color: Color(0xFF9B5DE5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Best Streak',
                  value: '$bestAllHabitsStreak',
                  icon: Icons.emoji_events,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Score',
                  value: '$score',
                  icon: Icons.star,
                  color: Color(0xFF9B5DE5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, habitProvider, child) {
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Active Habits',
                value: '${habitProvider.activeHabits.length}',
                icon: Icons.track_changes,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Total Streaks',
                value: '${habitProvider.totalStreaks}',
                icon: Icons.local_fire_department,
                color: Color(0xFF9B5DE5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                title: 'Completed Today',
                value: '${habitProvider.completedTodayCount}',
                icon: Icons.check_circle,
                color: Colors.greenAccent,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: theme.colorScheme.outline.withAlpha((0.2 * 255).round())),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha((0.18 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Column(
      children: [
        _buildMenuCard(
          context,
          [
            _buildMenuItem(
              context,
              title: 'Analysis',
              subtitle: 'View your habit statistics and progress',
              icon: Icons.analytics,
              iconColor: Color(0xFF9B5DE5),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AnalysisScreen()),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context,
          [
            _buildMenuItem(
              context,
              title: 'Backup Data',
              subtitle: 'Export or import your habits, notes, and settings',
              icon: Icons.cloud_sync,
              iconColor: Colors.tealAccent,
              onTap: () => _showBackupDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context,
          [
            _buildMenuItem(
              context,
              title: 'Reset Widget Configuration',
              subtitle: 'Clear widget habit selection',
              icon: Icons.widgets_outlined,
              iconColor: Colors.orangeAccent,
              onTap: () {
                _showResetWidgetDialog(context);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context,
          [
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return _buildMenuItem(
                  context,
                  title: 'Dark Mode',
                  subtitle: 'Toggle app theme',
                  icon: themeProvider.isDarkMode
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  iconColor: themeProvider.isDarkMode
                      ? Colors.purpleAccent
                      : Colors.orangeAccent,
                  onTap: () {
                    final newMode = themeProvider.isDarkMode
                        ? ThemeMode.light
                        : ThemeMode.dark;
                    themeProvider.setThemeMode(newMode);
                  },
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    activeColor: const Color(0xFF9B5DE5),
                    onChanged: (value) {
                      final newMode = value ? ThemeMode.dark : ThemeMode.light;
                      themeProvider.setThemeMode(newMode);
                    },
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Modified "Share App" Menu Item
        _buildMenuCard(
          context,
          [
            _buildMenuItem(
              context,
              title: 'Share App',
              subtitle: 'Invite friends to join Streakly',
              icon: Icons.share, // Changed icon
              iconColor: Colors.lightGreen,
              onTap: () {
                _showShareDialog(context); // Changed method name for clarity
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context,
          [
            _buildMenuItem(
              context,
              title: 'Help & Support',
              subtitle: 'Get help and contact support',
              icon: Icons.help_outline,
              iconColor: Colors.cyanAccent,
              onTap: () {
                _showSupportDialog(context);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context,
          [
            _buildMenuItem(
              context,
              title: 'About',
              subtitle: 'Learn more about Streakly',
              icon: Icons.info_outline,
              iconColor: Colors.tealAccent,
              onTap: () {
                _showAboutDialog(context);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context,
          [
            _buildMenuItem(
              context,
              title: 'Privacy Policy',
              subtitle: 'Read our privacy policy and data usage',
              icon: Icons.privacy_tip_outlined,
              iconColor: Colors.indigo,
              onTap: () {
                _showPrivacyPolicy(context);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context,
          [
            _buildMenuItem(
              context,
              title: 'Terms of Service',
              subtitle: 'View terms and conditions of use',
              icon: Icons.description_outlined,
              iconColor: Color(0xFF9B5DE5),
              onTap: () {
                _showTermsOfService(context);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildMenuCard(
          context,
          [
            _buildMenuItem(
              context,
              title: 'Sign Out',
              subtitle: 'Sign out of your account',
              icon: Icons.logout,
              iconColor: Colors.redAccent,
              onTap: () {
                _showSignOutDialog(context);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuCard(BuildContext context, List<Widget> children) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: theme.colorScheme.outline.withAlpha((0.2 * 255).round())),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required Color iconColor,
      required VoidCallback onTap,
      Widget? trailing}) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withAlpha((0.18 * 255).round()),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withAlpha((0.6 * 255).round()),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                Icon(Icons.chevron_right,
                    color: theme.colorScheme.onSurface
                        .withAlpha((0.4 * 255).round())),
          ],
        ),
      ),
    );
  }

  // MODIFIED DIALOG FOR SHARING THE APP
  void _showShareDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.share, color: Colors.lightGreen),
            const SizedBox(width: 8),
            const Text('Share Streakly'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.local_fire_department,
                color: Color(0xFF9B5DE5), size: 40),
            const SizedBox(height: 16),
            Text(
              'Enjoying Streakly? Share it with your friends and help them build great habits too!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.colorScheme.onSurface.withAlpha((0.7 * 255).round()),
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.link),
              label: const Text('Share App Link'),
              onPressed: () {
                // IMPORTANT: Replace with your actual package name
                const appPackageName = 'your.package.name';
                const appLink =
                    'https://play.google.com/store/apps/details?id=$appPackageName';

                final shareText =
                    'Check out Streakly, a great app for building habits! You can download it here: $appLink';
                Share.share(shareText);
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.privacy_tip_outlined, color: Colors.indigo),
            const SizedBox(width: 8),
            const Text('Privacy Policy'),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Data Collection',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We collect minimal data necessary to provide our habit tracking services:\n'
                  '• Account information (email, username)\n'
                  '• Habit data and completion records\n'
                  '• App usage analytics for improvement',
                  softWrap: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'Data Usage',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your data is used to:\n'
                  '• Sync your habits across devices\n'
                  '• Provide personalized insights\n'
                  '• Improve app functionality',
                  softWrap: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'Data Security',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We use industry-standard encryption and security measures to protect your data. Your habit data is stored securely and is never shared with third parties.',
                  softWrap: true,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.description_outlined, color: Color(0xFF9B5DE5)),
            const SizedBox(width: 8),
            const Text('Terms of Service'),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Acceptance of Terms',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'By using Streakly, you agree to these terms of service. If you do not agree, please discontinue use of the app.',
                  softWrap: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'User Responsibilities',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Use the app for personal habit tracking only\n'
                  '• Provide accurate information\n'
                  '• Respect other users in community features\n'
                  '• Do not attempt to hack or misuse the service',
                  softWrap: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'Service Availability',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'We strive to provide reliable service but cannot guarantee 100% uptime. We reserve the right to modify or discontinue features with notice.',
                  softWrap: true,
                ),
                const SizedBox(height: 16),
                Text(
                  'Limitation of Liability',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Streakly is provided "as is" without warranties. We are not liable for any damages arising from app usage.',
                  softWrap: true,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  int _calculateCurrentAllHabitsStreak(HabitProvider habitProvider) {
    final activeHabits = habitProvider.activeHabits;
    if (activeHabits.isEmpty) return 0;

    int streak = 0;
    final today = DateTime.now();
    bool streakStarted = false;

    // Check each day going backwards from today
    for (int daysBack = 0; daysBack < 365; daysBack++) {
      final checkDate = today.subtract(Duration(days: daysBack));
      bool allHabitsCompleted = true;

      // Get habits that existed on this date
      List<Habit> habitsOnDate = activeHabits
          .where((habit) => !habit.createdAt.isAfter(checkDate))
          .toList();

      if (habitsOnDate.isEmpty) {
        // No habits existed on this date, skip
        continue;
      }

      // Check if ALL habits that existed were completed on this date
      for (var habit in habitsOnDate) {
        bool habitCompleted = habit.completedDates.any((date) =>
            date.year == checkDate.year &&
            date.month == checkDate.month &&
            date.day == checkDate.day);

        if (!habitCompleted) {
          allHabitsCompleted = false;
          break;
        }
      }

      if (allHabitsCompleted) {
        streak++;
        streakStarted = true;
      } else {
        // If we haven't started counting yet (today/yesterday not completed)
        if (!streakStarted && daysBack <= 1) {
          continue; // Allow today or yesterday to be incomplete
        }
        break; // Streak is broken
      }
    }

    return streak;
  }

  int _calculateBestAllHabitsStreak(HabitProvider habitProvider) {
    final activeHabits = habitProvider.activeHabits;
    if (activeHabits.isEmpty) return 0;

    int bestStreak = 0;
    int currentStreak = 0;
    final today = DateTime.now();

    // Find the earliest habit creation date
    DateTime earliestDate = today;
    for (var habit in activeHabits) {
      if (habit.createdAt.isBefore(earliestDate)) {
        earliestDate = habit.createdAt;
      }
    }

    // Check every day from earliest habit creation to today
    for (int daysFromStart = 0;
        daysFromStart <= today.difference(earliestDate).inDays;
        daysFromStart++) {
      final checkDate = earliestDate.add(Duration(days: daysFromStart));
      bool allHabitsCompleted = true;

      // Get habits that existed on this date
      List<Habit> habitsOnDate = activeHabits
          .where((habit) => !habit.createdAt.isAfter(checkDate))
          .toList();

      if (habitsOnDate.isEmpty) {
        currentStreak = 0;
        continue;
      }

      // Check if ALL habits that existed were completed on this date
      for (var habit in habitsOnDate) {
        bool habitCompleted = habit.completedDates.any((date) =>
            date.year == checkDate.year &&
            date.month == checkDate.month &&
            date.day == checkDate.day);

        if (!habitCompleted) {
          allHabitsCompleted = false;
          break;
        }
      }

      if (allHabitsCompleted) {
        currentStreak++;
        if (currentStreak > bestStreak) {
          bestStreak = currentStreak;
        }
      } else {
        currentStreak = 0;
      }
    }

    return bestStreak;
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'About Streakly',
              style: theme.textTheme.titleLarge,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0', style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            const Text(
                'Streakly helps you build better habits and maintain consistency in your daily routines.'),
            const SizedBox(height: 12),
            const Text(
                'Built with Flutter and designed for habit enthusiasts.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    final emailController = TextEditingController();
    final messageController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.help_outline,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Help & Support'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Your Email',
                  hintText: 'Enter your email address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Message',
                  hintText: 'How can we help you?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                  color: theme.colorScheme.onSurface
                      .withAlpha((0.6 * 255).round())),
            ),
          ),
          FilledButton(
            onPressed: () async {
              final email = emailController.text.trim();
              final message = messageController.text.trim();

              if (email.isEmpty || !email.contains('@')) {
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(
                  const SnackBar(
                      content: Text('Please enter a valid email address')),
                );
                return;
              }

              if (message.isEmpty) {
                final messenger = ScaffoldMessenger.of(context);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Please enter your message')),
                );
                return;
              }

              // Launch email client with pre-filled content
              final Uri emailUri = Uri(
                scheme: 'mailto',
                path: 'habitmakerc@gmail.com',
                query:
                    'subject=Streakly Support Request&body=${Uri.encodeComponent(message)}\n\nFrom: $email',
              );

              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              try {
                await launchUrl(emailUri);
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Opening email client...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (_) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Could not open email client. Please send your message to habitmakerc@gmail.com'),
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    ).then((_) {
      // Clean up controllers
      emailController.dispose();
      messageController.dispose();
    });
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ModernButton(
                    text: 'Cancel',
                    type: ModernButtonType.outline,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: ModernButton(
                    text: 'Sign Out',
                    type: ModernButtonType.destructive,
                    onPressed: () {
                      Provider.of<AuthProvider>(context, listen: false)
                          .logout();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (_) => const MainNavigation()),
                        (route) => false,
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

  void _showBackupDialog(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary
                            .withAlpha((0.12 * 255).round()),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.cloud_sync,
                          color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Backup Data',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Quickly export your data or restore from a saved JSON backup.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withAlpha((0.7 * 255).round()),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withAlpha((0.16 * 255).round()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.ios_share, color: Colors.green),
                  ),
                  title: const Text('Share Backup'),
                  subtitle: const Text(
                      'Send the JSON export via mail, chat, or cloud drive'),
                  onTap: () => _handleExportShare(context, sheetContext),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withAlpha((0.16 * 255).round()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.save_alt, color: Colors.blueAccent),
                  ),
                  title: const Text('Save to Device'),
                  subtitle: const Text(
                      'Store a copy inside the app documents folder'),
                  onTap: () => _handleExportSave(context, sheetContext),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xFF9B5DE5).withAlpha((0.16 * 255).round()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.upload_file, color: Color(0xFF9B5DE5)),
                  ),
                  title: const Text('Import Backup'),
                  subtitle: const Text(
                      'Restore from a JSON file exported from Streakly'),
                  onTap: () => _handleImport(context, sheetContext),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleExportShare(
      BuildContext context, BuildContext sheetContext) async {
    Navigator.of(sheetContext).pop();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ExportImportService.instance.shareExport();
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Opening share sheet with your backup...')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleExportSave(
      BuildContext context, BuildContext sheetContext) async {
    Navigator.of(sheetContext).pop();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await ExportImportService.instance.exportToFile();
      messenger.showSnackBar(
        SnackBar(content: Text('Backup saved to ${file.path}')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleImport(
      BuildContext context, BuildContext sheetContext) async {
    Navigator.of(sheetContext).pop();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final path = result.files.first.path;
      if (path == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Selected file is not accessible')),
        );
        return;
      }

      final file = File(path);
      final content = await file.readAsString();
      messenger.showSnackBar(
        const SnackBar(content: Text('Importing data...')),
      );

      final resultMap = await ExportImportService.instance
          .importFromJsonString(content, overwrite: false);

      if (resultMap['success'] == true) {
        // Refresh habits data after successful import
        if (context.mounted) {
          await Provider.of<HabitProvider>(context, listen: false).loadHabits();
          await Provider.of<NoteProvider>(context, listen: false).loadNotes();
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text('Import complete. Restarting app...'),
            duration: const Duration(seconds: 1),
          ),
        );

        // Wait for snackbar
        await Future.delayed(const Duration(seconds: 1));

        if (context.mounted) {
          // Restart app by navigating to Splash Screen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SplashScreen()),
            (route) => false,
          );
        }
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                'Import failed: ${resultMap['error']} (backup: ${resultMap['backup']})'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showResetWidgetDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.widgets_outlined,
                color: Colors.orangeAccent,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Reset Widget'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.refresh, color: Colors.orangeAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              'This will clear the current widget configuration. The next time you add a widget, it will show "+ Add Habit".',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              // Clear widget configuration via platform channel
              try {
                const platform = MethodChannel('com.harirajan.streakly/widget');
                await platform.invokeMethod('clearWidgetConfig');

                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Widget configuration cleared!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Error clearing widget config: $e');
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to clear widget configuration'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  int _calculateTotalScore(HabitProvider habitProvider) {
    final activeHabits = habitProvider.activeHabits;
    if (activeHabits.isEmpty) return 0;

    int totalScore = 0;
    final today = DateTime.now();

    // Find the earliest habit creation date
    DateTime earliestDate = today;
    for (var habit in activeHabits) {
      if (habit.createdAt.isBefore(earliestDate)) {
        earliestDate = habit.createdAt;
      }
    }

    // Check every day from earliest habit creation to today
    for (int daysFromStart = 0;
        daysFromStart <= today.difference(earliestDate).inDays;
        daysFromStart++) {
      final checkDate = earliestDate.add(Duration(days: daysFromStart));
      bool allHabitsCompleted = true;

      // Get habits that existed on this date
      List<Habit> habitsOnDate = activeHabits
          .where((habit) => !habit.createdAt.isAfter(checkDate))
          .toList();

      if (habitsOnDate.isEmpty) {
        continue;
      }

      // Check if ALL habits that existed were completed on this date
      for (var habit in habitsOnDate) {
        bool habitCompleted = habit.completedDates.any((date) =>
            date.year == checkDate.year &&
            date.month == checkDate.month &&
            date.day == checkDate.day);

        if (!habitCompleted) {
          allHabitsCompleted = false;
          break;
        }
      }

      // Award 50 points for each day ALL habits were completed
      if (allHabitsCompleted) {
        totalScore += 50;
      }
    }

    return totalScore;
  }

  int _calculateCompletionScore(HabitProvider habitProvider) {
    final habits = habitProvider.habits;
    if (habits.isEmpty) return 0;

    int totalCompletions = 0;
    for (final habit in habits) {
      if (habit.dailyCompletions.isNotEmpty) {
        totalCompletions +=
            habit.dailyCompletions.values.fold(0, (sum, count) => sum + count);
      } else {
        totalCompletions += habit.completedDates.length;
      }
    }

    return totalCompletions * 10;
  }
}
