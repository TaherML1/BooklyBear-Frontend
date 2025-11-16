import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../features/books/data/book_repository.dart'; // Import our new provider
import '../features/books/domain/book.dart';

class BookDetailsScreen extends ConsumerWidget {
  final String isbn;
  const BookDetailsScreen({super.key, required this.isbn});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider. Riverpod handles loading/error states!
    final bookAsyncValue = ref.watch(bookByIsbnProvider(isbn));

    return Scaffold(
      appBar: AppBar(title: const Text('Book Details')),
      body: bookAsyncValue.when(
        // Success: Show the book data
        data: (book) {
          if (book == null) {
            return const Center(
              child: Text('Book not found. (404)'),
            );
          }
          return _BookDetailsView(book: book);
        },
        // Error: Show the error
        error: (err, stack) => Center(
          child: Text('Error: $err'),
        ),
        // Loading: Show a spinner
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.brown),
        ),
      ),
    );
  }
}

// A private widget to display the book details
class _BookDetailsView extends StatelessWidget {
  final Book book;
  const _BookDetailsView({required this.book});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cover Image
          Container(
            height: 350,
            padding: const EdgeInsets.all(24),
            color: Colors.grey[200],
            child: CachedNetworkImage(
              imageUrl: book.coverImageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.book, size: 100, color: Colors.grey),
            ),
          ),
          
          // Book Info
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  book.author,
                  style: textTheme.titleMedium?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('${book.pageCount} pages'),
                    const Text(' • '),
                    Text(book.publisher ?? 'Unknown'),
                  ],
                ),
                const SizedBox(height: 24),
                
                // "Add to Library" Button
                FilledButton.icon(
                  onPressed: () {
                    // TODO: Implement "Add to Library" logic
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add to Library'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Description
                Text(
                  'Description',
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  book.description ?? 'No description available.',
                  style: textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}