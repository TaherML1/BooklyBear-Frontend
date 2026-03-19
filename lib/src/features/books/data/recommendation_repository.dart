import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/dio_client.dart';
import '../../../utils/app_logger.dart';
import '../domain/recommendation.dart';

final recommendationRepositoryProvider = Provider<RecommendationRepository>((ref) {
  return RecommendationRepository(ref.watch(dioProvider));
});

// A future provider to fetch the recommendations safely
final recommendationsProvider = FutureProvider.autoDispose<List<Recommendation>>((ref) async {
  final repo = ref.watch(recommendationRepositoryProvider);
  return repo.getRecommendations();
});

class RecommendationRepository {
  final Dio _dio;

  RecommendationRepository(this._dio);

  Future<List<Recommendation>> getRecommendations({int limit = 10}) async {
    AppLogger.info('[Recommendations] Fetching recommendations (limit=$limit)...');
    try {
      final response = await _dio.get(
        '/recommendations',
        queryParameters: {'limit': limit},
      );

      AppLogger.debug('[Recommendations] Response status: ${response.statusCode}');
      AppLogger.debug('[Recommendations] Response data type: ${response.data.runtimeType}');
      // Truncated log to prevent debugger stalling
      AppLogger.debug('[Recommendations] Data received (truncated)');

      if (response.statusCode == 200 && response.data != null) {
        // Handle both possible backend structures (direct list vs {data: list})
        List<dynamic>? data;
        if (response.data is List) {
          AppLogger.info('[Recommendations] Data is a direct List');
          data = response.data as List<dynamic>;
        } else if (response.data is Map && response.data['data'] != null) {
          AppLogger.info('[Recommendations] Data is wrapped in {data: ...}');
          data = response.data['data'] as List<dynamic>;
        } else {
          AppLogger.warn('[Recommendations] Unexpected data structure: ${response.data.runtimeType}');
        }

        if (data == null) {
          AppLogger.warn('[Recommendations] Parsed data is null → returning empty list');
          return [];
        }

        AppLogger.info('[Recommendations] Parsed ${data.length} raw items');
        final result = data.map((item) => Recommendation.fromJson(item)).toList();
        AppLogger.info('[Recommendations] Returning ${result.length} Recommendation objects');
        return result;
      }

      AppLogger.warn('[Recommendations] Non-200 or null data → returning empty list');
      return [];
    } catch (e, stack) {
      AppLogger.error('[Recommendations] Exception: $e');
      AppLogger.error('[Recommendations] Stack: $stack');
      rethrow;
    }
  }
}
