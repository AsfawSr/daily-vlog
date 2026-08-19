import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/camera_service.dart';
import '../services/permission_service.dart';
import 'create_activity_screen.dart';

enum CameraMode { video, photo }

class CameraRecorderScreen extends StatefulWidget {
  final CameraMode initialMode;

  const CameraRecorderScreen({
    super.key,
    this.initialMode = CameraMode.video,
  });

  @override
  State<CameraRecorderScreen> createState() => _CameraRecorderScreenState();
}

class _CameraRecorderScreenState extends State<CameraRecorderScreen>
    with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  bool _hasPermissions = false;
  bool _isCheckingPermissions = true;
  bool _isProcessingMedia = false;
  late CameraMode _currentMode;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
    WidgetsBinding.instance.addObserver(this);
    _cameraService.addListener(_onCameraStateChanged);
    _checkAndInitCamera();
  }

  void _onCameraStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_hasPermissions || _cameraService.controller == null) return;

    if (state == AppLifecycleState.inactive) {
      _cameraService.controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _cameraService.initializeCameras();
    }
  }

  Future<void> _checkAndInitCamera() async {
    setState(() => _isCheckingPermissions = true);
    final granted = await PermissionService().hasRecordingPermissions();
    if (granted) {
      setState(() {
        _hasPermissions = true;
        _isCheckingPermissions = false;
      });
      await _cameraService.initializeCameras();
    } else {
      final requestResult =
          await PermissionService().requestRecordingPermissions();
      setState(() {
        _hasPermissions = requestResult;
        _isCheckingPermissions = false;
      });
      if (requestResult) {
        await _cameraService.initializeCameras();
      }
    }
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _onShutterPressed() async {
    if (_currentMode == CameraMode.photo) {
      // Take Photo
      setState(() => _isProcessingMedia = true);
      final photoFile = await _cameraService.takePicture();
      setState(() => _isProcessingMedia = false);

      if (photoFile != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => CreateActivityScreen(
              initialMediaPath: photoFile.path,
              mediaType: 'photo',
            ),
          ),
        );
      }
    } else {
      // Video Recording
      if (!_cameraService.isRecording) {
        await _cameraService.startRecording();
      } else {
        setState(() => _isProcessingMedia = true);
        final duration = _cameraService.recordDurationSeconds;
        final videoFile = await _cameraService.stopRecording();
        setState(() => _isProcessingMedia = false);

        if (videoFile != null && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => CreateActivityScreen(
                initialMediaPath: videoFile.path,
                mediaType: 'video',
                videoDurationSeconds: duration > 0 ? duration : 1,
              ),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.removeListener(_onCameraStateChanged);
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPermissions) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );
    }

    if (!_hasPermissions) {
      return _buildPermissionDeniedView();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview Viewfinder
          if (_cameraService.isInitialized &&
              _cameraService.controller != null)
            Center(
              child: CameraPreview(_cameraService.controller!),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            ),

          // Top Gradient Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Bottom Gradient Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.95),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Top Action Bar
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close Button
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 28),
                      onPressed: () {
                        if (_cameraService.isRecording) {
                          _showExitConfirmDialog();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                    ),

                    // Recording Duration Badge (Video) / Mode Header
                    if (_cameraService.isRecording)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDuration(
                                  _cameraService.recordDurationSeconds),
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        _currentMode == CameraMode.photo
                            ? 'DAY VLOG PHOTO'
                            : 'DAY VLOG VIDEO',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          letterSpacing: 2,
                        ),
                      ),

                    // Flash Toggle
                    IconButton(
                      icon: Icon(
                        _cameraService.flashMode == FlashMode.torch
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        color: _cameraService.flashMode == FlashMode.torch
                            ? const Color(0xFFFBBF24)
                            : Colors.white,
                        size: 26,
                      ),
                      onPressed: _cameraService.toggleFlash,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Control Panel
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0, left: 24, right: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mode Selector Bar (PHOTO / VIDEO)
                    if (!_cameraService.isRecording)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildModeTab('PHOTO', CameraMode.photo),
                            const SizedBox(width: 4),
                            _buildModeTab('VIDEO', CameraMode.video),
                          ],
                        ),
                      ),

                    // Shutter & Side Actions Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Action: Pause/Resume (when recording) OR Quick Note
                        if (_cameraService.isRecording)
                          IconButton(
                            iconSize: 32,
                            icon: Icon(
                              _cameraService.isPaused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                              color: Colors.white,
                            ),
                            onPressed: _cameraService.isPaused
                                ? _cameraService.resumeRecording
                                : _cameraService.pauseRecording,
                          )
                        else
                          IconButton(
                            iconSize: 28,
                            icon: const Icon(Icons.edit_note_rounded,
                                color: Colors.white70),
                            tooltip: 'Log note without camera',
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const CreateActivityScreen(),
                                ),
                              );
                            },
                          ),

                        // Shutter / Capture Button
                        GestureDetector(
                          onTap: _isProcessingMedia ? null : _onShutterPressed,
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _cameraService.isRecording
                                    ? const Color(0xFFEF4444)
                                    : Colors.white,
                                width: 4,
                              ),
                            ),
                            child: Center(
                              child: _isProcessingMedia
                                  ? const CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 3)
                                  : AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      width: _cameraService.isRecording
                                          ? 32
                                          : (_currentMode == CameraMode.photo
                                              ? 68
                                              : 64),
                                      height: _cameraService.isRecording
                                          ? 32
                                          : (_currentMode == CameraMode.photo
                                              ? 68
                                              : 64),
                                      decoration: BoxDecoration(
                                        color: _cameraService.isRecording
                                            ? const Color(0xFFEF4444)
                                            : (_currentMode == CameraMode.photo
                                                ? Colors.white
                                                : const Color(0xFF6366F1)),
                                        borderRadius: BorderRadius.circular(
                                            _cameraService.isRecording ? 8 : 40),
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        // Switch Camera Lens (Front / Rear)
                        IconButton(
                          iconSize: 32,
                          icon: const Icon(Icons.flip_camera_ios_rounded,
                              color: Colors.white),
                          onPressed: _cameraService.isRecording
                              ? null
                              : _cameraService.toggleCamera,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(String label, CameraMode mode) {
    final isSelected = _currentMode == mode;
    return GestureDetector(
      onTap: () {
        if (!_cameraService.isRecording) {
          setState(() => _currentMode = mode);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? Colors.white : Colors.white60,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedView() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.videocam_off_rounded,
                  color: Color(0xFF6366F1),
                  size: 46,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Camera & Mic Access Required',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'To capture your daily vlog memories and photos, please allow Day Vlog access to your device camera and microphone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.lock_open_rounded),
                label: Text(
                  'Grant Permissions',
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600, fontSize: 16),
                ),
                onPressed: _checkAndInitCamera,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => PermissionService().openSettings(),
                child: Text(
                  'Open App Settings',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF818CF8),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Discard Recording?',
            style: GoogleFonts.outfit(color: Colors.white)),
        content: Text(
          'You are currently recording. Leaving now will discard your current clip.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Recording',
                style: TextStyle(color: Color(0xFF818CF8))),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child:
                const Text('Discard', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }
}
