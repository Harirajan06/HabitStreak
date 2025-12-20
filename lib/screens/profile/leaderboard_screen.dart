import 'package:flutter/material.dart';
import '../../models/leaderboard_entry.dart';
import '../../services/hive_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<LeaderboardEntry> _leaderboardData = const <LeaderboardEntry>[];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Build a local leaderboard from Hive data
      final users = HiveService.instance.getUsers();
      final habits = HiveService.instance.getHabits();

      final entries = users.map((u) {
        final userHabits = habits.where((h) => h.id != null).toList();
        // Filter by user id if you have user_id in habit, otherwise use all habits
        final userSpecificHabits = habits.where((h) => true).toList();

        final totalHabits = userSpecificHabits.length;
        final totalCompletions = userSpecificHabits.fold<int>(0, (sum, h) => sum + h.completedDates.length);
        final currentStreak = userSpecificHabits.fold<int>(0, (maxv, h) => h.currentStreak > maxv ? h.currentStreak : maxv);
        final longestStreak = userSpecificHabits.fold<int>(0, (maxv, h) => h.longestStreak > maxv ? h.longestStreak : maxv);

        return LeaderboardEntry(
          userId: u.id,
          name: u.name,
          email: u.email,
          avatarEmoji: u.avatarUrl,
          totalHabits: totalHabits,
          totalCompletions: totalCompletions,
          currentStreak: currentStreak,
          longestStreak: longestStreak,
        );
      }).toList();

      entries.sort((a, b) => b.totalCompletions.compareTo(a.totalCompletions));

      if (!mounted) return;
      setState(() {
        _leaderboardData = entries.take(30).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _leaderboardData = const <LeaderboardEntry>[];
        _errorMessage = _mapError(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              color: theme.colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Leaderboard',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        // Removed menu to fix overflow issues
      ),
      body: Column(
        children: [
          _buildHeader(theme),
          if (_leaderboardData.isNotEmpty) _buildTopThree(theme),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadLeaderboard,
              child: _buildLeaderboardBody(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child:
                const Icon(Icons.emoji_events, size: 36, color: Colors.amber),
          ),
          const SizedBox(height: 16),
          Text(
            'Global Leaderboard',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Compete with habit builders worldwide',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardBody(ThemeData theme) {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 160),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 120),
          _buildErrorState(theme),
        ],
      );
    }

    if (_leaderboardData.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 120),
          _buildEmptyState(theme),
        ],
      );
    }

    return _buildLeaderboardList(theme);
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Column(
      children: [
        Icon(Icons.people_alt_outlined,
            size: 64, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'No leaderboard data yet',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Complete habits to start ranking globally.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Column(
      children: [
        Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Text(
          'Unable to load leaderboard',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage ?? 'Something went wrong. Please try again.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _loadLeaderboard,
          icon: const Icon(Icons.refresh),
          label: const Text('Try Again'),
        ),
      ],
    );
  }

  String _mapError(dynamic error) {
    final message = error.toString();
    if (message.contains('Failed host lookup') ||
        message.contains('SocketException') ||
        message.contains('Connection refused')) {
      return 'Check your internet connection and try again.';
    }
    if (message.contains('permission denied')) {
      return 'You do not have access to view the global leaderboard yet.';
    }
    return message;
  }

  Widget _buildTopThree(ThemeData theme) {
    final topThree = _leaderboardData.take(3).toList();
    if (topThree.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (topThree.length > 1)
            _buildPodiumItem(theme, topThree[1], 2, Colors.grey),
          if (topThree.isNotEmpty)
            _buildPodiumItem(theme, topThree[0], 1, Colors.amber),
          if (topThree.length > 2)
            _buildPodiumItem(theme, topThree[2], 3, Colors.brown),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(
      ThemeData theme, LeaderboardEntry entry, int position, Color color) {
    final isFirst = position == 1;
    final isCurrentUser = _isCurrentUser(entry);

    return Column(
      children: [
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              width: isFirst ? 86 : 66,
              height: isFirst ? 86 : 66,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(isFirst ? 44 : 33),
                border: Border.all(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: isCurrentUser
                        ? theme.colorScheme.primary.withOpacity(0.4)
                        : color.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? theme.colorScheme.primary
                      : color.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(isFirst ? 38 : 28),
                ),
                child: Center(
                  child: Text(
                    entry.displayAvatar,
                    style: TextStyle(
                      fontSize: isFirst ? 30 : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '$position',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          entry.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isCurrentUser
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '${entry.score}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardList(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _leaderboardData.length,
        separatorBuilder: (context, index) => Divider(
          color: theme.colorScheme.outline.withOpacity(0.2),
          height: 1,
        ),
        itemBuilder: (context, index) {
          final entry = _leaderboardData[index];
          final position = index + 1;
          final isCurrentUser = _isCurrentUser(entry);
          final subtitle = isCurrentUser
              ? 'You'
              : (entry.email.isNotEmpty ? entry.email : 'Habit Builder');

          return Container(
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? theme.colorScheme.primary.withOpacity(0.14)
                  : Colors.transparent,
              borderRadius: index == 0
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22))
                  : index == _leaderboardData.length - 1
                      ? const BorderRadius.only(
                          bottomLeft: Radius.circular(22),
                          bottomRight: Radius.circular(22))
                      : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      '#$position',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _getPositionColor(position, theme),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isCurrentUser
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.1)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      entry.displayAvatar,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isCurrentUser
                            ? Colors.white
                            : Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: isCurrentUser
                                ? FontWeight.w700
                                : FontWeight.w500,
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
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department,
                            size: 16, color: Colors.orangeAccent),
                        const SizedBox(width: 6),
                        Text(
                          '${entry.score}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _getPositionColor(position, theme),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getPositionColor(int position, ThemeData theme) {
    switch (position) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.white;
    }
  }

  bool _isCurrentUser(LeaderboardEntry entry) {
    final settings = HiveService.instance.getSettings();
    final currentUserId = settings['currentUserId'] as String?;
    return currentUserId != null && entry.userId == currentUserId;
  }
}
