import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../domain/user_book.dart';
import '../../../theme/app_theme.dart';
import 'book_palette_provider.dart';

import '../data/library_local_service.dart';

/// A realistic bookshelf view that renders books on wooden shelves.
class BookshelfView extends StatelessWidget {
  final List<UserBook> books;
  final Map<String, BookDisplayStyle> displayStyles;

  const BookshelfView({
    super.key,
    required this.books,
    required this.displayStyles,
  });

  // Deterministic "random" based on ISBN to decide cover vs spine
  static bool _shouldShowCover(String isbn) {
    final hash = isbn.hashCode.abs();
    // ~30% of books show their cover face-out
    return hash % 10 < 3;
  }

  // Deterministic spine width variation
  static double _spineWidth(String isbn, int pageCount) {
    // Thicker books = wider spines, with some randomness
    final base = (pageCount / 15).clamp(
      24.0,
      42.0,
    ); // Made slightly thicker for readability
    final jitter = (isbn.hashCode.abs() % 10) - 5;
    return base + jitter;
  }

  // Deterministic height variation for organic look
  static double _bookHeight(String isbn) {
    const heights = [150.0, 160.0, 170.0, 145.0, 165.0, 155.0, 175.0, 148.0];
    return heights[isbn.hashCode.abs() % heights.length];
  }

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shelves, size: 72, color: AppTheme.outlineVariant),
            const SizedBox(height: 20),
            Text(
              'Your shelf is empty.\nDiscover books to fill it!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppTheme.onSurfaceVariant,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    // Chunk books into rows of variable size (2-4) for organic look
    final shelves = <List<UserBook>>[];
    int i = 0;
    int shelfIndex = 0;
    while (i < books.length) {
      // Vary shelf capacity: 2, 3, 4 books per shelf
      final capacities = [3, 4, 3, 2, 4];
      final capacity = capacities[shelfIndex % capacities.length];
      final end = (i + capacity).clamp(0, books.length);
      shelves.add(books.sublist(i, end));
      i = end;
      shelfIndex++;
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 100),
      itemCount: shelves.length,
      itemBuilder: (context, index) => _ShelfRow(
        books: shelves[index],
        shelfIndex: index,
        displayStyles: displayStyles,
      ),
    );
  }
}

class _ShelfRow extends StatelessWidget {
  final List<UserBook> books;
  final int shelfIndex;
  final Map<String, BookDisplayStyle> displayStyles;

  const _ShelfRow({
    required this.books,
    required this.shelfIndex,
    required this.displayStyles,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // The books row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          constraints: const BoxConstraints(minHeight: 160),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(width: (shelfIndex * 17 % 24).toDouble()),
              ...books.map((ub) {
                final explicitStyle =
                    displayStyles[ub.book.isbn] ?? BookDisplayStyle.auto;

                if (explicitStyle == BookDisplayStyle.flat) {
                  return _FlatBook(userBook: ub);
                } else if (explicitStyle == BookDisplayStyle.cover) {
                  return _CoverBook(userBook: ub);
                } else if (explicitStyle == BookDisplayStyle.spine) {
                  return _SpineBook(userBook: ub);
                } else {
                  // Fallback to auto
                  final showCover = BookshelfView._shouldShowCover(
                    ub.book.isbn,
                  );
                  if (showCover) {
                    return _CoverBook(userBook: ub);
                  } else {
                    return _SpineBook(userBook: ub);
                  }
                }
              }),
              const Spacer(),
            ],
          ),
        ),
        // The wooden shelf plank
        const _WoodenShelf(),
      ],
    );
  }
}

class _CoverBook extends StatelessWidget {
  final UserBook userBook;

  const _CoverBook({required this.userBook});

