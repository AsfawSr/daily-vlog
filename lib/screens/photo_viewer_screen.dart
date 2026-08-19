import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gal/gal.dart';
import '../models/activity_model.dart';
import '../services/database_service.dart';

class PhotoViewerScreen extends StatefulWidget {
  final DailyActivity activity;

  const PhotoViewerScreen({super.key, required this.activity});

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  bool _isSavingToGallery = false;

  Future<void> _saveToGallery() async {
    if (widget.activity.mediaPath == null) return;
    final file = File(widget.activity.mediaPath!);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFEF4444),
            content: Text('Photo file not found on disk.'),
          ),
        );
      }
      return;
    }

    setState(() => _isSavingToGallery = true);
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }
      await Gal.putImage(widget.activity.mediaPath!, album: 'Day Vlog');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Photo saved to your Gallery album "Day Vlog"!',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } on GalException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Failed to save to gallery: ${e.type.message}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Error saving to gallery: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingToGallery = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('EEEE, MMM d, y • h:mm a').format(widget.activity.createdAt);
    final photoFile = widget.activity.mediaPath != null
        ? File(widget.activity.mediaPath!)
        : null;

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
          // Save Photo to Gallery Button
          IconButton(
            tooltip: 'Download Photo to Gallery',
            icon: _isSavingToGallery
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.file_download_outlined,
                    color: Colors.white, size: 24),
            onPressed: _isSavingToGallery ? null : _saveToGallery,
          ),
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
            // Interactive Photo Viewport with Pinch to Zoom
            Expanded(
              child: Center(
                child: photoFile != null && photoFile.existsSync()
                    ? InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 4.0,
                        child: Image.file(
                          photoFile,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.broken_image_rounded,
                              color: Colors.white54, size: 54),
                          const SizedBox(height: 12),
                          Text(
                            'Photo file not found on disk',
                            style: GoogleFonts.inter(color: Colors.white70),
                          ),
                        ],
                      ),
              ),
            ),

            // Metadata & Details Section with Export Button
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
                          color:
                              const Color(0xFF3B82F6).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.activity.category,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF60A5FA),
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
                  const SizedBox(height: 16),
                  // Save Photo to Gallery Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color:
                              const Color(0xFF3B82F6).withValues(alpha: 0.6),
                        ),
                        backgroundColor:
                            const Color(0xFF3B82F6).withValues(alpha: 0.12),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _isSavingToGallery
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.download_rounded, size: 18),
                      label: Text(
                        _isSavingToGallery
                            ? 'Saving to Gallery...'
                            : 'Save Photo to Phone Gallery',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: _isSavingToGallery ? null : _saveToGallery,
                    ),
                  ),
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
        title: Text('Delete Photo Entry?',
            style: GoogleFonts.outfit(color: Colors.white)),
        content: Text(
          'This will permanently delete this photo journal entry and image file.',
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
