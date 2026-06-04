import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/user/data/profile_repository.dart';
import '../features/user/data/stats_repository.dart';
import '../features/user/domain/user.dart';
import '../features/library/presentation/library_providers.dart';
import '../features/library/domain/user_book.dart';
import '../features/gamification/presentation/gamification_providers.dart';
import '../features/gamification/domain/achievement.dart';
import '../theme/app_theme.dart';
import '../routing/app_router.dart';

// ─── Top-level color palette for charts ───────────────────────────────────────
const _chartColors = [
  Color(0xFF2D6A4F),
  Color(0xFF40916C),
  Color(0xFF52B788),
  Color(0xFF74C69D),
  Color(0xFF95D5B2),
  Color(0xFFB7E4C7),
  Color(0xFF4A4A5A),
  Color(0xFF8A7B6A),
];

// ─── Archetype gradient palettes ──────────────────────────────────────────────
Color _archetypeGradientStart(String? archetype) {
  switch (archetype) {
    case 'the_explorer':
      return const Color(0xFF2D6A4F);
    case 'the_scholar':
      return const Color(0xFF1A2744);
    case 'the_dreamer':
      return const Color(0xFF2C1654);
    case 'the_detective':
      return const Color(0xFF1A2744);
    case 'the_romantic':
      return const Color(0xFF6B2737);
    case 'the_philosopher':
      return const Color(0xFF1C3A3A);
    case 'the_speedster':
      return const Color(0xFF7B3A1C);
    case 'the_curator':
      return const Color(0xFF3A2C5A);
    default:
      return const Color(0xFF061B0E);
  }
}

Color _archetypeGradientEnd(String? archetype) {
  switch (archetype) {
    case 'the_explorer':
      return const Color(0xFF40916C);
    case 'the_scholar':
      return const Color(0xFF2A3F6B);
    case 'the_dreamer':
      return const Color(0xFF4A2880);
    case 'the_detective':
      return const Color(0xFF1E3A5F);
    case 'the_romantic':
      return const Color(0xFF8B3A52);
    case 'the_philosopher':
      return const Color(0xFF2A5050);
    case 'the_speedster':
      return const Color(0xFFB35A30);
    case 'the_curator':
      return const Color(0xFF5A3A8A);
    default:
      return const Color(0xFF0A2012);
  }
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading profile: $err')),
        data: (user) => _ProfileBody(user: user),
      ),
    );
  }
}

// ─── Profile Body ─────────────────────────────────────────────────────────────

