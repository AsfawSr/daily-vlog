import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/activity_model.dart';
import '../services/database_service.dart';
import '../widgets/activity_card.dart';
import 'camera_recorder_screen.dart';
import 'create_activity_screen.dart';

class HomeTimelineScreen extends StatefulWidget {
  const HomeTimelineScreen({super.key});

  @override
  State<HomeTimelineScreen> createState() => _HomeTimelineScreenState();
}

class _HomeTimelineScreenState extends State<HomeTimelineScreen> {
  String _selectedCategory = 'All';

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      return 'Today • ${DateFormat('MMMM d').format(date)}';
    } else if (checkDate == yesterday) {
      return 'Yesterday • ${DateFormat('MMMM d').format(date)}';
    } else {
      return DateFormat('EEEE, MMMM d, y').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Brand & Stats
                      _buildHeader(),

                      const SizedBox(height: 20),

                      // Quick Action Bar (Camera Vlog & Activity Logger)
                      _buildQuickActionHero(),

                      const SizedBox(height: 22),

                      // Category Filter Chips
                      _buildCategoryFilter(),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: ValueListenableBuilder<Box>(
            valueListenable: DatabaseService().listenable,
            builder: (context, box, _) {
              final allActivities = DatabaseService().getAllActivities();
              final filtered = _selectedCategory == 'All'
                  ? allActivities
                  : allActivities
                      .where((a) =>
                          a.category.toLowerCase() ==
                          _selectedCategory.toLowerCase())
                      .toList();

              if (filtered.isEmpty) {
                return _buildEmptyState();
              }

              // Group activities by date
              final grouped = <DateTime, List<DailyActivity>>{};
              for (final act in filtered) {
                final dateKey = DateTime(
                    act.createdAt.year, act.createdAt.month, act.createdAt.day);
                if (!grouped.containsKey(dateKey)) {
                  grouped[dateKey] = [];
                }
                grouped[dateKey]!.add(act);
              }

              final sortedDates = grouped.keys.toList()
                ..sort((a, b) => b.compareTo(a));

              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  final date = sortedDates[index];
                  final activities = grouped[date]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Group Header
                      Padding(
                        padding: const EdgeInsets.only(top: 14, bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF6366F1),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDateHeader(date),
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF94A3B8),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${activities.length} ${activities.length == 1 ? 'entry' : 'entries'}',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF64748B),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Activities for this date
                      ...activities.map((activity) => ActivityCard(
                            key: ValueKey(activity.id),
                            activity: activity,
                          )),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Day Vlog',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('✨', style: TextStyle(fontSize: 20)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Capture moments, track progress',
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 13,
              ),
            ),
          ],
        ),
        // Live Activity Counter Badge
        ValueListenableBuilder<Box>(
          valueListenable: DatabaseService().listenable,
          builder: (context, box, _) {
            final count = box.length;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.movie_creation_outlined,
                      color: Color(0xFF818CF8), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '$count Logs',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Record Your Day',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34D399),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Ready',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Record a short video clip or write notes about your daily activity.',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Main Camera Record Button
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4F46E5),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.videocam_rounded, size: 20),
                  label: Text(
                    'Record Vlog',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CameraRecorderScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              // Secondary Quick Text Log Button
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white60, width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: Text(
                    'Quick Log',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CreateActivityScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return ValueListenableBuilder(
      valueListenable: DatabaseService().listenableCategories,
      builder: (context, box, child) {
        final categories = DatabaseService().getCategories();
        final filterItems = [
          {'name': 'All', 'icon': '✨'},
          ...categories,
        ];

        return SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: filterItems.length,
            itemBuilder: (context, index) {
              final cat = filterItems[index];
              final catName = cat['name']!;
              final isSelected =
                  _selectedCategory.toLowerCase() == catName.toLowerCase();

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (cat['icon'] != null && catName != 'All') ...[
                        Text(cat['icon']!, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        catName,
                        style: GoogleFonts.outfit(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF94A3B8),
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
                      setState(() => _selectedCategory = catName);
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.video_library_outlined,
                color: Color(0xFF818CF8),
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Activities Found',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCategory == 'All'
                  ? 'Your daily vlog timeline is empty.\nTap "Record Vlog" above to start your first video memory!'
                  : 'No activities found under the "$_selectedCategory" category.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
