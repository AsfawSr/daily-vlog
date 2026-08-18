import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Requests Camera and Microphone permissions required for video recording
  Future<bool> requestRecordingPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    return cameraStatus.isGranted && micStatus.isGranted;
  }

  /// Checks whether both camera and microphone are granted
  Future<bool> hasRecordingPermissions() async {
    final cameraGranted = await Permission.camera.isGranted;
    final micGranted = await Permission.microphone.isGranted;
    return cameraGranted && micGranted;
  }

  /// Opens app settings if user permanently denied permissions
  Future<bool> openSettings() async {
    return await openAppSettings();
  }
}
