import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:booklybear/src/utils/dio_client.dart';
import 'package:booklybear/src/utils/app_logger.dart';

class OnboardingRepository {
  final Dio _dio;
  OnboardingRepository(this._dio);

  /// Check if the current user has completed onboarding
  Future<Map<String, dynamic>> getOnboardingStatus() async {
    try {
      final response = await _dio.get('/onboarding/status');
      return response.data;
    } on DioException catch (e) {
      AppLogger.error('[Onboarding] Status check failed: ${e.message}');
      throw e.response?.data['message'] ?? 'Failed to check onboarding status';
    }
  }

  /// Get popular books for the taste test, optionally filtered by genres
  Future<List<Map<String, dynamic>>> getPopularBooks({
    List<String>? genres,
    int limit = 30,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (genres != null && genres.isNotEmpty) {
        queryParams['genres'] = genres.join(',');
      }
      final response = await _dio.get(
        '/onboarding/popular-books',
        queryParameters: queryParams,
      );
      return List<Map<String, dynamic>>.from(response.data['data'] ?? []);
    } on DioException catch (e) {
      AppLogger.error('[Onboarding] Popular books fetch failed: ${e.message}');
      throw e.response?.data['message'] ?? 'Failed to fetch books';
    }
  }

  /// Submit the full onboarding quiz
  Future<Map<String, dynamic>> submitOnboarding({
    required List<String> selectedGenres,
    required Map<String, int> bookRatings,
    required String readingPace,
    required String preferredPageRange,
    required String readingFrequency,
    required String dailyReadingTime,
    String? currentlyReadingIsbn,
  }) async {
    try {
      final response = await _dio.post('/onboarding/submit', data: {
        'selectedGenres': selectedGenres,
        'bookRatings': bookRatings,
        'readingPace': readingPace,
        'preferredPageRange': preferredPageRange,
        'readingFrequency': readingFrequency,
        'dailyReadingTime': dailyReadingTime,
        'currentlyReadingIsbn': currentlyReadingIsbn,
      });
      AppLogger.info('[Onboarding] Submission successful');
      return response.data;
    } on DioException catch (e) {
      AppLogger.error('[Onboarding] Submission failed: ${e.message}');
      throw e.response?.data['message'] ?? 'Failed to submit onboarding';
    }
  }

  /// Reconfigure taste profile from profile screen
  Future<Map<String, dynamic>> reconfigure({
    required List<String> selectedGenres,
    required String readingPace,
    required String preferredPageRange,
    required String readingFrequency,
    required String dailyReadingTime,
  }) async {
    try {
      final response = await _dio.put('/onboarding/reconfigure', data: {
        'selectedGenres': selectedGenres,
        'readingPace': readingPace,
        'preferredPageRange': preferredPageRange,
        'readingFrequency': readingFrequency,
        'dailyReadingTime': dailyReadingTime,
      });
      return response.data;
    } on DioException catch (e) {
      AppLogger.error('[Onboarding] Reconfigure failed: ${e.message}');
      throw e.response?.data['message'] ?? 'Failed to update settings';
    }
  }
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(ref.read(dioProvider));
});
