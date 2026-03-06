import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/dio_client.dart';

class ReadingStats {
  final int totalBooks;
  final int totalPages;
  final int totalMinutes;
  final int totalSessions;

  ReadingStats({
    required this.totalBooks,
    required this.totalPages,
    required this.totalMinutes,
    required this.totalSessions,
  });

  int get totalHours => totalMinutes ~/ 60;

  factory ReadingStats.fromJson(Map<String, dynamic> json) {
    return ReadingStats(
      totalBooks: (json['totalBooksRead'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPagesRead'] as num?)?.toInt() ?? 0,
      totalMinutes: (json['totalMinutesRead'] as num?)?.toInt() ?? 0,
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
    );
  }
}

class StatsRepository {
  final Dio _dio;
  StatsRepository(this._dio);

  Future<ReadingStats> getMyStats() async {
    try {
      final response = await _dio.get('/stats/me');
      return ReadingStats.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load stats';
    }
  }
}

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(ref.read(dioProvider));
});

final myReadingStatsProvider = FutureProvider<ReadingStats>((ref) {
  return ref.read(statsRepositoryProvider).getMyStats();
});
