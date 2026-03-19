import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/dio_client.dart';
import '../domain/book_list.dart';

class BookListRepository {
  final Dio _dio;

  BookListRepository(this._dio);

  /// GET /api/booklists/me - Get all book lists for the logged-in user
  Future<List<BookList>> getMyBookLists() async {
    try {
      final response = await _dio.get('/booklists/me');
      final List<dynamic> data = response.data;
      return data
          .map((e) => BookList.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load book lists';
    }
  }

  /// GET /api/booklists/:id - Get a specific book list by ID
  Future<BookList> getBookList(String id) async {
    try {
      final response = await _dio.get('/booklists/$id');
      return BookList.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load book list';
    }
  }

  /// POST /api/booklists - Create a new book list
  Future<BookList> createBookList(BookList bookList) async {
    try {
      final response = await _dio.post('/booklists', data: bookList.toJson());
      return BookList.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to create book list';
    }
  }

  /// PUT /api/booklists/:id - Update an existing book list
  Future<BookList> updateBookList(String id, BookList bookList) async {
    try {
      final response = await _dio.put('/booklists/$id', data: bookList.toJson());
      return BookList.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to update book list';
    }
  }

  /// DELETE /api/booklists/:id - Delete a book list
  Future<void> deleteBookList(String id) async {
    try {
      await _dio.delete('/booklists/$id');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to delete book list';
    }
  }

  /// POST /api/booklists/:id/books - Add a book to a book list
  Future<BookList> addBookToList(String listId, String bookId) async {
    try {
      final response = await _dio.post('/booklists/$listId/books', data: {'bookId': bookId});
      return BookList.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to add book to list';
    }
  }

  /// DELETE /api/booklists/:id/books/:bookId - Remove a book from a book list
  Future<BookList> removeBookFromList(String listId, String bookId) async {
    try {
      final response = await _dio.delete('/booklists/$listId/books/$bookId');
      return BookList.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to remove book from list';
    }
  }

  /// GET /api/booklists/public - Get public book lists
  Future<List<BookList>> getPublicBookLists() async {
    try {
      final response = await _dio.get('/booklists/public');
      final List<dynamic> data = response.data;
      return data
          .map((e) => BookList.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load public book lists';
    }
  }
}

final bookListRepositoryProvider = Provider<BookListRepository>((ref) {
  return BookListRepository(ref.read(dioProvider));
});