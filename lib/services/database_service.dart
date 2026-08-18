import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/activity_model.dart';
import 'storage_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String boxName = 'daily_activities_box';
  Box? _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(boxName);
  }

  Box get box {
    if (_box == null || !_box!.isOpen) {
      throw Exception("DatabaseService not initialized. Call init() first.");
    }
    return _box!;
  }

  ValueListenable<Box> get listenable => box.listenable();

  /// Retrieve all activities sorted by creation date (newest first)
  List<DailyActivity> getAllActivities() {
    final rawValues = box.values.toList();
    final activities = <DailyActivity>[];

    for (final raw in rawValues) {
      if (raw is Map) {
        activities.add(DailyActivity.fromMap(raw));
      }
    }

    activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return activities;
  }

  /// Get activities grouped by day string (e.g. "Today", "Yesterday", "2026-08-18")
  Map<DateTime, List<DailyActivity>> getActivitiesGroupedByDate() {
    final all = getAllActivities();
    final grouped = <DateTime, List<DailyActivity>>{};

    for (final activity in all) {
      final dateKey = DateTime(
        activity.createdAt.year,
        activity.createdAt.month,
        activity.createdAt.day,
      );
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(activity);
    }
    return grouped;
  }

  /// Get single activity by ID
  DailyActivity? getActivityById(String id) {
    final raw = box.get(id);
    if (raw != null && raw is Map) {
      return DailyActivity.fromMap(raw);
    }
    return null;
  }

  /// Save or update an activity
  Future<void> saveActivity(DailyActivity activity) async {
    await box.put(activity.id, activity.toMap());
  }

  /// Delete an activity and its associated video file
  Future<void> deleteActivity(String id) async {
    final existing = getActivityById(id);
    if (existing?.videoPath != null) {
      await StorageService().deleteVideo(existing!.videoPath);
    }
    await box.delete(id);
  }

  /// Filter activities by category
  List<DailyActivity> filterByCategory(String category) {
    if (category == 'All') return getAllActivities();
    return getAllActivities()
        .where((act) => act.category.toLowerCase() == category.toLowerCase())
        .toList();
  }
}
