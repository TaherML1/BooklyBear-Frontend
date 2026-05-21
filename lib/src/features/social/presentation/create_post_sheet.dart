import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../data/post_repository.dart';

/// Modal bottom sheet for creating a new post.
class CreatePostSheet extends ConsumerStatefulWidget {
  const CreatePostSheet({super.key});

  @override
  ConsumerState<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<CreatePostSheet> {
  final _controller = TextEditingController();
  bool _isPosting = false;
  static const int _maxLength = 500;

  int get _remaining => _maxLength - _controller.text.length;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _isPosting = true);
    try {
      await ref.read(postRepositoryProvider).createPost(content);
      ref.invalidate(timelineProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPost = _controller.text.trim().isNotEmpty && !_isPosting;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Handle ──
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ──
          Text(
            'Share a thought',
            style: GoogleFonts.notoSerif(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // ── Text field ──
          TextField(
            controller: _controller,
            maxLines: 5,
            minLines: 3,
            maxLength: _maxLength,
            decoration: InputDecoration(
              hintText: 'What are you reading? Share your thoughts...',
              hintStyle: GoogleFonts.inter(
                color: AppTheme.outline,
                fontSize: 14,
              ),
              counterText: '',
              filled: true,
              fillColor: AppTheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppTheme.primary.withAlpha(51),
                  width: 2,
                ),
              ),
            ),
          ),

          // ── Footer ──
          const SizedBox(height: 12),
          Row(
            children: [
              // Character counter
              Text(
                '$_remaining characters remaining',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: _remaining < 50
                      ? AppTheme.error
                      : AppTheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              // Post button
              Container(
                decoration: BoxDecoration(
                  gradient:
                      canPost ? AppTheme.primaryGradient : null,
                  color: canPost ? null : AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: FilledButton(
                  onPressed: canPost ? _submit : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    minimumSize: const Size(100, 44),
                  ),
                  child: _isPosting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Post',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: canPost
                                ? Colors.white
                                : AppTheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
