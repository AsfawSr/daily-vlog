import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/activity_model.dart';
import 'storage_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String activitiesBoxName = 'daily_activities_box';
  static const String categoriesBoxName = 'daily_categories_box';
  static const String moodsBoxName = 'daily_moods_box';

  Box? _activitiesBox;
  Box? _categoriesBox;
  Box? _moodsBox;

  static const List<Map<String, String>> defaultCategories = [
    {'name': 'Workout', 'icon': '🏋️'},
    {'name': 'Work', 'icon': '💼'},
    {'name': 'Study', 'icon': '📚'},
    {'name': 'Creative', 'icon': '🎨'},
    {'name': 'Travel', 'icon': '✈️'},
    {'name': 'Food', 'icon': '🍲'},
    {'name': 'Coding', 'icon': '💻'},
    {'name': 'Life', 'icon': '🌿'},
    {'name': 'Morning Routine', 'icon': '☕'},
    {'name': 'Reading', 'icon': '📖'},
  ];

  static const List<Map<String, String>> defaultMoods = [
    {'name': 'Energized', 'emoji': '⚡'},
    {'name': 'Happy', 'emoji': '😊'},
    {'name': 'Calm', 'emoji': '😌'},
    {'name': 'Focused', 'emoji': '🎯'},
    {'name': 'Motivated', 'emoji': '🔥'},
    {'name': 'Grateful', 'emoji': '🙏'},
    {'name': 'Tired', 'emoji': '😴'},
  ];

  Future<void> init() async {
    await Hive.initFlutter();
    _activitiesBox = await Hive.openBox(activitiesBoxName);
    _categoriesBox = await Hive.openBox(categoriesBoxName);
    _moodsBox = await Hive.openBox(moodsBoxName);

    // Populate default categories if empty
    if (_categoriesBox!.isEmpty) {
      for (final cat in defaultCategories) {
        await _categoriesBox!.put(cat['name']!.toLowerCase(), cat);
      }
    }

    // Populate default moods if empty
    if (_moodsBox!.isEmpty) {
      for (final mood in defaultMoods) {
        await _moodsBox!.put(mood['name']!.toLowerCase(), mood);
      }
    }
  }

  Box get box {
    if (_activitiesBox == null || !_activitiesBox!.isOpen) {
      throw Exception("DatabaseService not initialized. Call init() first.");
    }
    return _activitiesBox!;
  }

  Box get categoriesBox {
    if (_categoriesBox == null || !_categoriesBox!.isOpen) {
      throw Exception("DatabaseService categoriesBox not initialized. Call init() first.");
    }
    return _categoriesBox!;
  }

  Box get moodsBox {
    if (_moodsBox == null || !_moodsBox!.isOpen) {
      throw Exception("DatabaseService moodsBox not initialized. Call init() first.");
    }
    return _moodsBox!;
  }

  ValueListenable<Box> get listenable => box.listenable();
  ValueListenable<Box> get listenableCategories => categoriesBox.listenable();
  ValueListenable<Box> get listenableMoods => moodsBox.listenable();

  // ==================== MOODS CRUD ====================

  /// Retrieve all moods (default + user-created)
  List<Map<String, String>> getMoods() {
    final rawValues = moodsBox.values.toList();
    if (rawValues.isEmpty) {
      return List<Map<String, String>>.from(defaultMoods);
    }

    final list = <Map<String, String>>[];
    for (final item in rawValues) {
      if (item is Map) {
        list.add({
          'name': item['name']?.toString() ?? 'Happy',
          'emoji': item['emoji']?.toString() ?? '😊',
        });
      }
    }
    return list;
  }

  /// Add a custom mood
  Future<void> addMood(String name, String emoji) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    final key = cleanName.toLowerCase();
    await moodsBox.put(key, {
      'name': cleanName,
      'emoji': emoji.trim().isNotEmpty ? emoji.trim() : '😊',
    });
  }

  /// Delete a custom mood
  Future<void> deleteMood(String name) async {
    final key = name.toLowerCase();
    await moodsBox.delete(key);
  }

  // ==================== CATEGORIES CRUD ====================

  /// Retrieve all categories (default + user-created)
  List<Map<String, String>> getCategories() {
    final rawValues = categoriesBox.values.toList();
    if (rawValues.isEmpty) {
      return List<Map<String, String>>.from(defaultCategories);
    }

    final list = <Map<String, String>>[];
    for (final item in rawValues) {
      if (item is Map) {
        list.add({
          'name': item['name']?.toString() ?? 'General',
          'icon': item['icon']?.toString() ?? '📌',
        });
      }
    }
    return list;
  }

  /// Add a custom category
  Future<void> addCategory(String name, String icon) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    final key = cleanName.toLowerCase();
    await categoriesBox.put(key, {
      'name': cleanName,
      'icon': icon.trim().isNotEmpty ? icon.trim() : '📌',
    });
  }

  /// Delete a custom category
  Future<void> deleteCategory(String name) async {
    final key = name.toLowerCase();
    await categoriesBox.delete(key);
  }

  // ==================== ACTIVITIES CRUD ====================

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

  /// Get activities grouped by day
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
