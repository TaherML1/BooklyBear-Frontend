import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../books/domain/book.dart';
import '../../books/domain/recommendation.dart';
import '../../books/data/recommendation_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Books For You — Full Recommendations Screen
// Powered by Item-Based KNN (MSD Similarity)
// ═══════════════════════════════════════════════════════════════════════════════

class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recAsync = ref.watch(recommendationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
            backgroundColor: AppTheme.surface,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppTheme.onSurface,
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Padding(
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryFixed,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 12,
                            color: AppTheme.onPrimaryFixed,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'AI-Powered · KNN',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.onPrimaryFixed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              title: Text(
                'Books For You',
                style: GoogleFonts.notoSerif(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
              titlePadding: const EdgeInsetsDirectional.fromSTEB(56, 0, 16, 16),
            ),
          ),

          // ── Body ───────────────────────────────────────────────────────────
          recAsync.when(
            loading: () => const SliverFillRemaining(child: _LoadingView()),
            error: (err, _) =>
                SliverFillRemaining(child: _ErrorView(error: err.toString())),
            data: (recs) {
              if (recs.isEmpty) {
                return const SliverFillRemaining(child: _ColdStartView());
              }
              return _RecommendationsList(recommendations: recs);
            },
          ),
        ],
      ),
    );
  }
}

// ─── Recommendations List ─────────────────────────────────────────────────────

class _RecommendationsList extends StatelessWidget {
  final List<Recommendation> recommendations;

  const _RecommendationsList({required this.recommendations});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final rec = recommendations[index];
          return _RecommendationCard(recommendation: rec, rank: index + 1);
        }, childCount: recommendations.length),
      ),
    );
  }
}

// ─── Recommendation Card ──────────────────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  final Recommendation recommendation;
  final int rank;

  const _RecommendationCard({required this.recommendation, required this.rank});

  @override
  Widget build(BuildContext context) {
    final book = recommendation.book;
    final score = recommendation.score;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => context.push('/book/${book.isbn}'),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.ambientShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cover ───────────────────────────────────────────────────
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                child: SizedBox(
                  width: 90,
                  height: 130,
                  child: book.coverImageUrl.isNotEmpty
                      ? Image.network(
                          book.coverImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _CoverPlaceholder(book),
                        )
                      : _CoverPlaceholder(book),
                ),
              ),

              // ── Info ─────────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rank + match score
                      Row(
                        children: [
                          Text(
                            '#$rank',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          _MatchBadge(score: score),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Title
                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSerif(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurface,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Author
                      Text(
                        book.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),

                      // Explanation
                      if (recommendation.explanation != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          recommendation.explanation!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.outline,
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ],

                      // Category chips
                      if (book.categories.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          children: book.categories.take(2).map((cat) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryFixed,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                cat,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.onPrimaryFixed,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
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

// ─── Match Score Badge ────────────────────────────────────────────────────────

class _MatchBadge extends StatelessWidget {
  final double score;
  const _MatchBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final pct = (score * 100).clamp(0, 100).toInt();
    final Color badgeColor = pct >= 75
        ? const Color(0xFF2D6A4F)
        : pct >= 50
        ? const Color(0xFF4D7E5B)
        : AppTheme.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(20),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: badgeColor.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 10,
            color: badgeColor,
          ),
          const SizedBox(width: 3),
          Text(
            '$pct% match',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cover Placeholder ────────────────────────────────────────────────────────

class _CoverPlaceholder extends StatelessWidget {
  final Book book;
  const _CoverPlaceholder(this.book);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceContainerHigh,
      child: Center(
        child: Text(
          book.title.isNotEmpty ? book.title[0].toUpperCase() : '?',
          style: GoogleFonts.notoSerif(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ─── Loading View ─────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 20),
          Text(
            'Finding your next great reads…',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'KNN model is computing similarities',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.outline,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cold Start View ──────────────────────────────────────────────────────────

class _ColdStartView extends StatelessWidget {
  const _ColdStartView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryFixed,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                size: 40,
                color: AppTheme.onPrimaryFixed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'We\'re still learning\nyour taste',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSerif(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Rate a few books in your library or add books you\'ve read to unlock personalized recommendations.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go('/library'),
              icon: const Icon(Icons.library_books_rounded, size: 18),
              label: const Text('Go to My Library'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.push('/discover'),
              icon: const Icon(Icons.swipe_rounded, size: 18),
              label: const Text('Discover & Rate Books'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  const _ErrorView({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: AppTheme.onSurfaceVariant,
            ),
            const SizedBox(height: 20),
            Text(
              'Could not load recommendations',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSerif(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The AI service may be offline.\nCheck back shortly.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
