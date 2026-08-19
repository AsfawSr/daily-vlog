import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  /// Gets or creates the dedicated directory for storing daily vlog videos
  Future<Directory> getVideoDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final videoDir = Directory(p.join(appDocDir.path, 'daily_vlogs'));
    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }
    return videoDir;
  }

  /// Gets or creates the dedicated directory for storing daily photos
  Future<Directory> getPhotoDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final photoDir = Directory(p.join(appDocDir.path, 'daily_photos'));
    if (!await photoDir.exists()) {
      await photoDir.create(recursive: true);
    }
    return photoDir;
  }

  /// Saves a recorded temporary video into persistent storage and returns permanent file path
  Future<String> persistVideo(String tempVideoPath) async {
    final videoDir = await getVideoDirectory();
    final uniqueId = const Uuid().v4().substring(0, 8);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = p.extension(tempVideoPath).isNotEmpty
        ? p.extension(tempVideoPath)
        : '.mp4';
    final permanentFileName = 'vlog_${timestamp}_$uniqueId$extension';
    final permanentPath = p.join(videoDir.path, permanentFileName);

    final tempFile = File(tempVideoPath);
    if (await tempFile.exists()) {
      await tempFile.copy(permanentPath);
      try {
        await tempFile.delete();
      } catch (_) {}
      return permanentPath;
    } else {
      throw Exception("Temporary video file does not exist at $tempVideoPath");
    }
  }

  /// Saves a captured photo into persistent storage and returns permanent file path
  Future<String> persistPhoto(String tempPhotoPath) async {
    final photoDir = await getPhotoDirectory();
    final uniqueId = const Uuid().v4().substring(0, 8);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = p.extension(tempPhotoPath).isNotEmpty
        ? p.extension(tempPhotoPath)
        : '.jpg';
    final permanentFileName = 'photo_${timestamp}_$uniqueId$extension';
    final permanentPath = p.join(photoDir.path, permanentFileName);

    final tempFile = File(tempPhotoPath);
    if (await tempFile.exists()) {
      await tempFile.copy(permanentPath);
      try {
        await tempFile.delete();
      } catch (_) {}
      return permanentPath;
    } else {
      throw Exception("Temporary photo file does not exist at $tempPhotoPath");
    }
  }

  /// Deletes a media file (video or photo) from disk safely
  Future<bool> deleteMedia(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return false;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      // Log or ignore deletion error
    }
    return false;
  }

  /// Alias for deleteMedia for backward compatibility
  Future<bool> deleteVideo(String? filePath) => deleteMedia(filePath);

  /// Returns file size in readable format (e.g. 14.2 MB)
  Future<String> getFormattedFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.length();
        if (bytes < 1024 * 1024) {
          return '${(bytes / 1024).toStringAsFixed(1)} KB';
        }
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (_) {}
    return '0 MB';
  }
}
