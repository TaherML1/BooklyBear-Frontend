import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../utils/dio_client.dart';
import '../features/books/domain/book.dart';
import '../theme/app_theme.dart';
import '../widgets/book_cover_image.dart';

// ─── Provider: drives the search query string ────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');

// ─── Provider: fetches results whenever the query changes ────────────────────
final searchResultsProvider = FutureProvider<List<Book>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];

  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('/search', queryParameters: {'q': query});
    final hits = response.data['hits'] as List<dynamic>? ?? [];
    return hits
        .map((h) => Book.fromJson(h['document'] as Map<String, dynamic>? ?? {}))
        .where((book) => book.id.isNotEmpty) // Skip empty/corrupt entries
        .toList();
  } on DioException catch (e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      throw data['message'] ?? 'Search failed';
    }
    throw 'Search failed: ${e.message}';
  } catch (e) {
    rethrow;
  }
});

// ─── Screen ──────────────────────────────────────────────────────────────────
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    final initialQuery = ref.read(searchQueryProvider);
    _controller = TextEditingController(text: initialQuery);
    _lastQuery = initialQuery;
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = _controller.text.trim();
    if (text == _lastQuery) return;
    _lastQuery = text;

    // Debounce: wait 400ms after the user stops typing
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (_controller.text.trim() == text) {
        ref.read(searchQueryProvider.notifier).state = text;
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _controller,
            autofocus: false,
            decoration: InputDecoration(
              hintText: 'Search books by title or author…',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primary.withAlpha(51), width: 2),
              ),
              hintStyle: GoogleFonts.inter(color: AppTheme.outline, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: AppTheme.onSurfaceVariant),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppTheme.onSurfaceVariant),
                      onPressed: () {
                        _controller.clear();
                        ref.read(searchQueryProvider.notifier).state = '';
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
      body: query.isEmpty
          ? _EmptySearchState()
          : resultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Search error: $err',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant),
                  ),
                ),
              ),
              data: (books) {
                if (books.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppTheme.outlineVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No results for "$query"',
                          style: GoogleFonts.inter(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: books.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _BookSearchCard(book: books[i]),
                );
              },
            ),
    );
  }
}

// ─── Individual Search Result Card ───────────────────────────────────────────
class _BookSearchCard extends StatelessWidget {
  final Book book;
  const _BookSearchCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: AppTheme.cardDecoration,
      child: InkWell(
        onTap: () => context.push('/book/${book.isbn}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image with smart fallback
              BookCoverImage(
                coverImageUrl: book.coverImageUrl,
                bookTitle: book.title,
                width: 56,
                height: 82,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSerif(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (book.pageCount > 0) ...[
                          const Icon(
                            Icons.menu_book,
                            size: 13,
                            color: AppTheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${book.pageCount} pages',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                        if (book.categories.isNotEmpty) ...[
                          if (book.pageCount > 0)
                            Text(
                              ' · ',
                              style: GoogleFonts.inter(color: AppTheme.outlineVariant),
                            ),
                          Expanded(
                            child: Text(
                              book.categories.first,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.outlineVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty State (before user types anything) ────────────────────────────────
class _EmptySearchState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_stories, size: 80, color: AppTheme.outlineVariant),
          const SizedBox(height: 20),
          Text(
            'Discover your next book',
            style: GoogleFonts.notoSerif(
              fontSize: 18,
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type a title, author, or keyword',
            style: GoogleFonts.inter(
              color: AppTheme.outline,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
