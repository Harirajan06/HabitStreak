class LeaderboardEntry {
  final String userId;
  final String name;
  final String email;
  final String? avatarEmoji;
  final int totalHabits;
  final int totalCompletions;
  final int currentStreak;
  final int longestStreak;

  LeaderboardEntry({
    required this.userId,
    required this.name,
    required this.email,
    this.avatarEmoji,
    required this.totalHabits,
    required this.totalCompletions,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> data) {
    final user =
        (data['users'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    String resolveString(dynamic value) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      return '';
    }

    final resolvedName = resolveString(data['name'])
        .ifEmpty(() => resolveString(user['name']))
        .ifEmpty(() => 'Habit Builder');

    final resolvedEmail = resolveString(data['email'])
        .ifEmpty(() => resolveString(user['email']));

    final resolvedAvatar = resolveString(data['avatar_url'])
        .ifEmpty(() => resolveString(user['avatar_url']));

    final userIdValue = data['user_id'] ?? user['id'];

    return LeaderboardEntry(
      userId: userIdValue?.toString() ?? '',
      name: resolvedName,
      email: resolvedEmail,
      avatarEmoji: resolvedAvatar.isNotEmpty ? resolvedAvatar : null,
      totalHabits: data['total_habits'] as int? ?? 0,
      totalCompletions: data['total_completions'] as int? ?? 0,
      currentStreak: data['current_streak'] as int? ?? 0,
      longestStreak: data['longest_streak'] as int? ?? 0,
    );
  }
  int get score => totalCompletions;

  String get displayAvatar {
    if (avatarEmoji != null && avatarEmoji!.trim().isNotEmpty) {
      return avatarEmoji!;
    }
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      return trimmed.substring(0, 1).toUpperCase();
    }
    return 'U';
  }
}

extension _EmptyStringExtension on String {
  String ifEmpty(String Function() fallback) {
    return isEmpty ? fallback() : this;
  }
}
