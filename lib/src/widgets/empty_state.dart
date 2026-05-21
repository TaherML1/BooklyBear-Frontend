import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// A reusable empty state widget with animated icon, title, subtitle, and optional CTA.
class EmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? ctaLabel;
  final VoidCallback? onCtaPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.ctaLabel,
    this.onCtaPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
  });

  /// Library empty state
  factory EmptyState.library({VoidCallback? onDiscover}) => EmptyState(
        icon: Icons.auto_stories_outlined,
        title: 'Your library is waiting',
        subtitle: 'Search for books to start building your collection.',
        ctaLabel: 'Discover Books',
        onCtaPressed: onDiscover,
      );

  /// Groups empty state
  factory EmptyState.groups({VoidCallback? onCreate}) => EmptyState(
        icon: Icons.groups_outlined,
        title: 'No clubs yet',
        subtitle: 'Create or join a reading club to read together.',
        ctaLabel: 'Create Club',
        onCtaPressed: onCreate,
      );

  /// Friends empty state
  factory EmptyState.friends({VoidCallback? onFind}) => EmptyState(
        icon: Icons.people_outline,
        title: 'No friends yet',
        subtitle: 'Find readers who share your taste in books.',
        ctaLabel: 'Find Readers',
        onCtaPressed: onFind,
      );

  /// Feed empty state
  factory EmptyState.feed() => const EmptyState(
        icon: Icons.forum_outlined,
        title: 'Your feed is quiet',
        subtitle: 'Add friends or share your thoughts to see activity here.',
      );

  /// No results empty state
  factory EmptyState.noResults() => const EmptyState(
        icon: Icons.search_off,
        title: 'No results found',
        subtitle: 'Try a different search term or adjust your filters.',
      );

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _floatAnimation,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, -_floatAnimation.value),
                child: child,
              ),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryFixed,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  widget.icon,
                  size: 36,
                  color: AppTheme.onPrimaryFixed,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.title,
              style: GoogleFonts.notoSerif(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.subtitle,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.ctaLabel != null && widget.onCtaPressed != null) ...[
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: FilledButton(
                  onPressed: widget.onCtaPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    minimumSize: const Size(180, 48),
                  ),
                  child: Text(
                    widget.ctaLabel!,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
            if (widget.secondaryLabel != null &&
                widget.onSecondaryPressed != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.onSecondaryPressed,
                child: Text(widget.secondaryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
