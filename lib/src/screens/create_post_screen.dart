import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../features/social/data/post_repository.dart';
import '../features/books/domain/book.dart';
import '../features/books/data/book_repository.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  
  bool _isSubmitting = false;
  Book? _selectedBook;
  List<String> _tags = [];
  
  @override
  void dispose() {
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    if (tag.trim().isNotEmpty && _tags.length < 3 && !_tags.contains(tag.trim())) {
      setState(() {
        _tags.add(tag.trim());
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _submitPost() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmitting = true);
    
    try {
      await ref.read(postRepositoryProvider).createPost(
        content,
        bookId: _selectedBook?.id,
        tags: _tags,
      );
      
      // Invalidate timeline so it refreshes when we go back
      ref.invalidate(timelineProvider);
      
      if (mounted) {
        context.pop(); // Go back to feed
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: $e')),
        );
      }
    }
  }

  Future<void> _showBookSearchDialog() async {
    final selected = await showModalBottomSheet<Book>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _BookSearchSheet(),
    );

    if (selected != null) {
      setState(() {
        _selectedBook = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = _contentController.text.trim().isNotEmpty;
    
    return Scaffold(
      backgroundColor: AppTheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceContainerLowest,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'New Post',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: FilledButton(
              onPressed: (hasContent && !_isSubmitting) ? _submitPost : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.onPrimary,
                disabledBackgroundColor: AppTheme.surfaceContainerHighest,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: _isSubmitting 
                  ? const SizedBox(
                      width: 16, height: 16, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    )
                  : const Text('Post', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Text Area
                    TextField(
                      controller: _contentController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.inter(fontSize: 18, color: AppTheme.onSurface),
                      decoration: InputDecoration(
                        hintText: "What are your thoughts?",
                        hintStyle: GoogleFonts.inter(fontSize: 18, color: AppTheme.outline),
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Selected Book Display
                    if (_selectedBook != null) ...[
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.outlineVariant.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _selectedBook!.coverImageUrl.isNotEmpty ? CachedNetworkImage(
                                    imageUrl: _selectedBook!.coverImageUrl,
                                    width: 50,
                                    height: 75,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      width: 50, height: 75, color: AppTheme.surfaceContainerHighest,
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      width: 50, height: 75, color: AppTheme.surfaceContainerHighest,
                                      child: const Icon(Icons.book, color: AppTheme.outline),
                                    ),
                                  ) : Container(
                                      width: 50, height: 75, color: AppTheme.surfaceContainerHighest,
                                      child: const Icon(Icons.book, color: AppTheme.outline),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedBook!.title,
                                        style: GoogleFonts.notoSerif(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: AppTheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _selectedBook!.author,
                                        style: GoogleFonts.inter(
                                          color: AppTheme.onSurfaceVariant,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: -10,
                            right: -10,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedBook = null),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: AppTheme.error,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Tags Display
                    if (_tags.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _tags.map((tag) => Chip(
                          label: Text('#$tag', style: GoogleFonts.inter(color: AppTheme.onPrimaryContainer, fontWeight: FontWeight.w500)),
                          backgroundColor: AppTheme.primaryContainer,
                          side: BorderSide.none,
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () => _removeTag(tag),
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Add Tag Input (if less than 3)
                    if (_tags.length < 3)
                      TextField(
                        controller: _tagController,
                        onSubmitted: _addTag,
                        style: GoogleFonts.inter(fontSize: 15, color: AppTheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Add a tag (e.g., SciFi, Review)',
                          hintStyle: GoogleFonts.inter(color: AppTheme.outline, fontSize: 15),
                          prefixIcon: const Icon(Icons.tag, size: 20, color: AppTheme.outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: AppTheme.surfaceContainerLow,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                border: Border(top: BorderSide(color: AppTheme.outlineVariant.withOpacity(0.5))),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _showBookSearchDialog,
                    icon: const Icon(Icons.book, color: AppTheme.primary),
                    tooltip: 'Tag a Book',
                  ),
                  IconButton(
                    onPressed: () {
                      // Just focus the tag input or scroll down
                    },
                    icon: const Icon(Icons.tag, color: AppTheme.primary),
                    tooltip: 'Add Tags',
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

/// A bottom sheet for searching and selecting a book to tag
class _BookSearchSheet extends ConsumerStatefulWidget {
  const _BookSearchSheet();

  @override
  ConsumerState<_BookSearchSheet> createState() => _BookSearchSheetState();
}

class _BookSearchSheetState extends ConsumerState<_BookSearchSheet> {
  final _searchController = TextEditingController();
  List<Book> _results = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _results = [];
    });
    
    try {
      final results = await ref.read(bookRepositoryProvider).searchBooks(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Tag a Book', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onSubmitted: _performSearch,
              decoration: InputDecoration(
                hintText: 'Search for a book...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ) : null,
                filled: true,
                fillColor: AppTheme.surfaceContainerLow,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: _results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final book = _results[index];
                return ListTile(
                  onTap: () => Navigator.of(context).pop(book),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: book.coverImageUrl.isNotEmpty ? CachedNetworkImage(
                      imageUrl: book.coverImageUrl,
                      width: 40, height: 60, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const Icon(Icons.book),
                    ) : Container(
                      width: 40, height: 60, color: AppTheme.surfaceContainerHighest,
                      child: const Icon(Icons.book),
                    ),
                  ),
                  title: Text(book.title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  subtitle: Text(book.author),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  tileColor: AppTheme.surfaceContainerLow,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
