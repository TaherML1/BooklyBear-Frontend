import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/dio_client.dart';
import '../domain/book_review.dart';

class ReviewRepository {
  final Dio _dio;

  ReviewRepository(this._dio);

  Future<PaginatedReviews> getReviews(String isbn, {int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(
        '/books/isbn/$isbn/reviews',
        queryParameters: {'page': page, 'limit': limit},
      );
      return PaginatedReviews.fromJson(response.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load reviews';
    }
  }

  Future<BookReview> upsertReview({
    required String isbn,
    int? rating,
    String? reviewText,
  }) async {
    try {
      final response = await _dio.post(
        '/books/isbn/$isbn/reviews',
        data: {
          if (rating != null) 'rating': rating,
          if (reviewText != null) 'reviewText': reviewText,
        },
      );
      return BookReview.fromJson(response.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to submit review';
    }
  }

  Future<void> deleteReview(String isbn) async {
    try {
      await _dio.delete('/books/isbn/$isbn/reviews');
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to delete review';
    }
  }
}

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.read(dioProvider));
});

// A provider family to watch reviews per book
final bookReviewsProvider = FutureProvider.family<PaginatedReviews, String>((ref, isbn) {
  return ref.watch(reviewRepositoryProvider).getReviews(isbn);
});
