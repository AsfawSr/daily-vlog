class DailyActivity {
  final String id;
  final String title;
  final String description;
  final String category;
  final String mood;
  final String moodEmoji;
  final String? mediaPath;
  final List<String> mediaPaths;
  final String mediaType; // 'video', 'photo', or 'text'
  final int videoDurationSeconds;
  final DateTime createdAt;

  DailyActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.mood,
    required this.moodEmoji,
    String? mediaPath,
    List<String>? mediaPaths,
    String? videoPath,
    String? mediaType,
    this.videoDurationSeconds = 0,
    required this.createdAt,
  })  : mediaPaths = mediaPaths ??
            (mediaPath != null
                ? [mediaPath]
                : (videoPath != null ? [videoPath] : const [])),
        mediaPath = mediaPath ??
            (mediaPaths != null && mediaPaths.isNotEmpty
                ? mediaPaths.first
                : videoPath),
        mediaType = mediaType ??
            (((mediaPaths != null && mediaPaths.isNotEmpty) ||
                    mediaPath != null ||
                    videoPath != null)
                ? ((videoDurationSeconds > 0 ||
                        (mediaPath ??
                                videoPath ??
                                (mediaPaths != null && mediaPaths.isNotEmpty
                                    ? mediaPaths.first
                                    : ''))
                            .endsWith('.mp4'))
                    ? 'video'
                    : 'photo')
                : 'text');

  String? get videoPath => mediaType == 'video' ? mediaPath : null;
  String? get photoPath => mediaType == 'photo' ? mediaPath : null;
  List<String> get photoPaths => mediaType == 'photo' ? mediaPaths : const [];
  bool get hasVideo =>
      mediaType == 'video' && mediaPath != null && mediaPath!.isNotEmpty;
  bool get hasPhoto =>
      mediaType == 'photo' &&
      (mediaPaths.isNotEmpty || (mediaPath != null && mediaPath!.isNotEmpty));
  bool get hasMultiplePhotos => mediaType == 'photo' && mediaPaths.length > 1;
  int get photoCount => mediaType == 'photo' ? mediaPaths.length : 0;
  bool get hasMedia =>
      (mediaPaths.isNotEmpty) || (mediaPath != null && mediaPath!.isNotEmpty);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'mood': mood,
      'moodEmoji': moodEmoji,
      'mediaPath': mediaPath,
      'mediaPaths': mediaPaths,
      'videoPath': mediaPath, // for backward compatibility
      'mediaType': mediaType,
      'videoDurationSeconds': videoDurationSeconds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DailyActivity.fromMap(Map<dynamic, dynamic> map) {
    final rawList = map['mediaPaths'];
    List<String> parsedPaths = [];
    if (rawList is List) {
      parsedPaths = rawList.map((e) => e.toString()).toList();
    }

    final rawMediaPath =
        map['mediaPath'] as String? ?? map['videoPath'] as String?;

    if (parsedPaths.isEmpty && rawMediaPath != null) {
      parsedPaths = [rawMediaPath];
    }

    final rawType = map['mediaType'] as String? ??
        (rawMediaPath != null
            ? (rawMediaPath.endsWith('.mp4') ? 'video' : 'photo')
            : (parsedPaths.isNotEmpty ? 'photo' : 'text'));

    return DailyActivity(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'Untitled Activity',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      mood: map['mood'] as String? ?? 'Happy',
      moodEmoji: map['moodEmoji'] as String? ?? '😊',
      mediaPath: rawMediaPath ?? (parsedPaths.isNotEmpty ? parsedPaths.first : null),
      mediaPaths: parsedPaths,
      mediaType: rawType,
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
    String? mediaPath,
    List<String>? mediaPaths,
    String? videoPath,
    String? mediaType,
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
      mediaPath: mediaPath ?? videoPath ?? this.mediaPath,
      mediaPaths: mediaPaths ?? this.mediaPaths,
      mediaType: mediaType ?? this.mediaType,
      videoDurationSeconds: videoDurationSeconds ?? this.videoDurationSeconds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
