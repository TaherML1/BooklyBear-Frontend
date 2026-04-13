import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../data/post_repository.dart';
import '../domain/post.dart';
import '../../books/domain/book.dart';
import '../../../theme/app_theme.dart';

class SocialFeedSection extends ConsumerWidget {
  const SocialFeedSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(timelineProvider);

    return timelineAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading feed: $err')),
      data: (posts) {
        if (posts.isEmpty) {
          return const _EmptyFeedPlaceholder();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reflections',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            ...posts.map((post) => _PostCard(post: post)),
          ],
        );
      },
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: post.isDiscovery 
            ? AppTheme.surfaceContainerLow 
            : AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryFixed,
                backgroundImage: post.user.avatarUrl != null 
                    ? CachedNetworkImageProvider(post.user.avatarUrl!) 
                    : null,
                child: post.user.avatarUrl == null 
                    ? Text(
                        post.user.displayName.isNotEmpty 
                            ? post.user.displayName[0].toUpperCase() 
                            : '?',
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.user.displayName,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (post.isDiscovery) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.auto_awesome, size: 14, color: AppTheme.primary),
                        ],
                      ],
                    ),
                    Text(
                      timeago.format(post.createdAt),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            post.content,
            style: GoogleFonts.inter(
              color: AppTheme.onSurface,
              height: 1.5,
            ),
          ),
          if (post.book != null) ...[
            const SizedBox(height: 12),
            _BookTag(book: post.book!),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.favorite_border, size: 20, color: AppTheme.primary),
              const SizedBox(width: 4),
              Text(
                '${post.likeCount}',
                style: GoogleFonts.inter(
                  color: AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookTag extends StatelessWidget {
  final Book book;
  const _BookTag({required this.book});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/book/${book.isbn}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: book.coverImageUrl,
                width: 40,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 40,
                  height: 60,
                  color: AppTheme.surfaceContainerHighest,
                ),
                errorWidget: (context, url, error) => Container(
                  width: 40,
                  height: 60,
                  color: AppTheme.surfaceContainerHighest,
                  child: const Icon(Icons.book, size: 20, color: AppTheme.onSurfaceVariant),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSerif(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  Text(
                    book.author,
                    style: GoogleFonts.inter(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 12,
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

class _EmptyFeedPlaceholder extends StatelessWidget {
  const _EmptyFeedPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.library_books, size: 64, color: AppTheme.outlineVariant),
          const SizedBox(height: 12),
          Text(
            'Your Feed is Empty',
            style: GoogleFonts.notoSerif(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Discover books to start your journey!',
            style: GoogleFonts.inter(
              color: AppTheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(32),
            ),
            child: FilledButton.icon(
              onPressed: () => context.push('/search'),
              icon: const Icon(Icons.search),
              label: const Text('Discover Books'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
