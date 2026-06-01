import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/dio_client.dart';
import '../domain/user_book.dart';

class LibraryRepository {
  final Dio _dio;

  LibraryRepository(this._dio);

  /// GET /api/library/me — full library for logged-in user
  Future<List<UserBook>> getMyLibrary() async {
    try {
      final response = await _dio.get('/library/me');
      final List<dynamic> data = response.data;
      return data
          .map((e) => UserBook.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load library';
    }
  }

  /// POST /api/library/:bookId — add a book to the user's library
  Future<UserBook> addBookToLibrary(String bookId) async {
    try {
      final response = await _dio.post('/library/$bookId');
      return UserBook.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to add book to library';
    }
  }

  /// PUT /api/library/:userBookId — update status, currentPage, or rating
  Future<UserBook> updateLibraryEntry({
    required String userBookId,
    String? status,
    int? currentPage,
    int? rating,
    bool? isFavorite,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (status != null) body['status'] = status;
      if (currentPage != null) body['currentPage'] = currentPage;
      if (rating != null) body['rating'] = rating;
      if (isFavorite != null) body['isFavorite'] = isFavorite;

      final response = await _dio.put('/library/$userBookId', data: body);
      return UserBook.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to update library entry';
    }
  }

  /// POST /api/library/:userBookId/sessions — log a reading session
  /// This triggers XP + streak increment on the backend.
  Future<Map<String, dynamic>> logReadingSession({
    required String userBookId,
    required int pagesRead,
    required int minutesSpent,
  }) async {
    try {
      final response = await _dio.post(
        '/library/$userBookId/sessions',
        data: {
          'pagesRead': pagesRead,
          'minutesSpent': minutesSpent,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to log reading session';
    }
  }
  /// GET /api/library/sessions/history
  Future<List<dynamic>> getRawReadingHistory() async {
    try {
      final response = await _dio.get('/library/sessions/history');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load reading history';
    }
  }
}

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepository(ref.read(dioProvider));
});
