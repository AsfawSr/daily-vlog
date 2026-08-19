import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:gal/gal.dart';
import '../models/activity_model.dart';
import '../screens/video_player_screen.dart';
import '../screens/photo_viewer_screen.dart';
import '../services/database_service.dart';

class ActivityCard extends StatelessWidget {
  final DailyActivity activity;

  const ActivityCard({super.key, required this.activity});

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'workout':
        return const Color(0xFFEF4444);
      case 'work':
        return const Color(0xFF3B82F6);
      case 'study':
        return const Color(0xFF8B5CF6);
      case 'creative':
        return const Color(0xFFEC4899);
      case 'travel':
        return const Color(0xFF10B981);
      case 'food':
        return const Color(0xFFF59E0B);
      case 'coding':
        return const Color(0xFF06B6D4);
      case 'life':
        return const Color(0xFF14B8A6);
      case 'morning routine':
        return const Color(0xFFF97316);
      case 'reading':
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryColor(activity.category);
    final hasVideo = activity.hasVideo;
    final hasPhoto = activity.hasPhoto;
    final hasMedia = activity.hasMedia;
    final formattedTime = DateFormat('h:mm a').format(activity.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF334155).withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (hasVideo) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => VideoPlayerScreen(activity: activity),
                ),
              );
            } else if (hasPhoto) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PhotoViewerScreen(activity: activity),
                ),
              );
            } else {
              _showActivityDetailsDialog(context);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag Bar
                Row(
                  children: [
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        activity.category.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: catColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Mood Emoji Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${activity.moodEmoji} ${activity.mood}',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Timestamp
                    Text(
                      formattedTime,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    // More Menu (Save to Gallery & Delete)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded,
                          color: Color(0xFF64748B), size: 18),
                      padding: EdgeInsets.zero,
                      color: const Color(0xFF0F172A),
                      onSelected: (val) {
                        if (val == 'download') {
                          _saveMediaToGallery(context);
                        } else if (val == 'delete') {
                          _confirmDelete(context);
                        }
                      },
                      itemBuilder: (ctx) => [
                        if (hasMedia)
                          PopupMenuItem(
                            value: 'download',
                            child: Row(
                              children: [
                                const Icon(Icons.file_download_outlined,
                                    color: Color(0xFF818CF8), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  hasPhoto
                                      ? (activity.photoCount > 1
                                          ? 'Save ${activity.photoCount} Photos'
                                          : 'Save Photo')
                                      : 'Save Video',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  color: Color(0xFFEF4444), size: 18),
                              SizedBox(width: 8),
                              Text('Delete',
                                  style: TextStyle(color: Color(0xFFEF4444))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  activity.title,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                if (activity.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    activity.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF94A3B8),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Media Indicator Bar (Video or Multi-Photo)
                if (hasVideo)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF6366F1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Watch Vlog Clip',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if (activity.videoDurationSeconds > 0)
                              Text(
                                '${activity.videoDurationSeconds}s duration',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF64748B),
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            color: Color(0xFF64748B), size: 12),
                      ],
                    ),
                  )
                else if (hasPhoto)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            activity.hasMultiplePhotos
                                ? Icons.photo_library_rounded
                                : Icons.photo_camera_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.hasMultiplePhotos
                                  ? 'View ${activity.photoCount} Photos'
                                  : 'View Photo Memory',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if (activity.hasMultiplePhotos)
                              Text(
                                'Swipe to view album',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF64748B),
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios_rounded,
                            color: Color(0xFF64748B), size: 12),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showActivityDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Text(activity.moodEmoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                activity.title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${activity.category} • ${activity.mood}',
              style: GoogleFonts.outfit(
                color: const Color(0xFF818CF8),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              activity.description.isNotEmpty
                  ? activity.description
                  : 'No extra notes provided for this activity.',
              style: GoogleFonts.inter(color: Colors.white70, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: Color(0xFF6366F1))),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Delete Activity?',
            style: GoogleFonts.outfit(color: Colors.white)),
        content: Text('Are you sure you want to delete "${activity.title}"?',
            style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF818CF8))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await DatabaseService().deleteActivity(activity.id);
            },
            child:
                const Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMediaToGallery(BuildContext context) async {
    final paths = activity.photoPaths.isNotEmpty
        ? activity.photoPaths
        : (activity.mediaPath != null ? [activity.mediaPath!] : <String>[]);

    if (paths.isEmpty) return;

    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      int savedCount = 0;
      for (final p in paths) {
        final file = File(p);
        if (await file.exists()) {
          if (activity.hasPhoto) {
            await Gal.putImage(p, album: 'Day Vlog');
          } else {
            await Gal.putVideo(p, album: 'Day Vlog');
          }
          savedCount++;
        }
      }

      if (context.mounted) {
        final msg = activity.hasPhoto
            ? (savedCount > 1
                ? 'Saved $savedCount photos to Gallery album "Day Vlog"!'
                : 'Saved "${activity.title}" photo to Gallery album "Day Vlog"!')
            : 'Saved "${activity.title}" video to Gallery album "Day Vlog"!';

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
                    msg,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } on GalException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Failed to save to gallery: ${e.type.message}'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Error saving to gallery: $e'),
          ),
        );
      }
    }
  }
}
