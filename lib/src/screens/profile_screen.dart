import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/user/data/profile_repository.dart';
import '../features/user/data/stats_repository.dart';
import '../features/library/presentation/library_providers.dart';
import '../features/library/domain/user_book.dart';
import '../features/gamification/presentation/gamification_providers.dart';
import '../theme/app_theme.dart';
import '../routing/app_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final statsAsync = ref.watch(myReadingStatsProvider);
    final libraryAsync = ref.watch(libraryProvider);

    return Scaffold(
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading profile: $err')),
        data: (user) {
          // XP calculation — matches backend: level = floor(sqrt(points / 50))
          final int currentLevel = user.level;
          final int nextLevelXp =
              ((currentLevel + 1) * (currentLevel + 1) * 50);
          final int currentLevelXp = (currentLevel * currentLevel * 50);
          final int xpProgress = (user.points - currentLevelXp).clamp(
            0,
            nextLevelXp - currentLevelXp,
          );
          final int xpNeeded = nextLevelXp - currentLevelXp;
          final double xpPercent = xpNeeded > 0
              ? (xpProgress / xpNeeded).clamp(0.0, 1.0)
              : 0.0;

          // Library counts from the library provider
          final int readingCount =
              libraryAsync.whenOrNull(
                data: (books) => books
                    .where((b) => b.status == ReadingStatus.reading)
                    .length,
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
            },
            child: CustomScrollView(
              slivers: [
                // ── Hero App Bar — editorial tonal ──────────────────────────
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      color: AppTheme.surfaceContainerLow,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 44,
                                backgroundColor: AppTheme.primaryFixed,
                                backgroundImage: user.avatarUrl != null
                                    ? CachedNetworkImageProvider(
                                        user.avatarUrl!,
                                      )
                                    : null,
                                child: user.avatarUrl == null
                                    ? Text(
                                        user.displayName.isNotEmpty
                                            ? user.displayName[0].toUpperCase()
                                            : '?',
                                        style: GoogleFonts.notoSerif(
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.onPrimaryFixed,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.displayName,
                                      style: Theme.of(context).textTheme.headlineLarge,
                                    ),
                                    Text(
                                      '@${user.username}',
                                      style: GoogleFonts.inter(
                                        color: AppTheme.onSurfaceVariant,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (user.bio != null &&
                                        user.bio!.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        user.bio!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          color: AppTheme.onSurfaceVariant,
                                          fontSize: 13,
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
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppTheme.primary,
                      ),
                      onPressed: () {
                        context.go(
                          '/profile/edit',
                          extra: {
                            'displayName': user.displayName,
                            'bio': user.bio,
                          },
                        );
                      },
                    ),
                  ],
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Level & XP Bar ──────────────────────────────────
                        _SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      // Level pill badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary,
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.star_rounded,
                                              size: 16,
                                              color: AppTheme.onPrimary,
                                            ),
                                            const SizedBox(width: 4),
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
                                      const SizedBox(width: 12),
                                      // Streak pill
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryFixed,
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.local_fire_department,
                                              color: AppTheme.onPrimaryFixed,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${user.currentStreak} days',
                                              style: GoogleFonts.inter(
                                                color: AppTheme.onPrimaryFixed,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${user.points} XP',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                              ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: LinearProgressIndicator(
                                  value: xpPercent,
                                  minHeight: 4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Library Stats — tonal cards ─────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: _LibraryStatCard(
                                value: readingCount,
                                label: 'Reading',
                                icon: Icons.book_outlined,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _LibraryStatCard(
                                value: finishedCount,
                                label: 'Finished',
                                icon: Icons.check_circle_outline,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _LibraryStatCard(
                                value: toReadCount,
                                label: 'To Read',
                                icon: Icons.bookmarks_outlined,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Reading Stats ───────────────────────────────────
                        statsAsync.when(
                          loading: () => const SizedBox(
                            height: 80,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (stats) => _SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reading Stats',
                                  style: GoogleFonts.notoSerif(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _StatItem(
                                      icon: Icons.pages_outlined,
                                      value: '${stats.totalPages}',
                                      label: 'Pages',
                                    ),
                                    _StatItem(
                                      icon: Icons.schedule,
                                      value: '${stats.totalHours}h',
                                      label: 'Hours',
                                    ),
                                    _StatItem(
                                      icon: Icons.self_improvement,
                                      value: '${stats.totalSessions}',
                                      label: 'Sessions',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Account Info ────────────────────────────────────
                        _SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Account',
                                style: GoogleFonts.notoSerif(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.email_outlined, color: AppTheme.onSurfaceVariant),
                                title: const Text('Email'),
                                subtitle: Text(user.email),
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.alternate_email, color: AppTheme.onSurfaceVariant),
                                title: const Text('Username'),
                                subtitle: Text('@${user.username}'),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Recommendation Settings ──────────────────────────
                        _SectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Recommendation Settings',
                                    style: GoogleFonts.notoSerif(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: AppTheme.onSurface,
                                    ),
                                  ),
                                  if (user.onboardingCompleted)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryFixed,
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                      child: Text(
                                        'Active',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.onPrimaryFixed,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (user.readerArchetype != null) ...[
                                // Archetype display
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        _archetypeEmoji(user.readerArchetype!),
                                        style: const TextStyle(fontSize: 32),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _archetypeDisplayName(user.readerArchetype!),
                                              style: GoogleFonts.notoSerif(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.primary,
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
                                const SizedBox(height: 12),
                              ],
                              // Preferred genres
                              if (user.preferredGenres.isNotEmpty) ...[
                                Text(
                                  'Preferred Genres',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: user.preferredGenres.map((genre) {
                                    return Chip(
                                      label: Text(genre),
                                      visualDensity: VisualDensity.compact,
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 12),
                              ],
                              // Reading habits summary
                              if (user.readingPace != null)
                                _HabitRow(
                                  icon: Icons.speed,
                                  label: 'Pace',
                                  value: _capitalize(user.readingPace!),
                                ),
                              if (user.readingFrequency != null)
                                _HabitRow(
                                  icon: Icons.calendar_today,
                                  label: 'Frequency',
                                  value: _formatFrequency(user.readingFrequency!),
                                ),
                              if (user.dailyReadingTime != null)
                                _HabitRow(
                                  icon: Icons.schedule,
                                  label: 'Daily Time',
                                  value: _formatDailyTime(user.dailyReadingTime!),
                                ),
                              const SizedBox(height: 16),
                              // Retake button
                              OutlinedButton.icon(
                                onPressed: () {
                                  ref.read(onboardingCompletedProvider.notifier).state = null;
                                  context.go('/onboarding');
                                },
                                icon: const Icon(Icons.refresh_rounded, size: 18),
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
                        ),

                        const SizedBox(height: 16),

                        // ── Achievements ────────────────────────────────────
                        Consumer(
                           builder: (context, ref, child) {
                             final achievementsAsync = ref.watch(achievementsProvider);
                             return achievementsAsync.when(
                               loading: () => const Center(child: CircularProgressIndicator()),
                               error: (err, _) => const SizedBox.shrink(),
                               data: (achievements) {
                                 if (achievements.isEmpty) return const SizedBox.shrink();
                                 return _SectionCard(
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       Text('Achievements', style: GoogleFonts.notoSerif(
                                         fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.onSurface,
                                       )),
                                       const SizedBox(height: 12),
                                       SizedBox(
                                         height: 100,
                                         child: ListView.builder(
                                           scrollDirection: Axis.horizontal,
                                           itemCount: achievements.length,
                                           itemBuilder: (context, index) {
                                             final ach = achievements[index];
                                             return Opacity(
                                               opacity: ach.unlocked ? 1.0 : 0.4,
                                               child: Container(
                                                 width: 80,
                                                 margin: const EdgeInsets.only(right: 12),
                                                 child: Column(
                                                   children: [
                                                     Text(ach.icon, style: const TextStyle(fontSize: 32)),
                                                     const SizedBox(height: 4),
                                                     Text(ach.name, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.onSurfaceVariant), textAlign: TextAlign.center),
                                                   ],
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
                           },
                        ),

                        const SizedBox(height: 16),

                        // ── Dynamic Badges ──────────────────────────────────
                        Consumer(
                          builder: (context, ref, child) {
                            final badgesAsync = ref.watch(userBadgesProvider);
                            return badgesAsync.when(
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (err, _) => const SizedBox.shrink(),
                              data: (badges) {
                                if (badges.isEmpty) return const SizedBox.shrink();
                                return _SectionCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Earned Badges', style: GoogleFonts.notoSerif(
                                        fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.onSurface,
                                      )),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        height: 100,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: badges.length,
                                          itemBuilder: (context, index) {
                                            final badge = badges[index];
                                            return Container(
                                              width: 80,
                                              margin: const EdgeInsets.only(right: 12),
                                              child: Column(
                                                children: [
                                                  Text(badge.icon, style: const TextStyle(fontSize: 32)),
                                                  const SizedBox(height: 4),
                                                  Text(badge.name, style: GoogleFonts.inter(fontSize: 10, color: AppTheme.onSurfaceVariant), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                                                ],
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
                          },
                        ),

                        const SizedBox(height: 24),
                        // ── Logout ──────────────────────────────────────────
                        FilledButton.icon(
                          onPressed: () => ref
                              .read(authControllerProvider.notifier)
                              .logout(),
                          icon: const Icon(Icons.logout),
                          label: const Text('Log Out'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            backgroundColor: AppTheme.errorContainer,
                            foregroundColor: AppTheme.onErrorContainer,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                          ),
                        ),
                        const SizedBox(height: 100), // nav bar clearance
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

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

class _LibraryStatCard extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color color;

  const _LibraryStatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: GoogleFonts.notoSerif(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppTheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppTheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.notoSerif(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurface,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─── Recommendation Settings Helpers ─────────────────────────────────────────

class _HabitRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _HabitRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.onSurfaceVariant),
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

const _archetypeEmojis = {
  'the_explorer': '🧭',
  'the_scholar': '📚',
  'the_dreamer': '🌙',
  'the_detective': '🔍',
  'the_romantic': '💕',
  'the_philosopher': '🧠',
  'the_speedster': '⚡',
  'the_curator': '🎨',
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

String _archetypeEmoji(String key) => _archetypeEmojis[key] ?? '📖';
String _archetypeDisplayName(String key) => _archetypeNames[key] ?? key;

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s.replaceAll('_', ' ').split(' ').map((w) =>
    w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}'
  ).join(' ');
}

String _formatFrequency(String key) {
  switch (key) {
    case 'daily': return 'Every day';
    case 'few_times_week': return 'Few times a week';
    case 'weekly': return 'Weekly';
    case 'few_times_month': return 'Few times a month';
    default: return _capitalize(key);
  }
}

String _formatDailyTime(String key) {
  switch (key) {
    case 'under_15': return 'Under 15 min';
    case '15_to_30': return '15–30 min';
    case '30_to_60': return '30–60 min';
    case 'over_60': return 'Over 1 hour';
    default: return _capitalize(key);
  }
}
