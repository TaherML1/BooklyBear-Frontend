import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/gamification/presentation/gamification_providers.dart';
import '../features/library/presentation/library_providers.dart';
import '../features/library/domain/user_book.dart';

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
            _buildGamificationHero(ref),
            const SizedBox(height: 20),

            // ── Currently Reading ─────────────────────────────────────────
            _CurrentlyReadingSection(ref: ref),
            const SizedBox(height: 20),

            // ── Feed / Empty State ────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  const Icon(Icons.library_books, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'Your Feed is Empty',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Discover books to start your journey!'),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/search'),
                    icon: const Icon(Icons.search),
                    label: const Text('Discover Books'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  Widget _buildGamificationHero(WidgetRef ref) {
    final gamificationState = ref.watch(gamificationStatusProvider);

    return gamificationState.when(
      data: (status) {
        final progressPercent = status.nextLevelXp > 0
            ? (status.xpProgress / status.nextLevelXp).clamp(0.0, 1.0)
            : 0.0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Level Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          'Level ${status.level}',
                          style: const TextStyle(
                            color: Colors.white,
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
                      const Icon(Icons.local_fire_department, color: Colors.yellow, size: 28),
                      const SizedBox(width: 4),
                      Text(
                        '${status.streak} Days',
                        style: const TextStyle(
                          color: Colors.white,
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
                  const Text('XP Progress',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  Text('${status.xpProgress} / ${status.nextLevelXp} XP',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 10,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Card(
        color: Colors.red.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Failed to load stats: $err'),
        ),
      ),
    );
  }
}

// ─── Currently Reading Section ────────────────────────────────────────────────
class _CurrentlyReadingSection extends StatelessWidget {
  final WidgetRef ref;
  const _CurrentlyReadingSection({required this.ref});

  @override
  Widget build(BuildContext context) {
    final libraryAsync = ref.watch(libraryProvider);

    return libraryAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (books) {
        final reading = books
            .where((b) => b.status == ReadingStatus.reading)
            .toList();

        if (reading.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Continue Reading',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...reading.map((userBook) => _CurrentlyReadingCard(userBook: userBook)),
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
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
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
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: userBook.progressPercent,
                        minHeight: 6,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 10),

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
                          backgroundColor: const Color(0xFF7B61FF),
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          textStyle: const TextStyle(fontSize: 13),
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
