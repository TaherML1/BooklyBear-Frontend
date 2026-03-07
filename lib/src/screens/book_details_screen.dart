import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../features/books/data/book_repository.dart';
import '../features/books/domain/book.dart';
import '../features/library/data/library_repository.dart';
import '../features/library/domain/user_book.dart';
import '../features/library/presentation/library_providers.dart';
import '../features/books/presentation/book_reviews_section.dart';

// ─── Provider: Is this book already in the library? ─────────────────────────
final userBookForIsbnProvider = FutureProvider.family<UserBook?, String>((
  ref,
  isbn,
) async {
  final library = await ref.watch(libraryProvider.future);
  try {
    return library.firstWhere((ub) => ub.book.isbn == isbn);
  } catch (_) {
    return null;
  }
});

// ─── Main Screen ─────────────────────────────────────────────────────────────
class BookDetailsScreen extends ConsumerWidget {
  final String isbn;
  const BookDetailsScreen({super.key, required this.isbn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookByIsbnProvider(isbn));

    return Scaffold(
      appBar: AppBar(title: const Text('Book Details')),
      body: bookAsync.when(
        data: (book) {
          if (book == null) {
            return const Center(child: Text('Book not found. (404)'));
          }
          return _BookDetailsView(book: book);
        },
        error: (err, _) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

// ─── Book Details View (StatefulWidget for local slider state) ───────────────
class _BookDetailsView extends ConsumerStatefulWidget {
  final Book book;
  const _BookDetailsView({required this.book});

  @override
  ConsumerState<_BookDetailsView> createState() => _BookDetailsViewState();
}

class _BookDetailsViewState extends ConsumerState<_BookDetailsView> {
  bool _isAddingToLibrary = false;
  bool _isUpdatingProgress = false;

  // Local slider value (updated as user drags)
  late double _sliderPage;

  @override
  void initState() {
    super.initState();
    _sliderPage = 0;
  }

  Future<void> _addToLibrary(BuildContext ctx) async {
    setState(() => _isAddingToLibrary = true);
    try {
      await ref
          .read(libraryRepositoryProvider)
          .addBookToLibrary(widget.book.id);
      ref.invalidate(libraryProvider);
      ref.invalidate(userBookForIsbnProvider(widget.book.isbn));
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('"${widget.book.title}" added to your library!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingToLibrary = false);
    }
  }

  Future<void> _updateProgress(BuildContext ctx, UserBook userBook) async {
    setState(() => _isUpdatingProgress = true);
    try {
      final page = _sliderPage.toInt();
      final isFinished = page >= widget.book.pageCount;
      final newStatus = isFinished
          ? readingStatusToString(ReadingStatus.read)
          : readingStatusToString(ReadingStatus.reading);

      await ref
          .read(libraryRepositoryProvider)
          .updateLibraryEntry(
            userBookId: userBook.id,
            currentPage: page,
            status: newStatus,
          );
      ref.invalidate(libraryProvider);
      ref.invalidate(userBookForIsbnProvider(widget.book.isbn));

      if (ctx.mounted) {
        if (isFinished) {
          // Show star rating bottom sheet!
          await _showRatingModal(ctx, userBook.id);
        } else {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text('Progress updated to page $page!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingProgress = false);
    }
  }

  /// Shows a bottom sheet asking the user to rate the finished book
  Future<void> _showRatingModal(BuildContext ctx, String userBookId) async {
    await showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _StarRatingSheet(
        bookTitle: widget.book.title,
        onRate: (rating) async {
          await ref.read(libraryRepositoryProvider).updateLibraryEntry(
            userBookId: userBookId,
            rating: rating,
          );
          ref.invalidate(libraryProvider);
          ref.invalidate(userBookForIsbnProvider(widget.book.isbn));
          if (ctx.mounted) Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userBookAsync = ref.watch(userBookForIsbnProvider(widget.book.isbn));
    final book = widget.book;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Cover Image ──────────────────────────────────────────────────
          Container(
            height: 300,
            padding: const EdgeInsets.all(24),
            color: Colors.grey[200],
            child: CachedNetworkImage(
              imageUrl: book.coverImageUrl,
              fit: BoxFit.contain,
              placeholder: (_, __) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (_, __, ___) =>
                  const Icon(Icons.book, size: 100, color: Colors.grey),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  book.author,
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.menu_book, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${book.pageCount} pages'),
                    const Text(' · '),
                    Text(book.publisher ?? 'Unknown publisher'),
                  ],
                ),
                // ── Google Books Community Rating ────────────────────────
                if (book.averageRating != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ...List.generate(5, (i) {
                        final full = i < book.averageRating!.floor();
                        final half = !full &&
                            i < book.averageRating! &&
                            (book.averageRating! - i) >= 0.5;
                        return Icon(
                          full
                              ? Icons.star_rounded
                              : half
                                  ? Icons.star_half_rounded
                                  : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 18,
                        );
                      }),
                      const SizedBox(width: 6),
                      Text(
                        '${book.averageRating!.toStringAsFixed(1)}'  
                        '${book.ratingsCount != null ? ' (${_formatCount(book.ratingsCount!)})' : ''}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Google Books',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),

                // ── Library Section ──────────────────────────────────────
                userBookAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (userBook) {
                    if (userBook == null) {
                      // Book is NOT in library — show Add button
                      return SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isAddingToLibrary
                              ? null
                              : () => _addToLibrary(context),
                          icon: _isAddingToLibrary
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.add),
                          label: const Text('Add to Library'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      );
                    }

                    // Book IS in library — initialize slider with current page
                    if (_sliderPage == 0 && userBook.currentPage > 0) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(
                            () => _sliderPage = userBook.currentPage.toDouble(),
                          );
                        }
                      });
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(
                              userBook.status,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusLabel(userBook.status),
                            style: TextStyle(
                              color: _statusColor(userBook.status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Page progress slider
                        if (userBook.status != ReadingStatus.read) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Reading Progress',
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_sliderPage.toInt()} / ${book.pageCount}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _sliderPage.clamp(
                              0,
                              book.pageCount.toDouble(),
                            ),
                            min: 0,
                            max: book.pageCount.toDouble(),
                            divisions: book.pageCount > 0 ? book.pageCount : 1,
                            label: 'Page ${_sliderPage.toInt()}',
                            onChanged: (v) => setState(() => _sliderPage = v),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _isUpdatingProgress
                                  ? null
                                  : () => _updateProgress(context, userBook),
                              icon: _isUpdatingProgress
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save_alt),
                              label: Text(
                                _sliderPage.toInt() >= book.pageCount
                                    ? '🎉 Mark as Finished'
                                    : 'Save Progress',
                              ),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (userBook.status == ReadingStatus.read) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'You have finished this book!',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // ── Description ──────────────────────────────────────────
                Text(
                  'Description',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  book.description ?? 'No description available.',
                  style: textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 48),

                // ── Reviews Section ──────────────────────────────────────
                BookReviewsSection(isbn: book.isbn),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(ReadingStatus s) => switch (s) {
    ReadingStatus.reading => Colors.blue,
    ReadingStatus.read => Colors.green,
    ReadingStatus.toRead => Colors.orange,
    ReadingStatus.dnf => Colors.grey,
  };

  String _statusLabel(ReadingStatus s) => switch (s) {
    ReadingStatus.reading => '📖 Currently Reading',
    ReadingStatus.read => '✅ Finished',
    ReadingStatus.toRead => '🔖 In Your Library',
    ReadingStatus.dnf => '😅 Did Not Finish',
  };

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return '$n';
  }
}

// ─── Star Rating Bottom Sheet ─────────────────────────────────────────────────
class _StarRatingSheet extends StatefulWidget {
  final String bookTitle;
  final Future<void> Function(int rating) onRate;

  const _StarRatingSheet({required this.bookTitle, required this.onRate});

  @override
  State<_StarRatingSheet> createState() => _StarRatingSheetState();
}

class _StarRatingSheetState extends State<_StarRatingSheet> {
  int _selectedRating = 0;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Trophy
          const Text('🎉', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text(
            'You finished the book!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            widget.bookTitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 28),

          // Stars
          const Text(
            'How would you rate it?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _selectedRating;
              return GestureDetector(
                onTap: () => setState(() => _selectedRating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 48,
                    color: filled ? Colors.amber : Colors.grey[300],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedRating == 0 ? 'Tap a star to rate'
            : ['', '😕 Poor', '😐 Fair', '🙂 Good', '😊 Great', '🤩 Amazing!'][_selectedRating],
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 28),

          // Submit
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_selectedRating == 0 || _saving) ? null : () async {
                setState(() => _saving = true);
                await widget.onRate(_selectedRating);
                if (mounted) setState(() => _saving = false);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber[700],
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Submit Rating', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Skip', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
