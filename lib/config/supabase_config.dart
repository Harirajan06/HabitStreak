// Supabase configuration removed. App now uses local Hive storage.
// This file remains as a deprecated stub to avoid breaking imports.
@deprecated
class SupabaseConfig {
  // Intentionally empty — Supabase keys removed for local-only mode.
  static const String supabaseUrl = '';
  static const String supabaseAnonKey = '';

  // Keep table name constants for any lingering references.
  static const String usersTable = 'users';
  static const String habitsTable = 'habits';
  static const String habitCompletionsTable = 'habit_completions';
  static const String userStatsTable = 'user_stats';
  static const String notesTable = 'notes';
}
