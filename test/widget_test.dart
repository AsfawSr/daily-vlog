import 'package:flutter_test/flutter_test.dart';
import 'package:daily_vlog/models/activity_model.dart';

void main() {
  test('DailyActivity default values', () {
    final activity = DailyActivity(
      id: 'test-1',
      title: 'Quick Activity',
      description: '',
      category: 'General',
      mood: 'Calm',
      moodEmoji: '😌',
      createdAt: DateTime.now(),
    );

    expect(activity.videoPath, isNull);
    expect(activity.videoDurationSeconds, 0);
  });
}
