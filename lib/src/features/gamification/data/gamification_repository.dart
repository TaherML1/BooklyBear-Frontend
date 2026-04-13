import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/dio_client.dart';
import '../domain/gamification_status.dart';
import '../domain/achievement.dart';
import '../domain/daily_challenge.dart';
import '../domain/quiz_models.dart';

class GamificationRepository {
  final Dio _dio;

  GamificationRepository(this._dio);

  Future<GamificationStatus> getStatus() async {
    try {
      final response = await _dio.get('/gamification/status');
      return GamificationStatus.fromJson(response.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load gamification status';
    }
  }

  Future<List<Achievement>> getAchievements() async {
    try {
      final response = await _dio.get('/gamification/achievements');
      final list = response.data as List;
      return list.map((e) => Achievement.fromJson(e)).toList();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load achievements';
    }
  }

  Future<DailyChallenge> getTodaysChallenge() async {
    try {
      final response = await _dio.get('/gamification/challenge/today');
      return DailyChallenge.fromJson(response.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load daily challenge';
    }
  }

  Future<List<UserBadge>> getBadges() async {
    try {
      final response = await _dio.get('/gamification/badges');
      final list = response.data as List;
      return list.map((e) => UserBadge.fromJson(e)).toList();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load badges';
    }
  }

  Future<List<Quiz>> getGeneralQuizzes() async {
    try {
      final response = await _dio.get('/gamification/quizzes');
      final list = response.data as List;
      return list.map((e) => Quiz.fromJson(e)).toList();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load quizzes';
    }
  }

  Future<Quiz> getBookQuiz(String bookId) async {
    try {
      final response = await _dio.get('/gamification/quizzes/book/$bookId');
      return Quiz.fromJson(response.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load book quiz';
    }
  }

  Future<QuizAttemptResult> submitQuiz(String quizId, List<Map<String, dynamic>> answers) async {
    try {
      final response = await _dio.post('/gamification/quizzes/$quizId/submit', data: {
        'answers': answers,
      });
      return QuizAttemptResult.fromJson(response.data);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to submit quiz';
    }
  }
}

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepository(ref.read(dioProvider));
});
