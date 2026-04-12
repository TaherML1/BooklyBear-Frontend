import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/gamification/presentation/gamification_providers.dart';
import '../features/library/presentation/library_providers.dart';
import '../features/library/domain/user_book.dart';

import '../features/books/presentation/books_for_you_section.dart';
import '../features/social/presentation/social_feed_section.dart';

import '../utils/app_logger.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BooklyBear 🐻'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(gamificationStatusProvider);
          ref.invalidate(libraryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // ── Gamification Hero ─────────────────────────────────────────
            _buildGamificationHero(context, ref),
            const SizedBox(height: 24),

            // ── Daily Challenge ───────────────────────────────────────────
            _buildDailyChallenge(context, ref),
            const SizedBox(height: 48),

            // ── AI Recommendations ────────────────────────────────────────
            const BooksForYouSection(),
            const SizedBox(height: 48),

            // ── Currently Reading ─────────────────────────────────────────
            const _CurrentlyReadingSection(),
            const SizedBox(height: 48),

            // ── Feed (Social + Discovery) ─────────────────────────────────
            const SocialFeedSection(),
          ],
        ),
      ),
    );
  }

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
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Level Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onPrimary.withAlpha(25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Theme.of(context).colorScheme.onPrimary, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'Level ${status.level}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Streak
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 28,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${status.streak} Days',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'XP Progress',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${status.xpProgress} / ${status.nextLevelXp} XP',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progressPercent,
                backgroundColor: Theme.of(context).colorScheme.onPrimary.withAlpha(50),
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                minHeight: 2,
              ),
            ],
          ),
        );
      },
      loading: () {
        AppLogger.info('[HomeScreen] Gamification loading...');
        return const Center(child: CircularProgressIndicator());
      },
      error: (err, _) {
        AppLogger.error('[HomeScreen] Gamification error: $err');
        return Card(
          color: Colors.red.shade100,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Failed to load stats: $err'),
          ),
        );
      },
    );
  }

  Widget _buildDailyChallenge(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(todaysChallengeProvider);

    return challengeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => const SizedBox.shrink(),
      data: (challenge) {
        if (challenge.isCompleted && !challenge.newlyCompleted) {
          // If completely done before today, we could just show a checkmark or ignore it.
        }

        final double progress = (challenge.pagesReadToday / challenge.goalPages).clamp(0.0, 1.0);

        return Card(
          color: challenge.isCompleted 
              ? Theme.of(context).colorScheme.primaryContainer 
              : Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: challenge.isCompleted 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      challenge.isCompleted ? Icons.check_circle : Icons.star_border,
                      color: challenge.isCompleted ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Daily Challenge',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Text('+${challenge.xpReward} XP', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(challenge.description),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${challenge.pagesReadToday} / ${challenge.goalPages} pages'),
                    if (challenge.isCompleted) const Text('Completed!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
                if (!challenge.isCompleted) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress),
                ],
              ],
            ),
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
            const SizedBox(height: 10),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/book/${book.isbn}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  book.coverImageUrl,
                  width: 60,
                  height: 88,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 88,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.book, size: 30),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Info + Progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Page ${userBook.currentPage} of ${book.pageCount}',
                          style: theme.textTheme.labelSmall,
                        ),
                        Text(
                          '$percent%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: userBook.progressPercent,
                      minHeight: 2,
                      backgroundColor: theme.colorScheme.outlineVariant.withAlpha(50),
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),

                    // ── Focus Timer Button ──────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.push(
                          '/timer/${userBook.id}?title=${Uri.encodeComponent(book.title)}',
                        ),
                        icon: const Icon(Icons.timer_outlined, size: 16),
                        label: const Text('Start Focus Timer'),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          foregroundColor: theme.colorScheme.onPrimary,
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          textStyle: const TextStyle(fontSize: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
