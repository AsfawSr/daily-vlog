import 'package:flutter_test/flutter_test.dart';
import 'package:daily_vlog/models/activity_model.dart';

void main() {
  group('DailyActivity Model Tests', () {
    test('Serialization and deserialization to Map works correctly', () {
      final now = DateTime(2026, 8, 18, 16, 30);
      final activity = DailyActivity(
        id: 'test-id-123',
        title: 'Evening Run & Daily Vlog',
        description: 'Completed 5km around the park. Feeling fresh!',
        category: 'Workout',
        mood: 'Energized',
        moodEmoji: '⚡',
        videoPath: '/data/user/0/com.dailyvlog.app/app_flutter/vlog_123.mp4',
        videoDurationSeconds: 45,
        createdAt: now,
      );

      final map = activity.toMap();

      expect(map['id'], 'test-id-123');
      expect(map['title'], 'Evening Run & Daily Vlog');
      expect(map['description'], 'Completed 5km around the park. Feeling fresh!');
      expect(map['category'], 'Workout');
      expect(map['mood'], 'Energized');
      expect(map['moodEmoji'], '⚡');
      expect(map['videoPath'], '/data/user/0/com.dailyvlog.app/app_flutter/vlog_123.mp4');
      expect(map['videoDurationSeconds'], 45);
      expect(map['createdAt'], now.toIso8601String());

      final restored = DailyActivity.fromMap(map);
      expect(restored.id, activity.id);
      expect(restored.title, activity.title);
      expect(restored.description, activity.description);
      expect(restored.category, activity.category);
      expect(restored.mood, activity.mood);
      expect(restored.moodEmoji, activity.moodEmoji);
      expect(restored.videoPath, activity.videoPath);
      expect(restored.videoDurationSeconds, 45);
      expect(restored.createdAt, now);
    });

    test('copyWith properly overrides specified properties', () {
      final activity = DailyActivity(
        id: '1',
        title: 'Original Title',
        description: 'Original Description',
        category: 'Work',
        mood: 'Happy',
        moodEmoji: '😊',
        createdAt: DateTime.now(),
      );

      final updated = activity.copyWith(
        title: 'Updated Title',
        category: 'Coding',
      );

      expect(updated.id, '1');
      expect(updated.title, 'Updated Title');
      expect(updated.description, 'Original Description');
      expect(updated.category, 'Coding');
      expect(updated.mood, 'Happy');
    });

    test('Photo media serialization and deserialization works correctly', () {
      final photoActivity = DailyActivity(
        id: 'photo-1',
        title: 'Sunset View',
        description: 'Golden hour at the lake',
        category: 'Life',
        mood: 'Calm',
        moodEmoji: '😌',
        mediaPath: '/data/user/0/com.dailyvlog.app/app_flutter/photo_123.jpg',
        mediaType: 'photo',
        createdAt: DateTime.now(),
      );

      expect(photoActivity.hasPhoto, isTrue);
      expect(photoActivity.hasVideo, isFalse);
      expect(photoActivity.photoPath, contains('photo_123.jpg'));

      final map = photoActivity.toMap();
      expect(map['mediaType'], 'photo');
      expect(map['mediaPath'], contains('photo_123.jpg'));

      final restored = DailyActivity.fromMap(map);
      expect(restored.hasPhoto, isTrue);
      expect(restored.mediaType, 'photo');
      expect(restored.mediaPath, contains('photo_123.jpg'));
    });

    test('Multiple photos serialization and deserialization works correctly', () {
      final multiPhotoActivity = DailyActivity(
        id: 'multi-1',
        title: 'Weekend Hike',
        description: 'Photos from the mountain trail',
        category: 'Travel',
        mood: 'Energized',
        moodEmoji: '⚡',
        mediaPaths: [
          '/app_flutter/photo_1.jpg',
          '/app_flutter/photo_2.jpg',
          '/app_flutter/photo_3.jpg',
        ],
        mediaType: 'photo',
        createdAt: DateTime.now(),
      );

      expect(multiPhotoActivity.hasPhoto, isTrue);
      expect(multiPhotoActivity.hasMultiplePhotos, isTrue);
      expect(multiPhotoActivity.photoCount, 3);
      expect(multiPhotoActivity.photoPaths.length, 3);

      final map = multiPhotoActivity.toMap();
      expect(map['mediaPaths'], isList);
      expect((map['mediaPaths'] as List).length, 3);

      final restored = DailyActivity.fromMap(map);
      expect(restored.hasMultiplePhotos, isTrue);
      expect(restored.photoCount, 3);
      expect(restored.photoPaths[0], contains('photo_1.jpg'));
      expect(restored.photoPaths[1], contains('photo_2.jpg'));
      expect(restored.photoPaths[2], contains('photo_3.jpg'));
    });
  });
}
