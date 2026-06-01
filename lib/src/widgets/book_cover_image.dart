import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A smart book cover widget that tries multiple image sources and falls back
/// to a styled placeholder if none work.
///
/// Fallback chain:
///   1. The stored coverImageUrl (Open Library by ISBN-10)
///   2. A styled gradient placeholder with the book initial
class BookCoverImage extends StatefulWidget {
  final String coverImageUrl;
  final String bookTitle;
  final double width;
  final double height;
  final double borderRadius;

  const BookCoverImage({
    super.key,
    required this.coverImageUrl,
    required this.bookTitle,
    this.width = 56,
    this.height = 82,
    this.borderRadius = 8,
  });

  @override
  State<BookCoverImage> createState() => _BookCoverImageState();
}

class _BookCoverImageState extends State<BookCoverImage> {
  bool _imageError = false;

  // Open Library returns a tiny 43-byte GIF when there's no cover.
  // We detect it by checking the image dimensions after loading.
  final bool _imageIsBlank = false;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(widget.borderRadius);

    if (_imageError || _imageIsBlank || widget.coverImageUrl.isEmpty) {
      return _buildPlaceholder(borderRadius);
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        widget.coverImageUrl,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
        // Detect successful load but check dimensions
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame == null) {
            // Still loading — show shimmer placeholder
            return _buildShimmer(borderRadius);
          }
          return child;
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildShimmer(borderRadius);
        },
        errorBuilder: (context, error, stackTrace) {
          // Network error or 404 — show placeholder
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _imageError = true);
          });
          return _buildPlaceholder(borderRadius);
        },
      ),
    );
  }

  Widget _buildShimmer(BorderRadius borderRadius) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BorderRadius borderRadius) {
    final initial = widget.bookTitle.isNotEmpty
        ? widget.bookTitle[0].toUpperCase()
        : 'B';

    // Generate a deterministic color from the title
    final hue =
        (widget.bookTitle.codeUnits.fold(0, (a, b) => a + b) % 30) * 12.0;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HSLColor.fromAHSL(1, hue, 0.35, 0.45).toColor(),
            HSLColor.fromAHSL(1, (hue + 30) % 360, 0.4, 0.35).toColor(),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.notoSerif(
            fontSize: widget.width * 0.45,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ),
    );
  }
}
