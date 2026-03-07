import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/library/presentation/library_providers.dart';
import '../features/library/domain/user_book.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Library'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.book), text: 'Reading'),
              Tab(icon: Icon(Icons.bookmarks_outlined), text: 'To Read'),
              Tab(icon: Icon(Icons.check_circle_outline), text: 'Finished'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BookList(
              statusProvider: readingBooksProvider,
              emptyMessage:
                  "You're not reading anything yet.\nAdd a book and start reading!",
            ),
            _BookList(
              statusProvider: toReadBooksProvider,
              emptyMessage:
                  "Your reading list is empty.\nSearch for books to add!",
            ),
            _BookList(
              statusProvider: finishedBooksProvider,
              emptyMessage:
                  "No finished books yet.\nKeep reading, you'll get there! 🎉",
            ),
          ],
        ),
      ),
    );
  }
}

class _BookList extends ConsumerWidget {
  final ProviderListenable<AsyncValue<List<UserBook>>> statusProvider;
  final String emptyMessage;

  const _BookList({required this.statusProvider, required this.emptyMessage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(statusProvider);

    return booksAsync.when(
      data: (books) {
        if (books.isEmpty) {
          return _EmptyState(message: emptyMessage);
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(libraryProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _BookCard(userBook: books[index], ref: ref),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                'Failed to load library:\n$err',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(libraryProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final UserBook userBook;
  final WidgetRef ref;

  const _BookCard({required this.userBook, required this.ref});

  @override
  Widget build(BuildContext context) {
    final book = userBook.book;
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => context.push('/book/${book.isbn}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Cover Image ---
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  book.coverImageUrl,
                  width: 70,
                  height: 105,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 70,
                    height: 105,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.book, size: 36),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // --- Book Info ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    // --- Progress Section (Reading only) ---
                    if (userBook.status == ReadingStatus.reading) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Page ${userBook.currentPage} of ${book.pageCount}',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            '${(userBook.progressPercent * 100).toStringAsFixed(0)}%',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: userBook.progressPercent,
                          minHeight: 6,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // ── Focus Timer Button ──────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: () => context.push(
                            '/timer/${userBook.id}?title=${Uri.encodeComponent(book.title)}',
                          ),
                          icon: const Icon(Icons.timer_outlined, size: 16),
                          label: const Text('Focus Timer'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 34),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            textStyle: const TextStyle(fontSize: 13),
                            backgroundColor: const Color(0xFF7B61FF).withValues(alpha: 0.15),
                            foregroundColor: const Color(0xFF7B61FF),
                          ),
                        ),
                      ),
                    ],

                    // --- Rating Section (Finished only) ---
                    if (userBook.status == ReadingStatus.read &&
                        userBook.rating != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < (userBook.rating ?? 0)
                                ? Icons.star
                                : Icons.star_border,
                            size: 18,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ],

                    // --- Status Chip ---
                    const SizedBox(height: 10),
                    _StatusChip(status: userBook.status),
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

class _StatusChip extends StatelessWidget {
  final ReadingStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ReadingStatus.reading => ('Reading', Colors.blue),
      ReadingStatus.read => ('Finished ✓', Colors.green),
      ReadingStatus.toRead => ('To Read', Colors.orange),
      ReadingStatus.dnf => ('Did Not Finish', Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 72,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
