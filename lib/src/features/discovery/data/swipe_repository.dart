import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/dio_client.dart';
import '../../../utils/app_logger.dart';
import '../../books/domain/book.dart';

final swipeRepositoryProvider = Provider<SwipeRepository>((ref) {
  return SwipeRepository(ref.watch(dioProvider));
});

/// Provider that fetches the swipe deck (batch of recommended books to swipe)
final swipeDeckProvider = FutureProvider.autoDispose<List<Book>>((ref) async {
  final repo = ref.watch(swipeRepositoryProvider);
  return repo.getSwipeDeck();
});

class SwipeRepository {
  final Dio _dio;

  SwipeRepository(this._dio);

  /// Fetch the next batch of swipeable books
  Future<List<Book>> getSwipeDeck({int limit = 20}) async {
    AppLogger.info('[SwipeDeck] Fetching deck (limit=$limit)...');
    try {
      final response = await _dio.get(
        '/swipes/deck',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as List<dynamic>? ?? [];
        AppLogger.info('[SwipeDeck] Received ${data.length} books');
        return data.map((item) => Book.fromJson(item)).toList();
      }

      return [];
    } catch (e) {
      AppLogger.error('[SwipeDeck] Error: $e');
      rethrow;
    }
  }

  /// Record a swipe action (like or skip)
  Future<void> recordSwipe({
    required String bookId,
    required String direction,
  }) async {
    AppLogger.info('[Swipe] Recording $direction on book $bookId');
    try {
      await _dio.post('/swipes', data: {
        'bookId': bookId,
        'direction': direction,
      });
    } catch (e) {
      AppLogger.error('[Swipe] Error recording swipe: $e');
      rethrow;
    }
  }
}
