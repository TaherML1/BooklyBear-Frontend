import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/gamification/presentation/gamification_providers.dart';
import '../features/library/presentation/library_providers.dart';
import '../features/library/domain/user_book.dart';
import '../features/books/presentation/books_for_you_section.dart';
import '../features/social/presentation/social_feed_section.dart';
import '../theme/app_theme.dart';
import '../utils/app_logger.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(gamificationStatusProvider);
          ref.invalidate(libraryProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── Editorial Top Bar ─────────────────────────────────────────
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: AppTheme.surface,
              surfaceTintColor: Colors.transparent,
              title: Text(
                'BooklyBear',
                style: GoogleFonts.notoSerif(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_outline, size: 22),
                  onPressed: () => context.push('/profile'),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 20),
                  onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                ),
              ],
            ),

            // ── Content ──────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Gamification Hero
                  _buildGamificationHero(context, ref),
                  const SizedBox(height: 32),

                  // Daily Challenge
                  _buildDailyChallenge(context, ref),
                  const SizedBox(height: 48),

                  // Continue Reading
                  const _CurrentlyReadingSection(),
                  const SizedBox(height: 48),

                  // Curated For You (AI Recommendations)
                  const BooksForYouSection(),
                  const SizedBox(height: 48),

                  // Discover — Tinder-style Book Swipe CTA
                  _DiscoverCta(),
                  const SizedBox(height: 48),

                  // Reflections (Social Feed)
                  const SocialFeedSection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Gamification Hero — Editorial Style ──────────────────────────────────
  Widget _buildGamificationHero(BuildContext context, WidgetRef ref) {
    final gamificationState = ref.watch(gamificationStatusProvider);

    return gamificationState.when(
      data: (status) {
        AppLogger.info(
          '[HomeScreen] Gamification loaded — Level ${status.level}, Streak ${status.streak}',
        );
        final progressPercent = status.nextLevelXp > 0
            ? (status.xpProgress / status.nextLevelXp).clamp(0.0, 1.0)
            : 0.0;

        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text(
                'Welcome back, Archivist.',
                style: GoogleFonts.notoSerif(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${status.nextLevelXp - status.xpProgress} XP until your next chapter.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Level & Streak Row
              Row(
                children: [
                  // Level Badge — pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: AppTheme.onPrimary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Level ${status.level}',
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
                  // Streak
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryFixed,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department, color: AppTheme.onPrimaryFixed, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${status.streak} Days',
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
              const SizedBox(height: 20),

              // XP Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'XP Progress',
                    style: GoogleFonts.inter(
                      color: AppTheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${status.xpProgress} / ${status.nextLevelXp}',
                    style: GoogleFonts.inter(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  minHeight: 4,
                  backgroundColor: AppTheme.surfaceContainerHighest,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
            ],
          ),
        );
      },
      loading: () {
        AppLogger.info('[HomeScreen] Gamification loading...');
        return Container(
          height: 160,
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      },
      error: (err, _) {
        AppLogger.error('[HomeScreen] Gamification error: $err');
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.errorContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text('Failed to load stats: $err',
              style: TextStyle(color: AppTheme.onErrorContainer)),
        );
      },
    );
  }

  // ── Daily Challenge ─────────────────────────────────────────────────────
  Widget _buildDailyChallenge(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(todaysChallengeProvider);

    return challengeAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, _) => const SizedBox.shrink(),
      data: (challenge) {
        if (challenge.isCompleted && !challenge.newlyCompleted) {
          // Already done
        }

        final double progress =
            (challenge.pagesReadToday / challenge.goalPages).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: challenge.isCompleted
                ? AppTheme.primaryFixed.withAlpha(60)
                : AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.ambientShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    challenge.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.auto_stories_outlined,
                    color: challenge.isCompleted
                        ? AppTheme.primary
                        : AppTheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Daily Challenge',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryFixed,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '+${challenge.xpReward} XP',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: AppTheme.onPrimaryFixed,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                challenge.description,
                style: GoogleFonts.notoSerif(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${challenge.pagesReadToday} / ${challenge.goalPages} pages',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  if (challenge.isCompleted)
                    Text(
                      'Completed ✓',
                      style: GoogleFonts.inter(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              if (!challenge.isCompleted) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─── Currently Reading Section ────────────────────────────────────────────────
class _CurrentlyReadingSection extends ConsumerWidget {
  const _CurrentlyReadingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryAsync = ref.watch(libraryProvider);

    return libraryAsync.when(
      loading: () {
        AppLogger.info('[HomeScreen] Library loading...');
        return const SizedBox.shrink();
      },
      error: (err, __) {
        AppLogger.error('[HomeScreen] Library error: $err');
        return const SizedBox.shrink();
      },
      data: (books) {
        AppLogger.info(
          '[HomeScreen] Library loaded — ${books.length} total books',
        );
        final reading = books
            .where((b) => b.status == ReadingStatus.reading)
            .toList();
        AppLogger.info(
          '[HomeScreen] Currently reading: ${reading.length} books',
        );

        if (reading.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Continue Reading',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 20),
            ...reading.map(
              (userBook) => _CurrentlyReadingCard(userBook: userBook),
            ),
          ],
        );
      },
    );
  }
}

// ─── Individual Currently Reading Card ───────────────────────────────────────
class _CurrentlyReadingCard extends StatelessWidget {
  final UserBook userBook;
  const _CurrentlyReadingCard({required this.userBook});

  @override
  Widget build(BuildContext context) {
    final book = userBook.book;
    final theme = Theme.of(context);
    final percent = (userBook.progressPercent * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: InkWell(
        onTap: () => context.push('/book/${book.isbn}'),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Cover — let it feel like a prized possession
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                book.coverImageUrl,
                width: 64,
                height: 96,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 64,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.book, size: 28, color: AppTheme.onSurfaceVariant),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info + Progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSerif(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Page ${userBook.currentPage} of ${book.pageCount}',
                        style: theme.textTheme.labelSmall,
                      ),
                      Text(
                        '$percent%',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: userBook.progressPercent,
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Focus Timer Button — editorial gradient
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: FilledButton.icon(
                        onPressed: () => context.push(
                          '/timer/${userBook.id}?title=${Uri.encodeComponent(book.title)}',
                        ),
                        icon: const Icon(Icons.timer_outlined, size: 16),
                        label: const Text('Focus Timer'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                        ),
                      ),
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
}

// ─── Discover CTA — Tinder‑style Book Swipe ──────────────────────────────────
class _DiscoverCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/discover'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6C63FF),
              Color(0xFF9F7AEA),
              Color(0xFFF687B3),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withAlpha(50),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover',
                    style: GoogleFonts.notoSerif(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Swipe through books tailored to your taste. Like to save, skip to pass.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white.withAlpha(210),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                          color: Colors.white.withAlpha(60)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Start Swiping',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Swipe cards icon
            Stack(
              children: [
                Transform.translate(
                  offset: const Offset(6, 6),
                  child: Transform.rotate(
                    angle: 0.12,
                    child: Container(
                      width: 56,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withAlpha(40)),
                      ),
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: -0.08,
                  child: Container(
                    width: 56,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(50),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: Colors.white.withAlpha(70)),
                    ),
                    child: const Center(
                      child: Icon(Icons.swipe_rounded,
                          color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
