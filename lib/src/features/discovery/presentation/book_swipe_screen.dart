import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../books/domain/book.dart';
import '../data/swipe_repository.dart';

class BookSwipeScreen extends ConsumerStatefulWidget {
  const BookSwipeScreen({super.key});

  @override
  ConsumerState<BookSwipeScreen> createState() => _BookSwipeScreenState();
}

class _BookSwipeScreenState extends ConsumerState<BookSwipeScreen>
    with TickerProviderStateMixin {
  List<Book> _deck = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _error;

  // Drag state
  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0;
  late AnimationController _flyAwayController;
  late AnimationController _nextCardController;
  Offset _flyDirection = Offset.zero;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _flyAwayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _nextCardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _flyAwayController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onCardDismissed();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDeck());
  }

  @override
  void dispose() {
    _flyAwayController.dispose();
    _nextCardController.dispose();
    super.dispose();
  }

  Future<void> _loadDeck() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(swipeRepositoryProvider);
      final books = await repo.getSwipeDeck();
      if (mounted) {
        setState(() {
          _deck = books;
          _currentIndex = 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (_isAnimating) return;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    setState(() {
      _dragOffset += details.delta;
      _dragAngle = _dragOffset.dx / 300 * 0.4; // Subtle tilt
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isAnimating) return;
    final dx = _dragOffset.dx;
    const threshold = 100.0;

    if (dx.abs() > threshold) {
      final direction = dx > 0 ? 'like' : 'skip';
      _animateFlyAway(direction);
    } else {
      // Spring back
      setState(() {
        _dragOffset = Offset.zero;
        _dragAngle = 0;
      });
    }
  }

  void _animateFlyAway(String direction) {
    _isAnimating = true;
    HapticFeedback.mediumImpact();

    final screenWidth = MediaQuery.of(context).size.width;
    _flyDirection = Offset(
      direction == 'like' ? screenWidth * 1.5 : -screenWidth * 1.5,
      _dragOffset.dy,
    );

    _flyAwayController.forward(from: 0);

    // Record the swipe
    if (_currentIndex < _deck.length) {
      final book = _deck[_currentIndex];
      ref.read(swipeRepositoryProvider).recordSwipe(
            bookId: book.id,
            direction: direction,
          );
    }
  }

  void _onCardDismissed() {
    setState(() {
      _currentIndex++;
      _dragOffset = Offset.zero;
      _dragAngle = 0;
      _isAnimating = false;
    });
    _flyAwayController.reset();
    _nextCardController.forward(from: 0);
  }

  void _onLikePressed() {
    if (_isAnimating || _currentIndex >= _deck.length) return;
    _animateFlyAway('like');
  }

  void _onSkipPressed() {
    if (_isAnimating || _currentIndex >= _deck.length) return;
    _animateFlyAway('skip');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Discover',
          style: GoogleFonts.notoSerif(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : _currentIndex >= _deck.length
                  ? _buildEmptyView()
                  : _buildSwipeView(),
    );
  }

  Widget _buildSwipeView() {
    final screenSize = MediaQuery.of(context).size;
    final cardHeight = screenSize.height * 0.62;
    final remaining = _deck.length - _currentIndex;

    return Column(
      children: [
        // Counter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$remaining books left',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.swipe, size: 16, color: AppTheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'Swipe to discover',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Card Stack
        Expanded(
          child: Center(
            child: SizedBox(
              width: screenSize.width - 48,
              height: cardHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background card (next card preview)
                  if (_currentIndex + 1 < _deck.length)
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _nextCardController,
                        builder: (context, child) {
                          final scale = 0.95 + (_nextCardController.value * 0.05);
                          return Transform.scale(
                            scale: scale,
                            child: child,
                          );
                        },
                        child: _BookCard(
                          book: _deck[_currentIndex + 1],
                          isBehind: true,
                        ),
                      ),
                    ),

                  // Front card (draggable)
                  AnimatedBuilder(
                    animation: _flyAwayController,
                    builder: (context, child) {
                      Offset currentOffset;
                      double currentAngle;

                      if (_flyAwayController.isAnimating ||
                          _flyAwayController.isCompleted) {
                        final t = Curves.easeIn.transform(
                            _flyAwayController.value);
                        currentOffset = Offset.lerp(
                            _dragOffset, _flyDirection, t)!;
                        currentAngle = _dragAngle +
                            (_flyDirection.dx > 0 ? 0.3 : -0.3) * t;
                      } else {
                        currentOffset = _dragOffset;
                        currentAngle = _dragAngle;
                      }

                      final swipeProgress =
                          (currentOffset.dx / 150).clamp(-1.0, 1.0);

                      return Transform.translate(
                        offset: currentOffset,
                        child: Transform.rotate(
                          angle: currentAngle,
                          child: Stack(
                            children: [
                              _BookCard(
                                book: _deck[_currentIndex],
                                isBehind: false,
                              ),
                              // Like overlay
                              if (swipeProgress > 0.1)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      color: Colors.green.withAlpha(
                                          (swipeProgress * 80).toInt()),
                                    ),
                                    child: Center(
                                      child: Opacity(
                                        opacity: swipeProgress.clamp(0, 1),
                                        child: Transform.rotate(
                                          angle: -0.3,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 10),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: Colors.green,
                                                  width: 3),
                                            ),
                                            child: Text(
                                              'LIKE',
                                              style: GoogleFonts.inter(
                                                fontSize: 36,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              // Skip overlay
                              if (swipeProgress < -0.1)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      color: Colors.red.withAlpha(
                                          (swipeProgress.abs() * 80).toInt()),
                                    ),
                                    child: Center(
                                      child: Opacity(
                                        opacity:
                                            swipeProgress.abs().clamp(0, 1),
                                        child: Transform.rotate(
                                          angle: 0.3,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 10),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: Colors.red, width: 3),
                                            ),
                                            child: Text(
                                              'SKIP',
                                              style: GoogleFonts.inter(
                                                fontSize: 36,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Gesture detector on top
                  Positioned.fill(
                    child: GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      onTap: () {
                        if (_currentIndex < _deck.length) {
                          context.push('/book/${_deck[_currentIndex].isbn}');
                        }
                      },
                      behavior: HitTestBehavior.translucent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(48, 16, 48, 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Skip
              _ActionButton(
                icon: Icons.close_rounded,
                color: AppTheme.error,
                size: 56,
                onTap: _onSkipPressed,
              ),
              // View Details
              _ActionButton(
                icon: Icons.info_outline_rounded,
                color: AppTheme.onSurfaceVariant,
                size: 44,
                onTap: () {
                  if (_currentIndex < _deck.length) {
                    context.push('/book/${_deck[_currentIndex].isbn}');
                  }
                },
              ),
              // Like
              _ActionButton(
                icon: Icons.favorite_rounded,
                color: Colors.green,
                size: 56,
                onTap: _onLikePressed,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              "You're all caught up!",
              style: GoogleFonts.notoSerif(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new book recommendations.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _loadDeck,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh Deck'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadDeck,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Book Card Widget
// ═══════════════════════════════════════════════════════════════════════════════

class _BookCard extends StatelessWidget {
  final Book book;
  final bool isBehind;

  const _BookCard({required this.book, required this.isBehind});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: isBehind
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Cover image
            book.coverImageUrl.isNotEmpty
                ? Image.network(
                    book.coverImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppTheme.surfaceContainerHigh,
                      child: const Center(
                        child: Icon(Icons.book_rounded, size: 64,
                            color: AppTheme.onSurfaceVariant),
                      ),
                    ),
                  )
                : Container(
                    color: AppTheme.surfaceContainerHigh,
                    child: const Center(
                      child: Icon(Icons.book_rounded, size: 64,
                          color: AppTheme.onSurfaceVariant),
                    ),
                  ),

            // Gradient overlay for text readability
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withAlpha(60),
                      Colors.black.withAlpha(200),
                    ],
                    stops: const [0.0, 0.45, 0.7, 1.0],
                  ),
                ),
              ),
            ),

            // Text info at the bottom
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSerif(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tags row
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (book.pageCount > 0) _InfoChip('${book.pageCount} pages'),
                      if (book.averageRating != null)
                        _InfoChip('★ ${book.averageRating!.toStringAsFixed(1)}'),
                      ...book.categories.take(2).map((c) => _InfoChip(c)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Tap to view details',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withAlpha(140),
                      fontStyle: FontStyle.italic,
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

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(35),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withAlpha(50)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white.withAlpha(220),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Action Button
// ═══════════════════════════════════════════════════════════════════════════════

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.surfaceContainerLowest,
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(30),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withAlpha(60), width: 2),
        ),
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }
}
