// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/library/presentation/library_providers.dart';
import '../features/library/presentation/bookshelf_view.dart';
import '../features/library/data/library_local_service.dart';
import '../features/library/domain/user_book.dart';
import '../theme/app_theme.dart';

/// Tracks the user's preferred library view mode.
enum LibraryViewMode { list, shelf }

final libraryViewModeProvider = StateProvider<LibraryViewMode>(
  (ref) => LibraryViewMode.shelf,
);

final isEditingOrderProvider = StateProvider<bool>((ref) => false);

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(libraryViewModeProvider);
    final isEditing = ref.watch(isEditingOrderProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isEditing
                ? 'Edit Order'
                : (viewMode == LibraryViewMode.shelf
                      ? 'My Collection'
                      : 'My Library'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          actions: [
            // Only show toggle layout if we aren't editing order
            if (!isEditing) _ViewToggleButton(viewMode: viewMode, ref: ref),
            _EditOrderButton(isEditing: isEditing, ref: ref),
          ],
          bottom: TabBar(
            // Disable tabs while editing to prevent saving to wrong state
            physics: isEditing ? const NeverScrollableScrollPhysics() : null,
            onTap: isEditing
                ? (index) => DefaultTabController.of(
                    context,
                  ).animateTo(DefaultTabController.of(context).previousIndex)
                : null,
            tabs: [
              Tab(
                icon: Icon(
                  Icons.book_outlined,
                  color: isEditing ? AppTheme.outlineVariant : null,
                ),
                text: 'Reading',
              ),
              Tab(
                icon: Icon(
                  Icons.bookmarks_outlined,
                  color: isEditing ? AppTheme.outlineVariant : null,
                ),
                text: 'To Read',
              ),
              Tab(
                icon: Icon(
                  Icons.check_circle_outline,
                  color: isEditing ? AppTheme.outlineVariant : null,
                ),
                text: 'Finished',
              ),
              Tab(
                icon: Icon(
                  Icons.favorite_border,
                  color: isEditing ? AppTheme.outlineVariant : null,
                ),
                text: 'Favorites',
              ),
            ],
          ),
        ),
        body: TabBarView(
          physics: isEditing ? const NeverScrollableScrollPhysics() : null,
          children: [
            _LibraryTab(
              statusProvider: readingBooksProvider,
              statusKey: 'reading',
              emptyMessage:
                  "You're not reading anything yet.\nAdd a book and start reading!",
            ),
            _LibraryTab(
              statusProvider: toReadBooksProvider,
              statusKey: 'to_read',
              emptyMessage:
                  "Your reading list is empty.\nSearch for books to add!",
            ),
            _LibraryTab(
              statusProvider: finishedBooksProvider,
              statusKey: 'finished',
              emptyMessage:
                  "No finished books yet.\nKeep reading, you'll get there! 🎉",
            ),
            _LibraryTab(
              statusProvider: favoriteBooksProvider,
              statusKey: 'favorites',
              emptyMessage:
                  "No favorite books yet.\nMark books you love to see them here!",
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final LibraryViewMode viewMode;
  final WidgetRef ref;

  const _ViewToggleButton({required this.viewMode, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: IconButton(
          key: ValueKey(viewMode),
          onPressed: () {
            ref
                .read(libraryViewModeProvider.notifier)
                .state = viewMode == LibraryViewMode.list
                ? LibraryViewMode.shelf
                : LibraryViewMode.list;
          },
          icon: Icon(
            viewMode == LibraryViewMode.shelf
                ? Icons.view_list_rounded
                : Icons.shelves,
            color: AppTheme.primary,
          ),
          tooltip: viewMode == LibraryViewMode.shelf
              ? 'Switch to List View'
              : 'Switch to Shelf View',
        ),
      ),
    );
  }
}

class _EditOrderButton extends StatelessWidget {
  final bool isEditing;
  final WidgetRef ref;

  const _EditOrderButton({required this.isEditing, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        onPressed: () {
          ref.read(isEditingOrderProvider.notifier).state = !isEditing;
        },
        icon: Icon(
          isEditing ? Icons.check_circle : Icons.edit_note,
          color: isEditing ? const Color(0xFFD4A84B) : AppTheme.primary,
        ),
        tooltip: isEditing ? 'Done Editing' : 'Customize Order',
      ),
    );
  }
}

class _LibraryTab extends ConsumerStatefulWidget {
  final ProviderListenable<AsyncValue<List<UserBook>>> statusProvider;
  final String statusKey;
  final String emptyMessage;

  const _LibraryTab({
    required this.statusProvider,
    required this.statusKey,
    required this.emptyMessage,
  });

  @override
  ConsumerState<_LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends ConsumerState<_LibraryTab> {
  // Temporary state for the reorderable list
  List<UserBook>? _editableBooks;

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(widget.statusProvider);
    final viewMode = ref.watch(libraryViewModeProvider);
    final isEditing = ref.watch(isEditingOrderProvider);
    final orderSvcAsync = ref.watch(libraryOrderServiceProvider);

    return booksAsync.when(
      data: (allBooks) {
        if (allBooks.isEmpty) {
          return _EmptyState(message: widget.emptyMessage);
        }

        return orderSvcAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildViews(allBooks, viewMode, isEditing, null),
          data: (orderSvc) {
            // Determine custom sorted books
            final savedOrder = orderSvc.getOrder(widget.statusKey);
            late List<UserBook> displayBooks;

            if (savedOrder != null && savedOrder.isNotEmpty) {
              // Create a mapped look up for fast sorting
              final bookMap = {for (var b in allBooks) b.id: b};
              displayBooks = savedOrder
                  .map((id) => bookMap[id])
                  .whereType<UserBook>()
                  .toList();

              // Append any new books that aren't in the saved order yet
              final savedSet = savedOrder.toSet();
              displayBooks.addAll(
                allBooks.where((b) => !savedSet.contains(b.id)),
              );
            } else {
              displayBooks = List.from(allBooks);
            }

            // Sync editable state
            if (isEditing) {
              _editableBooks ??= List.from(displayBooks);
              return _buildEditMode(_editableBooks!, orderSvc);
            } else {
              _editableBooks = null; // Clear edit state when done
              return _buildViews(displayBooks, viewMode, isEditing, orderSvc);
            }
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
              const SizedBox(height: 12),
              Text(
                'Failed to load library:\n$err',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(libraryProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditMode(List<UserBook> books, LibraryOrderService orderSvc) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          color: AppTheme.surfaceContainerLow,
          child: Row(
            children: [
              const Icon(
                Icons.drag_handle,
                size: 18,
                color: AppTheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Drag items to rearrange your shelf',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.all(20),
            itemCount: books.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) newIndex -= 1;
                final item = _editableBooks!.removeAt(oldIndex);
                _editableBooks!.insert(newIndex, item);
              });
              // Instantly save
              final newOrder = _editableBooks!.map((b) => b.id).toList();
              orderSvc.saveOrder(widget.statusKey, newOrder);
            },
            itemBuilder: (context, index) {
              final b = books[index].book;
              final currentStyles = orderSvc.getDisplayStyles();
              final currentStyle =
                  currentStyles[b.isbn] ?? BookDisplayStyle.auto;

              IconData styleIcon;
              Color styleColor;
              if (currentStyle == BookDisplayStyle.cover) {
                styleIcon = Icons.auto_stories;
                styleColor = AppTheme.primary;
              } else if (currentStyle == BookDisplayStyle.flat) {
                styleIcon = Icons.layers;
                styleColor = AppTheme.secondary;
              } else if (currentStyle == BookDisplayStyle.spine) {
                styleIcon = Icons.view_comfy_alt;
                styleColor = const Color(0xFFD4A84B);
              } else {
                styleIcon = Icons.auto_awesome;
                styleColor = AppTheme.onSurfaceVariant;
              }

              return Container(
                key: ValueKey(books[index].id),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: AppTheme.cardDecoration.copyWith(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.only(
                    left: 8,
                    right: 16,
                    top: 8,
                    bottom: 8,
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      b.coverImageUrl,
                      width: 40,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    b.title,
                    style: GoogleFonts.notoSerif(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    b.author,
                    style: GoogleFonts.inter(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          // Cycle state: Auto -> Cover -> Spine -> Flat -> Auto
                          BookDisplayStyle nextStyle;
                          if (currentStyle == BookDisplayStyle.auto)
                            nextStyle = BookDisplayStyle.cover;
                          else if (currentStyle == BookDisplayStyle.cover)
                            nextStyle = BookDisplayStyle.spine;
                          else if (currentStyle == BookDisplayStyle.spine)
                            nextStyle = BookDisplayStyle.flat;
                          else
                            nextStyle = BookDisplayStyle.auto;

                          orderSvc.saveDisplayStyle(b.isbn, nextStyle).then((
                            _,
                          ) {
                            setState(() {}); // refresh the icon
                          });
                        },
                        icon: Icon(styleIcon, size: 20, color: styleColor),
                        tooltip: 'Current Style: ${currentStyle.name}',
                      ),
                      const SizedBox(width: 8),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Icon(
                          Icons.drag_handle,
                          color: AppTheme.outlineVariant,
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
  }

  Widget _buildViews(
    List<UserBook> books,
    LibraryViewMode viewMode,
    bool isEditing,
    LibraryOrderService? orderSvc,
  ) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: viewMode == LibraryViewMode.shelf
          ? BookshelfView(
              key: const ValueKey('shelf'),
              books: books,
              displayStyles: orderSvc?.getDisplayStyles() ?? {},
            )
          : _ListView(key: const ValueKey('list'), books: books, ref: ref),
    );
  }
}

class _ListView extends ConsumerWidget {
  final List<UserBook> books;
  final WidgetRef ref;

  const _ListView({super.key, required this.books, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(libraryProvider),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: books.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) =>
            _BookCard(userBook: books[index], ref: ref),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final UserBook userBook;
  final WidgetRef ref;

  const _BookCard({required this.userBook, required this.ref});

  @override
  Widget build(BuildContext context) {
    final book = userBook.book;
    final theme = Theme.of(context);

    return Container(
      decoration: AppTheme.cardDecoration,
      child: InkWell(
        onTap: () => context.push('/book/${book.isbn}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Cover Image ---
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  book.coverImageUrl,
                  width: 70,
                  height: 105,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 70,
                    height: 105,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.book,
                      size: 36,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // --- Book Info ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: GoogleFonts.notoSerif(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(book.author, style: theme.textTheme.bodySmall),

                    // --- Progress Section (Reading only) ---
                    if (userBook.status == ReadingStatus.reading) ...[
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Page ${userBook.currentPage} of ${book.pageCount}',
                            style: theme.textTheme.labelSmall,
                          ),
                          Text(
                            '${(userBook.progressPercent * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: userBook.progressPercent,
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // ── Focus Timer Button ───────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: FilledButton.tonalIcon(
                            onPressed: () => context.push(
                              '/timer/${userBook.id}?title=${Uri.encodeComponent(book.title)}',
                            ),
                            icon: const Icon(Icons.timer_outlined, size: 16),
                            label: const Text('Focus Timer'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: AppTheme.onPrimary,
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              textStyle: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    // --- Rating Section (Finished only) ---
                    if (userBook.status == ReadingStatus.read &&
                        userBook.rating != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < (userBook.rating ?? 0)
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 18,
                            color: const Color(0xFFD4A84B),
                          ),
                        ),
                      ),
                    ],

                    // --- Status Chip --- pill style
                    const SizedBox(height: 12),
                    _StatusChip(status: userBook.status),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ReadingStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ReadingStatus.reading => ('Reading', AppTheme.primary),
      ReadingStatus.read => ('Finished ✓', AppTheme.primary),
      ReadingStatus.toRead => ('To Read', AppTheme.secondary),
      ReadingStatus.dnf => ('Did Not Finish', AppTheme.outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 72,
              color: AppTheme.outlineVariant,
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppTheme.onSurfaceVariant,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
