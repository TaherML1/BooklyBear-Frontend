import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/dio_client.dart';
import '../domain/gamification_status.dart';
import '../domain/achievement.dart';
import '../domain/daily_challenge.dart';

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
}

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepository(ref.read(dioProvider));
});
