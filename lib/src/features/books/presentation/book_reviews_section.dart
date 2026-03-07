import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../data/review_repository.dart';
import '../domain/book_review.dart';

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
           const SnackBar(content: Text('Review posted!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(bookReviewsProvider(widget.isbn));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Community Reviews',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // Write a review section
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('Rate this book: ', style: theme.textTheme.bodyMedium),
                    Row(
                      children: List.generate(5, (i) {
                        final filled = i < _selectedDraftRating;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedDraftRating = i + 1),
                          child: Icon(
                            filled ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: filled ? Colors.amber : Colors.grey[400],
                            size: 28,
                          ),
                        );
                      }),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reviewController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'What did you think of the book?',
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
        ),
        const SizedBox(height: 24),

        // Reviews list
        reviewsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading reviews')),
          data: (paginated) {
            if (paginated.reviews.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    'No reviews yet. Be the first to review!',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: paginated.reviews.length,
              separatorBuilder: (_, __) => const Divider(height: 32),
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
    final theme = Theme.of(context);
    final user = review.user;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.orange.shade100,
              backgroundImage: user.avatarUrl != null ? CachedNetworkImageProvider(user.avatarUrl!) : null,
              child: user.avatarUrl == null
                  ? Text(
                      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                      style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold),
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
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '@${user.username} • Level ${user.level}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Text(
              timeago.format(DateTime.parse(review.createdAt)),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (review.rating != null)
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < review.rating! ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.amber,
                size: 20,
              );
            }),
          ),
        if (review.rating != null && review.reviewText != null && review.reviewText!.isNotEmpty)
          const SizedBox(height: 8),
        if (review.reviewText != null && review.reviewText!.isNotEmpty)
          Text(
            review.reviewText!,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
      ],
    );
  }
}