class _ProfileBody extends ConsumerWidget {
  final User user;
  const _ProfileBody({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(myReadingStatsProvider);
    final libraryAsync = ref.watch(libraryProvider);
    final historyAsync = ref.watch(dailyReadingHistoryProvider);
    final genreAsync = ref.watch(genreStatsProvider);

    // XP calculation
    final int currentLevel = user.level;
    final int nextLevelXp = ((currentLevel + 1) * (currentLevel + 1) * 50);
    final int currentLevelXp = (currentLevel * currentLevel * 50);
    final int xpProgress = (user.points - currentLevelXp).clamp(
      0,
      nextLevelXp - currentLevelXp,
    );
    final int xpNeeded = nextLevelXp - currentLevelXp;
    final double xpPercent = xpNeeded > 0
        ? (xpProgress / xpNeeded).clamp(0.0, 1.0)
        : 0.0;

    // Library counts
    final int readingCount =
        libraryAsync.whenOrNull(
          data: (books) =>
              books.where((b) => b.status == ReadingStatus.reading).length,
        ) ??
        0;
    final int finishedCount =
        libraryAsync.whenOrNull(
          data: (books) =>
              books.where((b) => b.status == ReadingStatus.read).length,
        ) ??
        0;
    final int toReadCount =
        libraryAsync.whenOrNull(
          data: (books) =>
              books.where((b) => b.status == ReadingStatus.toRead).length,
        ) ??
        0;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myProfileProvider);
        ref.invalidate(myReadingStatsProvider);
        ref.invalidate(dailyReadingHistoryProvider);
        ref.invalidate(genreStatsProvider);
      },
      child: CustomScrollView(
        slivers: [
          // ── 1. Hero Header ────────────────────────────────────────────────
          SliverToBoxAdapter(child: _HeroHeader(user: user)),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── 2. XP Progress Card ──────────────────────────────────
                _XpCard(
                  currentLevel: currentLevel,
                  xpProgress: xpProgress,
                  xpNeeded: xpNeeded,
                  xpPercent: xpPercent,
                  totalPoints: user.points,
                  streak: user.currentStreak,
                ),

                const SizedBox(height: 16),

                // ── 3. Library Snapshot ──────────────────────────────────
                _LibrarySnapshotRow(
                  reading: readingCount,
                  finished: finishedCount,
                  toRead: toReadCount,
                ),

                const SizedBox(height: 24),

                // ── 4. Reading Analytics ─────────────────────────────────
                _SectionHeader(
                  icon: Icons.insights_rounded,
                  title: 'Reading Analytics',
                ),
                const SizedBox(height: 12),

                // 4a. Lifetime stats strip
                statsAsync.when(
                  loading: () => const _SkeletonCard(height: 72),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (stats) => _LifetimeStatsStrip(stats: stats),
                ),

                const SizedBox(height: 12),

                // 4b. 30-Day Activity Bar Chart
                historyAsync.when(
                  loading: () => const _SkeletonCard(height: 200),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (history) => _ActivityBarChart(history: history),
                ),

                const SizedBox(height: 12),

                // 4c. Genre Donut Chart
                genreAsync.when(
                  loading: () => const _SkeletonCard(height: 240),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (genres) => genres.isEmpty
                      ? const SizedBox.shrink()
                      : _GenreDonutChart(genres: genres),
                ),

                const SizedBox(height: 24),

                // ── 5. Achievements ──────────────────────────────────────
                _SectionHeader(
                  icon: Icons.emoji_events_rounded,
                  title: 'Achievements & Badges',
                ),
                const SizedBox(height: 12),
                _AchievementsSection(),
                const SizedBox(height: 8),
                _BadgesSection(),

                const SizedBox(height: 24),

                // ── 6. Reader Profile ────────────────────────────────────
                _SectionHeader(
                  icon: Icons.person_rounded,
                  title: 'Reader Profile',
                ),
                const SizedBox(height: 12),
                _ReaderProfileCard(user: user),

                const SizedBox(height: 24),

                // ── 7. Account Settings ──────────────────────────────────
                _SectionHeader(
                  icon: Icons.manage_accounts_rounded,
                  title: 'Account',
                ),
                const SizedBox(height: 12),
                _AccountCard(user: user, ref: ref),

                const SizedBox(height: 110),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 1. Hero Header ───────────────────────────────────────────────────────────

class _HeroHeader extends ConsumerWidget {
  final User user;
  const _HeroHeader({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gradStart = _archetypeGradientStart(user.readerArchetype);
    final gradEnd = _archetypeGradientEnd(user.readerArchetype);
    final archName = _archetypeDisplayName(user.readerArchetype);
    final archIcon = _archetypeIcon(user.readerArchetype);

    return Stack(
      children: [
        // Background gradient
        Container(
          height: 260,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [gradStart, gradEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // Subtle noise / texture overlay
        Container(
          height: 260,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withAlpha(10),
                Colors.transparent,
                Colors.black.withAlpha(30),
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
        ),

        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top action row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox.shrink(),
                    Row(
                      children: [
                        _HeroIconBtn(
                          icon: Icons.calendar_month_outlined,
                          onTap: () => context.push('/calendar'),
                        ),
                        const SizedBox(width: 8),
                        _HeroIconBtn(
                          icon: Icons.edit_outlined,
                          onTap: () => context.go(
                            '/profile/edit',
                            extra: {
                              'displayName': user.displayName,
                              'bio': user.bio,
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Avatar + name row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Avatar with ring
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withAlpha(100),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white.withAlpha(30),
                        backgroundImage: (user.avatarUrl?.isNotEmpty == true)
                            ? CachedNetworkImageProvider(user.avatarUrl!)
                            : null,
                        child: (user.avatarUrl?.isNotEmpty != true)
                            ? Text(
                                user.displayName.isNotEmpty
                                    ? user.displayName[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.notoSerif(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Name + username + bio
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: GoogleFonts.notoSerif(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${user.username}',
                            style: GoogleFonts.inter(
                              color: Colors.white.withAlpha(180),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (user.bio != null && user.bio!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              user.bio!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: Colors.white.withAlpha(160),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Archetype pill (if set)
                if (user.readerArchetype != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: Colors.white.withAlpha(60),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(archIcon, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          archName,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeroIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(25),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withAlpha(60), width: 1),
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }
}

// ─── 2. XP Progress Card ──────────────────────────────────────────────────────

class _XpCard extends StatelessWidget {
  final int currentLevel;
  final int xpProgress;
  final int xpNeeded;
  final double xpPercent;
  final int totalPoints;
  final int streak;

  const _XpCard({
    required this.currentLevel,
    required this.xpProgress,
    required this.xpNeeded,
    required this.xpPercent,
    required this.totalPoints,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Level badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: AppTheme.onPrimary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Level $currentLevel',
                      style: GoogleFonts.inter(
                        color: AppTheme.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Streak badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Color(0xFFE67E22),
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$streak day streak',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFB7470C),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '$totalPoints XP',
                style: GoogleFonts.inter(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level $currentLevel → ${currentLevel + 1}',
                style: GoogleFonts.inter(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              Text(
                '$xpProgress / $xpNeeded XP',
                style: GoogleFonts.inter(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Segmented-style XP bar
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: xpPercent),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: AppTheme.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 3. Library Snapshot Row ──────────────────────────────────────────────────

class _LibrarySnapshotRow extends StatelessWidget {
  final int reading;
  final int finished;
  final int toRead;
  const _LibrarySnapshotRow({
    required this.reading,
    required this.finished,
    required this.toRead,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: reading,
            label: 'Reading',
            icon: Icons.menu_book_rounded,
            accentColor: const Color(0xFF2D6A4F),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: finished,
            label: 'Finished',
            icon: Icons.check_circle_rounded,
            accentColor: const Color(0xFF40916C),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: toRead,
            label: 'To Read',
            icon: Icons.bookmarks_rounded,
            accentColor: AppTheme.secondary,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color accentColor;

  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: accentColor.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withAlpha(40), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: accentColor, size: 22),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: GoogleFonts.notoSerif(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppTheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 4a. Lifetime Stats Strip ─────────────────────────────────────────────────

class _LifetimeStatsStrip extends StatelessWidget {
  final ReadingStats stats;
  const _LifetimeStatsStrip({required this.stats});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MiniStat(
            value: '${stats.totalPages}',
            label: 'Pages',
            icon: Icons.article_rounded,
          ),
          _Divider(),
          _MiniStat(
            value: '${stats.totalHours}h',
            label: 'Hours',
            icon: Icons.schedule_rounded,
          ),
          _Divider(),
          _MiniStat(
            value: '${stats.totalSessions}',
            label: 'Sessions',
            icon: Icons.self_improvement_rounded,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _MiniStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.notoSerif(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: AppTheme.outlineVariant.withAlpha(80),
    );
  }
}

// ─── 4b. 30-Day Activity Bar Chart ────────────────────────────────────────────

class _ActivityBarChart extends StatefulWidget {
  final List<ReadingDayEntry> history;
  const _ActivityBarChart({required this.history});

  @override
  State<_ActivityBarChart> createState() => _ActivityBarChartState();
}

class _ActivityBarChartState extends State<_ActivityBarChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final maxPages = widget.history.fold<int>(
      1,
      (prev, e) => math.max(prev, e.pagesRead),
    );

    // Show only every 5th label to avoid overlap (30 bars total)
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '30-Day Activity',
                style: GoogleFonts.notoSerif(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              Text(
                'Pages read per day',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: (maxPages * 1.25).ceilToDouble(),
                barTouchData: BarTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (response?.spot == null ||
                          event is FlTapUpEvent ||
                          event is FlLongPressEnd) {
                        _touchedIndex = null;
                      } else {
                        _touchedIndex = response!.spot!.touchedBarGroupIndex;
                      }
                    });
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.primary,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final entry = widget.history[groupIndex];
                      final date = DateFormat('MMM d').format(entry.date);
                      return BarTooltipItem(
                        '$date\n',
                        GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text: '${entry.pagesRead} pages',
                            style: GoogleFonts.inter(
                              color: Colors.white.withAlpha(220),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: maxPages > 0
                          ? (maxPages / 3).ceilToDouble()
                          : 1,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          '${value.toInt()}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        // Show every 5th date
                        if (idx % 5 != 0 || idx >= widget.history.length) {
                          return const SizedBox.shrink();
                        }
                        final date = widget.history[idx].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('M/d').format(date),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxPages > 0
                      ? (maxPages / 3).ceilToDouble()
                      : 1,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.outlineVariant.withAlpha(60),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                barGroups: List.generate(widget.history.length, (i) {
                  final entry = widget.history[i];
                  final isTouched = _touchedIndex == i;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: entry.pagesRead.toDouble(),
                        color: isTouched
                            ? const Color(0xFF40916C)
                            : entry.pagesRead > 0
                            ? const Color(0xFF2D6A4F)
                            : AppTheme.surfaceContainerHighest,
                        width: 6,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                    ],
                  );
                }),
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            ),
          ),
          // Summary row below chart
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ChartLegendDot(color: const Color(0xFF2D6A4F)),
              const SizedBox(width: 6),
              Text(
                'Pages read',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              _ChartLegendDot(color: AppTheme.surfaceContainerHighest),
              const SizedBox(width: 6),
              Text(
                'No activity',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartLegendDot extends StatelessWidget {
  final Color color;
  const _ChartLegendDot({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

// ─── 4c. Genre Donut Chart ────────────────────────────────────────────────────

class _GenreDonutChart extends StatefulWidget {
  final List<GenreStat> genres;
  const _GenreDonutChart({required this.genres});

  @override
  State<_GenreDonutChart> createState() => _GenreDonutChartState();
}

class _GenreDonutChartState extends State<_GenreDonutChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final total = widget.genres.fold<int>(0, (sum, g) => sum + g.count);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reading by Genre',
            style: GoogleFonts.notoSerif(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),
          Text(
            'Based on finished books',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Donut chart + center label overlay, correctly stacked
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  response?.touchedSection == null) {
                                _touchedIndex = null;
                              } else {
                                _touchedIndex = response!
                                    .touchedSection!
                                    .touchedSectionIndex;
                              }
                            });
                          },
                        ),
                        sectionsSpace: 2,
                        centerSpaceRadius: 46,
                        startDegreeOffset: -90,
                        sections: List.generate(widget.genres.length, (i) {
                          final genre = widget.genres[i];
                          final isTouched = _touchedIndex == i;
                          return PieChartSectionData(
                            color: _chartColors[i % _chartColors.length],
                            value: genre.count.toDouble(),
                            radius: isTouched ? 38 : 32,
                            title: '',
                            borderSide: isTouched
                                ? const BorderSide(
                                    color: Colors.white,
                                    width: 2,
                                  )
                                : BorderSide.none,
                          );
                        }),
                      ),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                    ),
                    // Center label overlay — sits in the donut hole
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: GoogleFonts.notoSerif(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.onSurface,
                          ),
                        ),
                        Text(
                          'books',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(math.min(widget.genres.length, 6), (
                    i,
                  ) {
                    final genre = widget.genres[i];
                    final isSelected = _touchedIndex == i;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 7),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _chartColors[i % _chartColors.length].withAlpha(
                                25,
                              )
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _chartColors[i % _chartColors.length],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              genre.genre,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppTheme.onSurface
                                    : AppTheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Text(
                            '${genre.percentage.toInt()}%',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _chartColors[i % _chartColors.length]
                                  .withAlpha(isSelected ? 255 : 200),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── 5. Achievements Section ──────────────────────────────────────────────────

class _AchievementsSection extends ConsumerWidget {
  const _AchievementsSection();

  String _getAchievementTip(String id) {
    switch (id) {
      case 'first_book':
        return 'Finish any book in your library. Once you read the final page, update the book status to "Read" to earn this achievement!';
      case 'bookworm_5':
        return 'Complete reading 5 books in your library. Tip: Try adding shorter reads or novellas to build your momentum!';
      case 'bibliophile_20':
        return 'Finish 20 books. Tip: Consistency is key. Read just 15-20 minutes daily and you will get here sooner than you think!';
      case 'streak_3':
        return 'Log reading sessions on 3 consecutive days. Tip: Set a daily reminder to read at least one page every day!';
      case 'streak_7':
        return 'Read and log your progress every single day for a full week (7 days). Keep the flame burning!';
      case 'streak_30':
        return 'Maintain a reading streak of 30 days. Tip: Read a few pages before bed or during your morning coffee to make it a seamless habit!';
      case 'social_first_post':
        return 'Create your first post on the Reflection feed. Tip: Share a quote, a rating, or your thoughts on the current book you are reading!';
      case 'level_5':
        return 'Reach user Level 5 by earning 1,250 XP. Tip: Log reading sessions daily, review finished books, and take quizzes to earn XP rapidly!';
      case 'level_10':
        return 'Reach user Level 10 by earning 5,000 XP. Tip: Continue sharing posts, finishing books (100 XP each), and maintaining long streaks!';
      default:
        return 'Keep reading and logging your progress to unlock this special achievement!';
    }
  }

  void _showAchievementDialog(
    BuildContext context,
    Achievement ach,
    String assetPath,
    String tip,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge Image
              SizedBox(
                width: 140,
                height: 140,
                child: ColorFiltered(
                  colorFilter: ach.unlocked
                      ? const ColorFilter.mode(Colors.white, BlendMode.dst)
                      : const ColorFilter.matrix([
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0,
                          0,
                          0,
                          0.5,
                          0,
                        ]),
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D6A4F).withAlpha(30),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.emoji_events_rounded,
                          size: 64,
                          color: Color(0xFF2D6A4F),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                ach.name,
                style: GoogleFonts.notoSerif(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              // Status Label
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: ach.unlocked
                      ? const Color(0xFF2D6A4F).withAlpha(20)
                      : AppTheme.outlineVariant.withAlpha(30),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  ach.unlocked ? 'Unlocked' : 'Locked',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ach.unlocked
                        ? const Color(0xFF2D6A4F)
                        : AppTheme.onSurfaceVariant.withAlpha(200),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: AppTheme.outlineVariant.withAlpha(80)),
              const SizedBox(height: 12),
              // Description
              Text(
                ach.description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Tips Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D6A4F).withAlpha(10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2D6A4F).withAlpha(20),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: Color(0xFF2D6A4F),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'How to Unlock',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2D6A4F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tip,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.35,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D6A4F),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);
    return achievementsAsync.when(
      loading: () => const _SkeletonCard(height: 110),
      error: (_, __) => const SizedBox.shrink(),
      data: (achievements) {
        if (achievements.isEmpty) return const SizedBox.shrink();
        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Achievements',
                style: GoogleFonts.notoSerif(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: achievements.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final ach = achievements[index];
                    final assetPath = 'assets/achievements/${ach.id}.png';
                    return GestureDetector(
                      onTap: () {
                        _showAchievementDialog(
                          context,
                          ach,
                          assetPath,
                          _getAchievementTip(ach.id),
                        );
                      },
                      child: Tooltip(
                        message: 'Tap to see details & tip',
                        preferBelow: false,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 82,
                          decoration: BoxDecoration(
                            color: ach.unlocked
                                ? const Color(0xFF2D6A4F).withAlpha(12)
                                : AppTheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: ach.unlocked
                                  ? const Color(0xFF2D6A4F).withAlpha(80)
                                  : AppTheme.outlineVariant.withAlpha(60),
                              width: 1.5,
                            ),
                            boxShadow: ach.unlocked
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF2D6A4F,
                                      ).withAlpha(20),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Stack(
                            children: [
                              // Badge image + name
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Image with locked/unlocked treatment
                                    Expanded(
                                      child: ColorFiltered(
                                        colorFilter: ach.unlocked
                                            ? const ColorFilter.mode(
                                                Colors.white,
                                                BlendMode.dst,
                                              )
                                            : const ColorFilter.matrix([
                                                0.2126,
                                                0.7152,
                                                0.0722,
                                                0,
                                                0,
                                                0.2126,
                                                0.7152,
                                                0.0722,
                                                0,
                                                0,
                                                0.2126,
                                                0.7152,
                                                0.0722,
                                                0,
                                                0,
                                                0,
                                                0,
                                                0,
                                                0.5,
                                                0,
                                              ]),
                                        child: Image.asset(
                                          assetPath,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF2D6A4F,
                                                  ).withAlpha(30),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.emoji_events_rounded,
                                                    size: 32,
                                                    color: Color(0xFF2D6A4F),
                                                  ),
                                                ),
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      ach.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: ach.unlocked
                                            ? AppTheme.onSurface
                                            : AppTheme.onSurfaceVariant,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // Lock overlay for unearned achievements
                              if (!ach.unlocked)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceContainerHighest,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.outlineVariant,
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.lock_rounded,
                                      size: 10,
                                      color: AppTheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              // Unlocked sparkle indicator
                              if (ach.unlocked)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2D6A4F),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BadgesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(userBadgesProvider);
    return badgesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (badges) {
        if (badges.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            const SizedBox(height: 8),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Earned Badges',
                    style: GoogleFonts.notoSerif(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: badges.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, index) {
                        final badge = badges[index];
                        return Container(
                          width: 72,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B3A1C).withAlpha(12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF7B3A1C).withAlpha(40),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                badge.icon,
                                style: const TextStyle(fontSize: 28),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                badge.name,
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── 6. Reader Profile Card ───────────────────────────────────────────────────

class _ReaderProfileCard extends ConsumerWidget {
  final User user;
  const _ReaderProfileCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Archetype hero
          if (user.readerArchetype != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _archetypeGradientStart(user.readerArchetype).withAlpha(25),
                    _archetypeGradientEnd(user.readerArchetype).withAlpha(15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _archetypeGradientStart(
                        user.readerArchetype,
                      ).withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _archetypeIcon(user.readerArchetype),
                      size: 24,
                      color: _archetypeGradientStart(user.readerArchetype),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _archetypeDisplayName(user.readerArchetype),
                          style: GoogleFonts.notoSerif(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _archetypeGradientStart(
                              user.readerArchetype,
                            ),
                          ),
                        ),
                        Text(
                          'Your reader personality',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Preferred genres
          if (user.preferredGenres.isNotEmpty) ...[
            Text(
              'Preferred Genres',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: user.preferredGenres.map((genre) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryFixed,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    genre,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onPrimaryFixed,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],

          // Reading habits
          if (user.readingPace != null ||
              user.readingFrequency != null ||
              user.dailyReadingTime != null) ...[
            Text(
              'Reading Habits',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            if (user.readingPace != null)
              _HabitRow(
                icon: Icons.speed_rounded,
                label: 'Pace',
                value: _capitalize(user.readingPace!),
              ),
            if (user.readingFrequency != null)
              _HabitRow(
                icon: Icons.calendar_today_rounded,
                label: 'Frequency',
                value: _formatFrequency(user.readingFrequency!),
              ),
            if (user.dailyReadingTime != null)
              _HabitRow(
                icon: Icons.schedule_rounded,
                label: 'Daily Time',
                value: _formatDailyTime(user.dailyReadingTime!),
              ),
            const SizedBox(height: 8),
          ],

          // Retake button
          OutlinedButton.icon(
            onPressed: () {
              ref.read(onboardingCompletedProvider.notifier).state = null;
              context.go('/onboarding');
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(
              user.onboardingCompleted
                  ? 'Retake Taste Test'
                  : 'Take Taste Test',
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 7. Account Card ──────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final User user;
  final WidgetRef ref;
  const _AccountCard({required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          _AccountRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user.email,
          ),
          const SizedBox(height: 4),
          _AccountRow(
            icon: Icons.alternate_email_rounded,
            label: 'Username',
            value: '@${user.username}',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign Out'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: AppTheme.errorContainer,
              foregroundColor: AppTheme.onErrorContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _AccountRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shared UI Primitives ────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceVariant,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double height;
  const _SkeletonCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _HabitRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _HabitRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppTheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Archetype Helpers ────────────────────────────────────────────────────────

const _archetypeIcons = <String, IconData>{
  'the_explorer': Icons.explore_rounded,
  'the_scholar': Icons.school_rounded,
  'the_dreamer': Icons.dark_mode_rounded,
  'the_detective': Icons.search_rounded,
  'the_romantic': Icons.favorite_rounded,
  'the_philosopher': Icons.psychology_rounded,
  'the_speedster': Icons.bolt_rounded,
  'the_curator': Icons.palette_rounded,
};

const _archetypeNames = {
  'the_explorer': 'The Explorer',
  'the_scholar': 'The Scholar',
  'the_dreamer': 'The Dreamer',
  'the_detective': 'The Detective',
  'the_romantic': 'The Romantic',
  'the_philosopher': 'The Philosopher',
  'the_speedster': 'The Speedster',
  'the_curator': 'The Curator',
};

IconData _archetypeIcon(String? key) =>
    (key != null ? _archetypeIcons[key] : null) ?? Icons.auto_stories_rounded;

String _archetypeDisplayName(String? key) =>
    (key != null ? _archetypeNames[key] : null) ?? 'Reader';

// ─── Text Formatters ──────────────────────────────────────────────────────────

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

String _formatFrequency(String key) {
  switch (key) {
    case 'daily':
      return 'Every day';
    case 'few_times_week':
      return 'Few times a week';
    case 'weekly':
      return 'Weekly';
    case 'few_times_month':
      return 'Few times a month';
    default:
      return _capitalize(key);
  }
}

String _formatDailyTime(String key) {
  switch (key) {
    case 'under_15':
      return 'Under 15 min';
    case '15_to_30':
      return '15–30 min';
    case '30_to_60':
      return '30–60 min';
    case 'over_60':
      return 'Over 1 hour';
    default:
      return _capitalize(key);
  }
}
