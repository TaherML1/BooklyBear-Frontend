import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/dio_client.dart';
import '../domain/book.dart';

class BookRepository {
  final Dio _dio;

  BookRepository(this._dio);

  /// Fetches a single book from the backend by its ISBN.
  /// Returns null if the book is not found (404).
  Future<Book?> getBookByIsbn(String isbn) async {
    try {
      final response = await _dio.get('/books/isbn/$isbn');
      return Book.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // Book not found
      }
      // Re-throw other errors to be handled by the UI
      rethrow;
    }
  }
}

// 1. Provider for the Repository
final bookRepositoryProvider = Provider<BookRepository>((ref) {
  return BookRepository(ref.read(dioProvider));
});


// 2. A simple provider that fetches a book by ISBN
// This is what our UI will use!
// The ".family" modifier lets us pass in the ISBN string.
final bookByIsbnProvider = FutureProvider.family<Book?, String>((ref, isbn) async {
  // Read the repository and call the function
  return ref.read(bookRepositoryProvider).getBookByIsbn(isbn);
});