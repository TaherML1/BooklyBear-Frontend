import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/library/presentation/library_providers.dart';
import '../features/library/domain/user_book.dart';
import '../theme/app_theme.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Library', style: Theme.of(context).textTheme.headlineMedium),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.book_outlined), text: 'Reading'),
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
            padding: const EdgeInsets.all(20),
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
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
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 12),
              Text(
                'Failed to load library:\n$err',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton(
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

    return Container(
      decoration: AppTheme.cardDecoration,
      child: InkWell(
        onTap: () => context.push('/book/${book.isbn}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Cover Image ---
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  book.coverImageUrl,
                  width: 70,
                  height: 105,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 70,
                    height: 105,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.book, size: 36, color: AppTheme.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // --- Book Info ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: GoogleFonts.notoSerif(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: theme.textTheme.bodySmall,
                    ),

                    // --- Progress Section (Reading only) ---
                    if (userBook.status == ReadingStatus.reading) ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Page ${userBook.currentPage} of ${book.pageCount}',
                            style: theme.textTheme.labelSmall,
                          ),
                          Text(
                            '${(userBook.progressPercent * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                              fontSize: 12,
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
                      // ── Focus Timer Button ───────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: FilledButton.tonalIcon(
                            onPressed: () => context.push(
                              '/timer/${userBook.id}?title=${Uri.encodeComponent(book.title)}',
                            ),
                            icon: const Icon(Icons.timer_outlined, size: 16),
                            label: const Text('Focus Timer'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: AppTheme.onPrimary,
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                            ),
                          ),
                        ),
                      ),
                    ],

                    // --- Rating Section (Finished only) ---
                    if (userBook.status == ReadingStatus.read &&
                        userBook.rating != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < (userBook.rating ?? 0)
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 18,
                            color: const Color(0xFFD4A84B),
                          ),
                        ),
                      ),
                    ],

                    // --- Status Chip --- pill style
                    const SizedBox(height: 12),
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
      ReadingStatus.reading => ('Reading', AppTheme.primary),
      ReadingStatus.read => ('Finished ✓', AppTheme.primary),
      ReadingStatus.toRead => ('To Read', AppTheme.secondary),
      ReadingStatus.dnf => ('Did Not Finish', AppTheme.outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
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
              color: AppTheme.outlineVariant,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppTheme.onSurfaceVariant,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
