import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../data/review_repository.dart';
import '../domain/book_review.dart';
import '../../../theme/app_theme.dart';

class BookReviewsSection extends ConsumerStatefulWidget {
  final String isbn;
  const BookReviewsSection({super.key, required this.isbn});

  @override
  ConsumerState<BookReviewsSection> createState() => _BookReviewsSectionState();
}

class _BookReviewsSectionState extends ConsumerState<BookReviewsSection> {
  final TextEditingController _reviewController = TextEditingController();
  int _selectedDraftRating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final text = _reviewController.text.trim();
    if (text.isEmpty && _selectedDraftRating == 0) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(reviewRepositoryProvider).upsertReview(
            isbn: widget.isbn,
            rating: _selectedDraftRating > 0 ? _selectedDraftRating : null,
            reviewText: text.isNotEmpty ? text : null,
          );
      _reviewController.clear();
      setState(() => _selectedDraftRating = 0);
      ref.invalidate(bookReviewsProvider(widget.isbn));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Review posted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(bookReviewsProvider(widget.isbn));
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Community Reviews',
          style: textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        
        // Write a review section — editorial card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('Rate this book: ', style: GoogleFonts.inter(color: AppTheme.onSurface, fontSize: 14)),
                  Row(
                    children: List.generate(5, (i) {
                      final filled = i < _selectedDraftRating;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDraftRating = i + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Icon(
                            filled ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: filled ? const Color(0xFFD4A84B) : AppTheme.outlineVariant,
                            size: 28,
                          ),
                        ),
                      );
                    }),
                  )
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _reviewController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'What did you think of the book?',
                  filled: true,
                  fillColor: AppTheme.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submitReview,
                  icon: _isSubmitting 
                   ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                   : const Icon(Icons.send, size: 18),
                  label: const Text('Post Review'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Reviews list
        reviewsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading reviews', style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant))),
          data: (paginated) {
            if (paginated.reviews.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'No reviews yet. Be the first to review!',
                    style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: paginated.reviews.length,
              separatorBuilder: (_, __) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final review = paginated.reviews[index];
                return _ReviewCard(review: review);
              },
            );
          },
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final BookReview review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final user = review.user;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryFixed,
                backgroundImage: user.avatarUrl != null ? CachedNetworkImageProvider(user.avatarUrl!) : null,
                child: user.avatarUrl == null
                    ? Text(
                        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                        style: GoogleFonts.notoSerif(
                          color: AppTheme.onPrimaryFixed,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '@${user.username} • Level ${user.level}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Text(
                timeago.format(DateTime.parse(review.createdAt)),
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (review.rating != null)
            Row(
              children: List.generate(5, (i) {
                return Icon(
                  i < review.rating! ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: const Color(0xFFD4A84B), // warm gold
                  size: 18,
                );
              }),
            ),
          if (review.rating != null && review.reviewText != null && review.reviewText!.isNotEmpty)
            const SizedBox(height: 10),
          if (review.reviewText != null && review.reviewText!.isNotEmpty)
            Text(
              review.reviewText!,
              style: GoogleFonts.inter(color: AppTheme.onSurface, height: 1.6),
            ),
        ],
      ),
    );
  }
}
