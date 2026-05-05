import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/books/data/book_repository.dart';
import '../features/books/domain/book.dart';
import '../features/library/data/library_repository.dart';
import '../features/library/domain/user_book.dart';
import '../features/library/presentation/library_providers.dart';
import '../features/books/presentation/book_reviews_section.dart';
import '../features/gamification/data/gamification_repository.dart';
import '../features/gamification/presentation/quiz_taking_screen.dart';
import '../theme/app_theme.dart';

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
  bool _isGeneratingQuiz = false;

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
          ),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('$e')),
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
            SnackBar(content: Text('Progress updated to page $page!')),
          );
        }
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingProgress = false);
    }
  }

  void _takeBookQuiz() async {
    setState(() => _isGeneratingQuiz = true);
    try {
      final quiz = await ref.read(gamificationRepositoryProvider).getBookQuiz(widget.book.id);
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => QuizTakingScreen(quiz: quiz)));
      }
    } catch(e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate quiz: $e')));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingQuiz = false);
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
          // ── Cover Image — editorial hero ───────────────────────────────
          Container(
            height: 380,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppTheme.surfaceContainerLow,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: book.coverImageUrl,
                    fit: BoxFit.contain,
                    placeholder: (_, __) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.book, size: 100, color: AppTheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category — pill badge
                if (book.categories.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryFixed,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      book.categories.first.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppTheme.onPrimaryFixed,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Title — display serif
                Text(
                  book.title,
                  style: textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),

                // Author
                Text(
                  book.author,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),

                // Page count & publisher
                Row(
                  children: [
                    if (book.pageCount > 0) ...[
                      const Icon(Icons.menu_book, size: 16, color: AppTheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text('${book.pageCount} pages', style: textTheme.labelSmall),
                      Text(' · ', style: TextStyle(color: AppTheme.outlineVariant)),
                    ],
                    Expanded(
                      child: Text(
                        book.publisher ?? 'Unknown publisher',
                        style: textTheme.labelSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // ── Google Books Community Rating ────────────────────────
                if (book.averageRating != null) ...[
                  const SizedBox(height: 12),
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
                          color: const Color(0xFFD4A84B), // warm gold, editorial
                          size: 18,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        '${book.averageRating!.toStringAsFixed(1)}'
                        '${book.ratingsCount != null ? ' (${_formatCount(book.ratingsCount!)})' : ''}',
                        style: GoogleFonts.inter(
                          color: AppTheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 28),

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
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: AppTheme.ambientShadow,
                          ),
                          child: FilledButton.icon(
                            onPressed: _isAddingToLibrary
                                ? null
                                : () => _addToLibrary(context),
                            icon: _isAddingToLibrary
                                ? const SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppTheme.onPrimary,
                                    ),
                                  )
                                : const Icon(Icons.add),
                            label: const Text('Add to Library'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
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
                        // Status badge — pill style
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: _statusColor(userBook.status).withAlpha(25),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            _statusLabel(userBook.status),
                            style: GoogleFonts.inter(
                              color: _statusColor(userBook.status),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Page progress slider
                        if (userBook.status != ReadingStatus.read) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Reading Progress',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppTheme.onSurface,
                                ),
                              ),
                              Text(
                                '${_sliderPage.toInt()} / ${book.pageCount}',
                                style: GoogleFonts.inter(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _sliderPage.clamp(0, book.pageCount.toDouble()),
                            min: 0,
                            max: book.pageCount.toDouble(),
                            divisions: book.pageCount > 0 ? book.pageCount : 1,
                            label: 'Page ${_sliderPage.toInt()}',
                            onChanged: (v) => setState(() => _sliderPage = v),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: FilledButton.icon(
                                onPressed: _isUpdatingProgress
                                    ? null
                                    : () => _updateProgress(context, userBook),
                                icon: _isUpdatingProgress
                                    ? const SizedBox(
                                        width: 18, height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2, color: AppTheme.onPrimary,
                                        ),
                                      )
                                    : const Icon(Icons.save_alt),
                                label: Text(
                                  _sliderPage.toInt() >= book.pageCount
                                      ? '🎉 Mark as Finished'
                                      : 'Save Progress',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ),
                        ],
                        if (userBook.status == ReadingStatus.read) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryFixed.withAlpha(50),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'You have finished this book!',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: FilledButton.icon(
                                onPressed: _isGeneratingQuiz ? null : _takeBookQuiz,
                                icon: _isGeneratingQuiz
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.onPrimary))
                                  : const Icon(Icons.school_outlined),
                                label: const Text('Take Book Quiz'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),

                const SizedBox(height: 36),

                // ── Description — editorial "About" ─────────────────────
                Text('About the book', style: textTheme.headlineMedium),
                const SizedBox(height: 12),
                Text(
                  book.description ?? 'No description available.',
                  style: textTheme.bodyMedium?.copyWith(height: 1.6),
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
    ReadingStatus.reading => AppTheme.primary,
    ReadingStatus.read => AppTheme.primary,
    ReadingStatus.toRead => AppTheme.secondary,
    ReadingStatus.dnf => AppTheme.outline,
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

// ─── Star Rating Bottom Sheet — Editorial ─────────────────────────────────────
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
        color: AppTheme.surfaceContainerLowest,
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
              color: AppTheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),

          // Trophy
          const Text('🎉', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 14),
          Text(
            'You finished the book!',
            style: GoogleFonts.notoSerif(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.bookTitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppTheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 28),

          // Stars
          Text(
            'How would you rate it?',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
            ),
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
                    color: filled ? const Color(0xFFD4A84B) : AppTheme.outlineVariant,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            _selectedRating == 0 ? 'Tap a star to rate'
            : ['', '😕 Poor', '😐 Fair', '🙂 Good', '😊 Great', '🤩 Amazing!'][_selectedRating],
            style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 28),

          // Submit
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(32),
              ),
              child: FilledButton(
                onPressed: (_selectedRating == 0 || _saving) ? null : () async {
                  setState(() => _saving = true);
                  await widget.onRate(_selectedRating);
                  if (mounted) setState(() => _saving = false);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: _saving
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.onPrimary))
                  : Text('Submit Rating', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Skip', style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}
