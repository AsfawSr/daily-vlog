import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import '../models/activity_model.dart';
import '../services/database_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final DailyActivity activity;

  const VideoPlayerScreen({super.key, required this.activity});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showControls = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    if (widget.activity.videoPath == null) {
      setState(() => _hasError = true);
      return;
    }

    final file = File(widget.activity.videoPath!);
    if (!await file.exists()) {
      setState(() => _hasError = true);
      return;
    }

    _controller = VideoPlayerController.file(file)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
          _controller.play();
        }
      }).catchError((err) {
        if (mounted) {
          setState(() => _hasError = true);
        }
      });

    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('EEEE, MMM d, y • h:mm a').format(widget.activity.createdAt);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.activity.title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFEF4444)),
            onPressed: _showDeleteConfirm,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Video Viewport
            Expanded(
              child: Center(
                child: _hasError
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.broken_image_rounded,
                              color: Colors.white54, size: 54),
                          const SizedBox(height: 12),
                          Text(
                            'Video file not found or corrupted',
                            style: GoogleFonts.inter(color: Colors.white70),
                          ),
                        ],
                      )
                    : _isInitialized
                        ? GestureDetector(
                            onTap: () {
                              setState(() => _showControls = !_showControls);
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                AspectRatio(
                                  aspectRatio: _controller.value.aspectRatio,
                                  child: VideoPlayer(_controller),
                                ),
                                if (_showControls)
                                  Container(
                                    color: Colors.black38,
                                    child: Center(
                                      child: IconButton(
                                        iconSize: 64,
                                        icon: Icon(
                                          _controller.value.isPlaying
                                              ? Icons.pause_circle_filled_rounded
                                              : Icons.play_circle_fill_rounded,
                                          color: Colors.white.withValues(alpha: 0.9),
                                        ),
                                        onPressed: () {
                                          if (_controller.value.isPlaying) {
                                            _controller.pause();
                                          } else {
                                            _controller.play();
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : const CircularProgressIndicator(
                            color: Color(0xFF6366F1)),
              ),
            ),

            // Video Scrubber & Controls
            if (_isInitialized)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: const Color(0xFF6366F1),
                        inactiveTrackColor: Colors.white24,
                        thumbColor: const Color(0xFF818CF8),
                        trackHeight: 3.0,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6.0),
                      ),
                      child: Slider(
                        value: _controller.value.position.inMilliseconds
                            .toDouble()
                            .clamp(
                                0.0,
                                _controller.value.duration.inMilliseconds
                                    .toDouble()),
                        min: 0.0,
                        max: _controller.value.duration.inMilliseconds
                            .toDouble(),
                        onChanged: (val) {
                          _controller
                              .seekTo(Duration(milliseconds: val.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_controller.value.position),
                            style: GoogleFonts.inter(
                                color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            _formatDuration(_controller.value.duration),
                            style: GoogleFonts.inter(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Metadata & Details Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.activity.category,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF818CF8),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(widget.activity.moodEmoji,
                                style: const TextStyle(fontSize: 13)),
                            const SizedBox(width: 4),
                            Text(
                              widget.activity.mood,
                              style: GoogleFonts.inter(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formattedDate,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (widget.activity.description.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      widget.activity.description,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Delete Vlog Entry?',
            style: GoogleFonts.outfit(color: Colors.white)),
        content: Text(
          'This will permanently delete this activity and its associated video.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF818CF8))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await DatabaseService().deleteActivity(widget.activity.id);
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child:
                const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }
}
