import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/dio_client.dart';
import '../domain/gamification_status.dart';

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
}

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepository(ref.read(dioProvider));
});
