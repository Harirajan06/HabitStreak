class MoodEntry {
  final String id;
  final DateTime date;
  final String emoji;
  final String label;
  final List<String> tags;
  final String notes;
  final int score;

  MoodEntry({
    required this.id,
    required this.date,
    required this.emoji,
    required this.label,
    required this.tags,
    required this.notes,
    this.score = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'emoji': emoji,
      'label': label,
      'tags': tags,
      'notes': notes,
      'score': score,
    };
  }

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      emoji: json['emoji'] as String,
      label: json['label'] as String,
      tags: List<String>.from(json['tags'] as List),
      notes: json['notes'] as String,
      score: json['score'] as int? ?? 0,
    );
  }

  MoodEntry copyWith({
    String? id,
    DateTime? date,
    String? emoji,
    String? label,
    List<String>? tags,
    String? notes,
    int? score,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      emoji: emoji ?? this.emoji,
      label: label ?? this.label,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      score: score ?? this.score,
    );
  }
}
