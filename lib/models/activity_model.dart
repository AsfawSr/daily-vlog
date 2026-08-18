class DailyActivity {
  final String id;
  final String title;
  final String description;
  final String category;
  final String mood;
  final String moodEmoji;
  final String? videoPath;
  final int videoDurationSeconds;
  final DateTime createdAt;

  DailyActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.mood,
    required this.moodEmoji,
    this.videoPath,
    this.videoDurationSeconds = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'mood': mood,
      'moodEmoji': moodEmoji,
      'videoPath': videoPath,
      'videoDurationSeconds': videoDurationSeconds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DailyActivity.fromMap(Map<dynamic, dynamic> map) {
    return DailyActivity(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'Untitled Activity',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      mood: map['mood'] as String? ?? 'Happy',
      moodEmoji: map['moodEmoji'] as String? ?? '😊',
      videoPath: map['videoPath'] as String?,
      videoDurationSeconds: (map['videoDurationSeconds'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  DailyActivity copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? mood,
    String? moodEmoji,
    String? videoPath,
    int? videoDurationSeconds,
    DateTime? createdAt,
  }) {
    return DailyActivity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      mood: mood ?? this.mood,
      moodEmoji: moodEmoji ?? this.moodEmoji,
      videoPath: videoPath ?? this.videoPath,
      videoDurationSeconds: videoDurationSeconds ?? this.videoDurationSeconds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
