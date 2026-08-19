import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import '../models/activity_model.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import 'camera_recorder_screen.dart';

class CreateActivityScreen extends StatefulWidget {
  final String? initialVideoPath;
  final int videoDurationSeconds;

  const CreateActivityScreen({
    super.key,
    this.initialVideoPath,
    this.videoDurationSeconds = 0,
  });

  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _videoPath;
  int _videoDuration = 0;
  VideoPlayerController? _videoPlayerController;
  bool _isSaving = false;

  late String _selectedCategory;
  late Map<String, String> _selectedMood;

  @override
  void initState() {
    super.initState();
    final initialCats = DatabaseService().getCategories();
    _selectedCategory = initialCats.isNotEmpty ? initialCats.first['name']! : 'Workout';
    
    final initialMoods = DatabaseService().getMoods();
    _selectedMood = initialMoods.isNotEmpty
        ? initialMoods.first
        : {'name': 'Happy', 'emoji': '😊'};

    _videoPath = widget.initialVideoPath;
    _videoDuration = widget.videoDurationSeconds;

    if (_videoPath != null) {
      _initMiniVideoPlayer(_videoPath!);
    }
  }

  void _initMiniVideoPlayer(String path) {
    _videoPlayerController?.dispose();
    _videoPlayerController = VideoPlayerController.file(File(path))
      ..initialize().then((_) {
        setState(() {});
        _videoPlayerController?.setLooping(true);
        _videoPlayerController?.play();
      });
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? savedPermanentVideoPath;

      if (_videoPath != null) {
        // Persist video to permanent app documents folder
        savedPermanentVideoPath =
            await StorageService().persistVideo(_videoPath!);
      }

      final activity = DailyActivity(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        mood: _selectedMood['name']!,
        moodEmoji: _selectedMood['emoji']!,
        videoPath: savedPermanentVideoPath,
        videoDurationSeconds: _videoDuration,
        createdAt: DateTime.now(),
      );

      await DatabaseService().saveActivity(activity);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  'Daily vlog entry logged successfully!',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Failed to save activity: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Log Daily Activity',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              onPressed: _isSaving ? null : _saveActivity,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded, color: Colors.white),
              label: Text(
                'Save',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video Preview Banner / Record Video Button
              _buildVideoPreviewSection(),

              const SizedBox(height: 24),

              // Title Field
              Text(
                'ACTIVITY TITLE',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Please enter a title' : null,
                decoration: InputDecoration(
                  hintText: 'e.g. Morning gym session, Deep work sprint...',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF475569)),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Mood Selector
              Text(
                'HOW DO YOU FEEL?',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              _buildMoodSelector(),

              const SizedBox(height: 24),

              // Category Selector
              Text(
                'CATEGORY',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              _buildCategorySelector(),

              const SizedBox(height: 24),

              // Notes / Thoughts Field
              Text(
                'NOTES & REFLECTIONS',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText:
                      'Write details about what you accomplished, learnings, or thoughts...',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF475569)),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPreviewSection() {
    if (_videoPath != null) {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_videoPlayerController != null &&
                _videoPlayerController!.value.isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoPlayerController!.value.size.width,
                  height: _videoPlayerController!.value.size.height,
                  child: VideoPlayer(_videoPlayerController!),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF6366F1)),
              ),

            // Top action buttons overlay
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                children: [
                  // Duration badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.videocam_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${_videoDuration}s',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Remove video button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _videoPath = null;
                        _videoDuration = 0;
                        _videoPlayerController?.pause();
                        _videoPlayerController?.dispose();
                        _videoPlayerController = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // No video attached: button to record
    return InkWell(
      onTap: () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CameraRecorderScreen()),
        );
        if (result != null && result is String) {
          setState(() {
            _videoPath = result;
          });
          _initMiniVideoPlayer(_videoPath!);
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF6366F1).withValues(alpha: 0.4),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.videocam_rounded,
                  color: Color(0xFF818CF8), size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Record Vlog Video Clip',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap to open camera and record',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSelector() {
    return ValueListenableBuilder(
      valueListenable: DatabaseService().listenableMoods,
      builder: (context, box, child) {
        final moods = DatabaseService().getMoods();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...moods.map((m) {
                final isSelected = _selectedMood['name']?.toLowerCase() ==
                    m['name']?.toLowerCase();
                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6366F1).withValues(alpha: 0.25)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF334155),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(m['emoji'] ?? '😊',
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          m['name'] ?? 'Happy',
                          style: GoogleFonts.outfit(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF94A3B8),
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              // "+ Custom" Mood Button
              GestureDetector(
                onTap: () => _showAddMoodDialog(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_rounded,
                          color: Color(0xFF818CF8), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Add Custom',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF818CF8),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddMoodDialog(BuildContext context) {
    final moodNameController = TextEditingController();
    String selectedEmoji = '😊';

    final moodEmojis = [
      '😊', '😌', '⚡', '🎯', '🔥', '🙏', '😴', '🤩', 
      '😍', '😎', '🥳', '😇', '🥺', '🤯', '🕊️', '🌟', 
      '🌈', '🍂', '🌧️', '💤', '🥊', '🧗', '🧘', '☕', 
      '🌻', '💖', '💪', '💯', '✨', '🏖️', '👑', '🎉',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Create Custom Mood',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HOW ARE YOU FEELING?',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: moodNameController,
                    autofocus: true,
                    style:
                        GoogleFonts.inter(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'e.g. Grateful, Hyped, Peaceful...',
                      hintStyle: GoogleFonts.inter(
                          color: const Color(0xFF64748B), fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF6366F1), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'CHOOSE MOOD EMOJI',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: moodEmojis.map((emoji) {
                      final isSelected = selectedEmoji == emoji;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() => selectedEmoji = emoji);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF6366F1).withValues(alpha: 0.35)
                                : const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF6366F1)
                                  : const Color(0xFF334155),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(emoji,
                              style: const TextStyle(fontSize: 20)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Cancel',
                    style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final name = moodNameController.text.trim();
                  if (name.isNotEmpty) {
                    await DatabaseService().addMood(name, selectedEmoji);
                    if (mounted) {
                      setState(() {
                        _selectedMood = {'name': name, 'emoji': selectedEmoji};
                      });
                    }
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                    }
                  }
                },
                child: Text(
                  'Add Mood',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategorySelector() {
    return ValueListenableBuilder(
      valueListenable: DatabaseService().listenableCategories,
      builder: (context, box, child) {
        final categories = DatabaseService().getCategories();

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...categories.map((cat) {
              final isSelected = _selectedCategory.toLowerCase() == cat['name']!.toLowerCase();
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(cat['icon']!, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      cat['name']!,
                      style: GoogleFonts.outfit(
                        color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF6366F1),
                backgroundColor: const Color(0xFF1E293B),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF334155),
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedCategory = cat['name']!);
                  }
                },
              );
            }),
            // "+ Add Custom" Category Button
            ActionChip(
              avatar: const Icon(Icons.add_rounded,
                  color: Color(0xFF818CF8), size: 18),
              label: Text(
                'Add Custom',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF818CF8),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
              side: BorderSide(
                color: const Color(0xFF6366F1).withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onPressed: () => _showAddCategoryDialog(context),
            ),
          ],
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final catNameController = TextEditingController();
    String selectedEmoji = '✨';

    final popularEmojis = [
      '✨', '🧘', '🎸', '🎮', '🚴', '🏊', '🍕', '🎬', 
      '💡', '📝', '🚀', '🎯', '🎧', '🐶', '☀️', '🛠️', 
      '☕', '📖', '🧪', '🌿', '🌱', '🧁', '⚽', '🚗',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Create Custom Category',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CATEGORY NAME',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: catNameController,
                    autofocus: true,
                    style:
                        GoogleFonts.inter(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'e.g. Meditation, Guitar, Cooking...',
                      hintStyle: GoogleFonts.inter(
                          color: const Color(0xFF64748B), fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFF6366F1), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'PICK AN ICON / EMOJI',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: popularEmojis.map((emoji) {
                      final isSelected = selectedEmoji == emoji;
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() => selectedEmoji = emoji);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF6366F1).withValues(alpha: 0.35)
                                : const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF6366F1)
                                  : const Color(0xFF334155),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(emoji,
                              style: const TextStyle(fontSize: 20)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Cancel',
                    style: GoogleFonts.inter(color: const Color(0xFF94A3B8))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final name = catNameController.text.trim();
                  if (name.isNotEmpty) {
                    await DatabaseService().addCategory(name, selectedEmoji);
                    if (mounted) {
                      setState(() {
                        _selectedCategory = name;
                      });
                    }
                    if (ctx.mounted) {
                      Navigator.of(ctx).pop();
                    }
                  }
                },
                child: Text(
                  'Add Category',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