  @override
  Widget build(BuildContext context) {
    final height = BookshelfView._bookHeight(userBook.book.isbn) + 10;

    return Padding(
      padding: const EdgeInsets.only(left: 6, right: 6),
      child: GestureDetector(
        onTap: () => context.push('/book/${userBook.book.isbn}'),
        child: Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 8,
                offset: const Offset(3, 4),
              ),
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 2,
                offset: const Offset(1, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              userBook.book.coverImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF5D4037),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Text(
                      userBook.book.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSerif(
                        color: Colors.white.withAlpha(200),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpineBook extends ConsumerWidget {
  final UserBook userBook;

  const _SpineBook({required this.userBook});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dynamically grab color using Palette Generator
    final color = ref
        .watch(bookPaletteProvider.notifier)
        .getColorSync(userBook.book.isbn, userBook.book.coverImageUrl);

    final width = BookshelfView._spineWidth(
      userBook.book.isbn,
      userBook.book.pageCount,
    );
    final height = BookshelfView._bookHeight(userBook.book.isbn);

    // Deepen the color slightly so spines look rich and less pastel
    final Color richColor = HSLColor.fromColor(color)
        .withSaturation(
          (HSLColor.fromColor(color).saturation * 1.2).clamp(0.0, 1.0),
        )
        .withLightness(
          (HSLColor.fromColor(color).lightness * 0.8).clamp(0.0, 1.0),
        )
        .toColor();

    final highlightColor = Color.lerp(richColor, Colors.white, 0.2)!;
    final shadowColor = Color.lerp(richColor, Colors.black, 0.3)!;

    return Padding(
      padding: const EdgeInsets.only(left: 1, right: 1),
      child: GestureDetector(
        onTap: () => context.push('/book/${userBook.book.isbn}'),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [highlightColor, richColor, richColor, shadowColor],
              stops: const [0.0, 0.1, 0.85, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 5,
                offset: const Offset(3, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Subtle Leather Texture Overlay (simulated via noise)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.05,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black, Colors.white, Colors.black],
                        stops: const [0.1, 0.5, 0.9],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
              // Subtle top edge (book pages)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 3,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8E1CE), // aged paper color
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(3),
                    ),
                  ),
                ),
              ),
              // Spine Gold Ribbing (classic book look)
              const Positioned(
                top: 15,
                left: 0,
                right: 0,
                child: _GoldFoilStripe(),
              ),
              const Positioned(
                bottom: 15,
                left: 0,
                right: 0,
                child: _GoldFoilStripe(),
              ),
              // Title — rotated vertically
              Padding(
                padding: const EdgeInsets.only(top: 25, bottom: 25),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        userBook.book.title.toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSerif(
                          color: const Color(0xFFE8CF94), // Gold foil text
                          fontSize: width > 32 ? 11 : 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                          shadows: [
                            BoxShadow(
                              color: Colors.black.withAlpha(100),
                              blurRadius: 2,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoldFoilStripe extends StatelessWidget {
  const _GoldFoilStripe();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFC8A14B),
            const Color(0xFFF0E0AB),
            const Color(0xFFC8A14B),
            const Color(0xFF8B6B2B),
          ],
          stops: const [0.0, 0.4, 0.7, 1.0],
        ),
      ),
    );
  }
}

/// The wooden shelf plank
class _WoodenShelf extends StatelessWidget {
  const _WoodenShelf();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18, // slightly thicker shelf
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF5D4037),
        image: const DecorationImage(
          image: NetworkImage(
            // Use a subtle wood grain tile if available, else relying on gradients
            'https://www.transparenttextures.com/patterns/wood-pattern.png',
          ),
          repeat: ImageRepeat.repeat,
          opacity: 0.15,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF6D4C41), // top light edge
            Color(0xFF4E342E), // main face
            Color(0xFF3E2723), // bottom dark
          ],
          stops: [0.0, 0.3, 1.0],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(70),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Container(
        // The top glossy edge reflection
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(5)),
          border: Border(
            top: BorderSide(color: Colors.white.withAlpha(20), width: 1),
          ),
        ),
      ),
    );
  }
}

class _FlatBook extends ConsumerWidget {
  final UserBook userBook;

  const _FlatBook({required this.userBook});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dynamically grab color using Palette Generator
    final color = ref
        .watch(bookPaletteProvider.notifier)
        .getColorSync(userBook.book.isbn, userBook.book.coverImageUrl);

    final thickness = BookshelfView._spineWidth(
      userBook.book.isbn,
      userBook.book.pageCount,
    );
    // Flat books don't need to be as wide as leaning books are tall
    final stackWidth = BookshelfView._bookHeight(userBook.book.isbn) * 0.85;

    // Deepen the color slightly
    final Color richColor = HSLColor.fromColor(color)
        .withSaturation(
          (HSLColor.fromColor(color).saturation * 1.2).clamp(0.0, 1.0),
        )
        .withLightness(
          (HSLColor.fromColor(color).lightness * 0.8).clamp(0.0, 1.0),
        )
        .toColor();

    final highlightColor = Color.lerp(richColor, Colors.white, 0.2)!;
    final shadowColor = Color.lerp(richColor, Colors.black, 0.3)!;

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4),
      child: GestureDetector(
        onTap: () => context.push('/book/${userBook.book.isbn}'),
        child: Container(
          width: stackWidth,
          height: thickness,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [highlightColor, richColor, richColor, shadowColor],
              stops: const [0.0, 0.1, 0.85, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 4,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Cover pages overlap (white pages showing on the right edge)
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: 3,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8E1CE), // aged paper color
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(3),
                    ),
                  ),
                ),
              ),
              // Spine Gold Ribbing (classic book look)
              const Positioned(
                left: 15,
                top: 0,
                bottom: 0,
                child: _GoldFoilVerticalStripe(),
              ),
              const Positioned(
                right: 15,
                top: 0,
                bottom: 0,
                child: _GoldFoilVerticalStripe(),
              ),
              // Title — horizontal
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    userBook.book.title.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSerif(
                      color: const Color(0xFFE8CF94), // Gold foil text
                      fontSize: thickness > 32 ? 11 : 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      shadows: [
                        BoxShadow(
                          color: Colors.black.withAlpha(100),
                          blurRadius: 2,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoldFoilVerticalStripe extends StatelessWidget {
  const _GoldFoilVerticalStripe();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFC8A14B),
            const Color(0xFFF0E0AB),
            const Color(0xFFC8A14B),
            const Color(0xFF8B6B2B),
          ],
          stops: const [0.0, 0.4, 0.7, 1.0],
        ),
      ),
    );
  }
}
