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
import 'post_comments_sheet.dart';

class SocialFeedSection extends ConsumerWidget {
  const SocialFeedSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(timelineProvider);

    return timelineAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading feed: $err')),
      data: (posts) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reflections',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),

            // ── Share a thought button ──
            _CreatePostPrompt(
              onTap: () {
                context.push('/create-post');
              },
            ),
            const SizedBox(height: 16),

            if (posts.isEmpty)
              const _EmptyFeedPlaceholder()
            else
              ...posts.map((post) => _PostCard(post: post)),
          ],
        );
      },
    );
  }
}

/// Tappable prompt that opens the create-post sheet.
class _CreatePostPrompt extends StatelessWidget {
  final VoidCallback onTap;
  const _CreatePostPrompt({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.edit_note, size: 22, color: AppTheme.outline),
            const SizedBox(width: 12),
            Text(
              'Share a thought about what you are reading...',
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends ConsumerStatefulWidget {
  final Post post;
  const _PostCard({required this.post});

  @override
  ConsumerState<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<_PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimController;
  late Animation<double> _likeScale;
  late Post _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _likeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _likeScale =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(parent: _likeAnimController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _likeAnimController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    // Optimistic update
    final wasLiked = _post.isLiked;
    setState(() {
      _post.isLiked = !wasLiked;
      _post.likeCount += wasLiked ? -1 : 1;
    });
    _likeAnimController.forward(from: 0);

    try {
      await ref.read(postRepositoryProvider).toggleLike(_post.id);
    } catch (_) {
      // Revert on error
      if (mounted) {
        setState(() {
          _post.isLiked = wasLiked;
          _post.likeCount += wasLiked ? 1 : -1;
        });
      }
    }
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PostCommentsSheet(postId: _post.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _post.isDiscovery
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
                backgroundImage: (_post.user.avatarUrl?.isNotEmpty == true)
                    ? CachedNetworkImageProvider(_post.user.avatarUrl!)
                    : null,
                child: (_post.user.avatarUrl?.isNotEmpty != true)
                    ? Text(
                        _post.user.displayName.isNotEmpty
                            ? _post.user.displayName[0].toUpperCase()
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
                            _post.user.displayName,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_post.isDiscovery) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: AppTheme.primary,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      timeago.format(_post.createdAt),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _post.content,
            style: GoogleFonts.inter(color: AppTheme.onSurface, height: 1.5),
          ),
          if (_post.book != null) ...[
            const SizedBox(height: 12),
            _BookTag(book: _post.book!),
          ],
          if (_post.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _post.tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '#$tag',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 14),

          // ── Like + Comment actions ──
          Row(
            children: [
              // Like button with animation
              GestureDetector(
                onTap: _toggleLike,
                child: ScaleTransition(
                  scale: _likeScale,
                  child: Icon(
                    _post.isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 22,
                    color: _post.isLiked ? AppTheme.error : AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${_post.likeCount}',
                style: GoogleFonts.inter(
                  color: AppTheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 24),
              // Comment button
              GestureDetector(
                onTap: _openComments,
                child: const Icon(
                  Icons.chat_bubble_outline,
                  size: 20,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _openComments,
                child: Text(
                  '${_post.commentCount}',
                  style: GoogleFonts.inter(
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
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
              child: book.coverImageUrl.isNotEmpty
                  ? CachedNetworkImage(
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
                        child: const Icon(
                          Icons.book,
                          size: 20,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Container(
                      width: 40,
                      height: 60,
                      color: AppTheme.surfaceContainerHighest,
                      child: const Icon(
                        Icons.book,
                        size: 20,
                        color: AppTheme.onSurfaceVariant,
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
          const Icon(
            Icons.forum_outlined,
            size: 64,
            color: AppTheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Your Feed is Quiet',
            style: GoogleFonts.notoSerif(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add friends or share your thoughts to see activity here.',
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
