import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/app_logger.dart';
import '../data/recommendation_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/book_cover_image.dart';

class BooksForYouSection extends ConsumerWidget {
  const BooksForYouSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync = ref.watch(recommendationsProvider);

    return recommendationsAsync.when(
      loading: () {
        AppLogger.info('[BooksForYou] Loading recommendations...');
        return const Center(child: CircularProgressIndicator());
      },
      error: (err, stack) {
        AppLogger.error('[BooksForYou] Error: $err');
        return const SizedBox.shrink(); // Silently hide on error in prod
      },
      data: (recommendations) {
        AppLogger.info('[BooksForYou] Received ${recommendations.length} recommendations');
        if (recommendations.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Curated For You',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                TextButton(
                  onPressed: () => context.push('/recommendations'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'See All →',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 260,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recommendations.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final rec = recommendations[index];
                  final book = rec.book;
                  
                  return SizedBox(
                    width: 120,
                    child: InkWell(
                      onTap: () => context.push('/book/${book.isbn}'),
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        // Cover — ambient shadow
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppTheme.ambientShadow,
                          ),
                          child: BookCoverImage(
                            coverImageUrl: book.coverImageUrl,
                            bookTitle: book.title,
                            width: 120,
                            height: 180,
                            borderRadius: 12,
                          ),
                        ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.notoSerif(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: AppTheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  book.author,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
