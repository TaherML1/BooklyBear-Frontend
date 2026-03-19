import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/book_list_repository.dart';
import '../domain/book_list.dart';

// Provider for the book list service
final bookListServiceProvider = Provider<BookListService>((ref) {
  return BookListService(ref.read(bookListRepositoryProvider));
});

class BookListService {
  final BookListRepository _repository;

  BookListService(this._repository);

  /// Get all book lists for the logged-in user
  Future<List<BookList>> getMyBookLists() async {
    return await _repository.getMyBookLists();
  }

  /// Get a specific book list by ID
  Future<BookList> getBookList(String id) async {
    return await _repository.getBookList(id);
  }

  /// Create a new book list
  Future<BookList> createBookList(BookList bookList) async {
    return await _repository.createBookList(bookList);
  }

  /// Update an existing book list
  Future<BookList> updateBookList(String id, BookList bookList) async {
    return await _repository.updateBookList(id, bookList);
  }

  /// Delete a book list
  Future<void> deleteBookList(String id) async {
    return await _repository.deleteBookList(id);
  }

  /// Add a book to a book list
  Future<BookList> addBookToList(String listId, String bookId) async {
    return await _repository.addBookToList(listId, bookId);
  }

  /// Remove a book from a book list
  Future<BookList> removeBookFromList(String listId, String bookId) async {
    return await _repository.removeBookFromList(listId, bookId);
  }

  /// Get public book lists
  Future<List<BookList>> getPublicBookLists() async {
    return await _repository.getPublicBookLists();
  }
}