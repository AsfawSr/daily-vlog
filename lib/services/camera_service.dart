import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService extends ChangeNotifier {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isPaused = false;
  FlashMode _flashMode = FlashMode.off;

  Timer? _timer;
  int _recordDurationSeconds = 0;

  List<CameraDescription> get cameras => _cameras;
  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized && _controller != null && _controller!.value.isInitialized;
  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  int get recordDurationSeconds => _recordDurationSeconds;
  FlashMode get flashMode => _flashMode;
  bool get hasMultipleCameras => _cameras.length > 1;
  CameraLensDirection get currentLensDirection =>
      _cameras.isNotEmpty ? _cameras[_selectedCameraIndex].lensDirection : CameraLensDirection.back;

  Future<void> initializeCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        // Prefer back camera initially
        _selectedCameraIndex = _cameras.indexWhere(
            (c) => c.lensDirection == CameraLensDirection.back);
        if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;

        await _initController(_cameras[_selectedCameraIndex]);
      }
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  Future<void> _initController(CameraDescription description) async {
    await _controller?.dispose();
    _controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      _isInitialized = true;
      _flashMode = FlashMode.off;
      notifyListeners();
    } catch (e) {
      debugPrint("Error initializing camera controller: $e");
      _isInitialized = false;
      notifyListeners();
    }
  }

  Future<void> toggleCamera() async {
    if (_cameras.length < 2 || _isRecording) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _initController(_cameras[_selectedCameraIndex]);
  }

  Future<void> toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      if (_flashMode == FlashMode.off) {
        _flashMode = FlashMode.torch;
      } else {
        _flashMode = FlashMode.off;
      }
      await _controller!.setFlashMode(_flashMode);
      notifyListeners();
    } catch (e) {
      debugPrint("Error setting flash mode: $e");
    }
  }

  Future<void> startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized || _isRecording) {
      return;
    }

    try {
      await _controller!.startVideoRecording();
      _isRecording = true;
      _isPaused = false;
      _recordDurationSeconds = 0;
      _startTimer();
      notifyListeners();
    } catch (e) {
      debugPrint("Error starting video recording: $e");
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        _recordDurationSeconds++;
        notifyListeners();
      }
    });
  }

  Future<void> pauseRecording() async {
    if (_controller != null && _isRecording && !_isPaused) {
      try {
        await _controller!.pauseVideoRecording();
        _isPaused = true;
        notifyListeners();
      } catch (e) {
        debugPrint("Error pausing video recording: $e");
      }
    }
  }

  Future<void> resumeRecording() async {
    if (_controller != null && _isRecording && _isPaused) {
      try {
        await _controller!.resumeVideoRecording();
        _isPaused = false;
        notifyListeners();
      } catch (e) {
        debugPrint("Error resuming video recording: $e");
      }
    }
  }

  Future<XFile?> stopRecording() async {
    if (_controller == null || !_isRecording) return null;

    try {
      _timer?.cancel();
      final file = await _controller!.stopVideoRecording();
      _isRecording = false;
      _isPaused = false;
      notifyListeners();
      return file;
    } catch (e) {
      debugPrint("Error stopping video recording: $e");
      _isRecording = false;
      _timer?.cancel();
      notifyListeners();
      return null;
    }
  }

  Future<XFile?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isRecording) {
      return null;
    }

    try {
      final file = await _controller!.takePicture();
      return file;
    } catch (e) {
      debugPrint("Error taking picture: $e");
      return null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }
}
