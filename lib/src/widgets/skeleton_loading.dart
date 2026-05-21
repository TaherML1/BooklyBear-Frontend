import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A shimmer effect widget that renders animated loading placeholders.
/// Uses warm parchment-themed colors to match the editorial design system.
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  const ShimmerEffect({super.key, required this.child});

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                AppTheme.surfaceContainerHigh,
                AppTheme.surfaceContainerLowest,
                AppTheme.surfaceContainerHigh,
              ],
              stops: [
                (_controller.value - 0.3).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.3).clamp(0.0, 1.0),
              ],
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(2.0, 0.3),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

/// A single rounded placeholder block used inside shimmer layouts.
class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Mimics a book card layout (cover rectangle + text lines).
class BookCardSkeleton extends StatelessWidget {
  const BookCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration,
        child: Row(
          children: [
            const _SkeletonBox(width: 60, height: 90, borderRadius: 8),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBox(width: double.infinity, height: 16),
                  const SizedBox(height: 8),
                  _SkeletonBox(width: 120, height: 12),
                  const SizedBox(height: 12),
                  _SkeletonBox(width: 80, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mimics a social post card (avatar + text + actions).
class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _SkeletonBox(width: 40, height: 40, borderRadius: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: 100, height: 14),
                    const SizedBox(height: 4),
                    _SkeletonBox(width: 60, height: 10),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SkeletonBox(width: double.infinity, height: 14),
            const SizedBox(height: 6),
            _SkeletonBox(width: 200, height: 14),
            const SizedBox(height: 16),
            Row(
              children: [
                _SkeletonBox(width: 24, height: 24, borderRadius: 12),
                const SizedBox(width: 8),
                _SkeletonBox(width: 30, height: 12),
                const SizedBox(width: 24),
                _SkeletonBox(width: 24, height: 24, borderRadius: 12),
                const SizedBox(width: 8),
                _SkeletonBox(width: 30, height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Mimics a group card (avatar + title + subtitle).
class GroupCardSkeleton extends StatelessWidget {
  const GroupCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration,
        child: Row(
          children: [
            const _SkeletonBox(width: 48, height: 48, borderRadius: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBox(width: double.infinity, height: 16),
                  const SizedBox(height: 8),
                  _SkeletonBox(width: 140, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mimics a stat row (3 columns).
class StatRowSkeleton extends StatelessWidget {
  const StatRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          3,
          (_) => Column(
            children: [
              const _SkeletonBox(width: 32, height: 32, borderRadius: 16),
              const SizedBox(height: 8),
              _SkeletonBox(width: 40, height: 16),
              const SizedBox(height: 4),
              _SkeletonBox(width: 50, height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mimics a profile header (large avatar + text).
class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const _SkeletonBox(width: 88, height: 88, borderRadius: 44),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBox(width: 160, height: 24),
                  const SizedBox(height: 8),
                  _SkeletonBox(width: 100, height: 14),
                  const SizedBox(height: 12),
                  _SkeletonBox(width: double.infinity, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A convenience widget that produces a list of skeleton items.
class SkeletonList extends StatelessWidget {
  final Widget Function() skeletonBuilder;
  final int count;
  final double spacing;

  const SkeletonList({
    super.key,
    required this.skeletonBuilder,
    this.count = 5,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(
          count,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: i < count - 1 ? spacing : 0),
            child: skeletonBuilder(),
          ),
        ),
      ),
    );
  }
}
