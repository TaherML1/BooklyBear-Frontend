import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/dio_client.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

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

/// One day of reading activity — used for the 30-day bar chart.
class ReadingDayEntry {
  final DateTime date;
  final int pagesRead;
  final int minutesSpent;

  const ReadingDayEntry({
    required this.date,
    required this.pagesRead,
    required this.minutesSpent,
  });

  factory ReadingDayEntry.fromJson(Map<String, dynamic> json) {
    return ReadingDayEntry(
      date: DateTime.parse(json['date'] as String),
      pagesRead: (json['pagesRead'] as num?)?.toInt() ?? 0,
      minutesSpent: (json['minutesSpent'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A single genre with its read-book count + percentage — used for the donut chart.
class GenreStat {
  final String genre;
  final int count;
  final double percentage;

  const GenreStat({
    required this.genre,
    required this.count,
    required this.percentage,
  });

  factory GenreStat.fromJson(Map<String, dynamic> json) {
    return GenreStat(
      genre: json['genre'] as String,
      count: (json['count'] as num).toInt(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

// ─── Repository ───────────────────────────────────────────────────────────────

class StatsRepository {
  final Dio _dio;
  StatsRepository(this._dio);

  /// Lifetime totals — pages, minutes, sessions, books.
  Future<ReadingStats> getMyStats() async {
    try {
      final response = await _dio.get('/stats/me');
      return ReadingStats.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load stats';
    }
  }

  /// 30-day daily reading data — returns 30 entries, one per day (zeros on empty days).
  Future<List<ReadingDayEntry>> getReadingHistory() async {
    try {
      final response = await _dio.get('/stats/me/history');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => ReadingDayEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load reading history';
    }
  }

  /// Genre breakdown for finished books — top 8 genres with counts and percentages.
  Future<List<GenreStat>> getGenreStats() async {
    try {
      final response = await _dio.get('/stats/me/genres');
      final list = response.data as List<dynamic>;
      return list
          .map((e) => GenreStat.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to load genre stats';
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(ref.read(dioProvider));
});

final myReadingStatsProvider = FutureProvider<ReadingStats>((ref) {
  return ref.read(statsRepositoryProvider).getMyStats();
});

final dailyReadingHistoryProvider = FutureProvider<List<ReadingDayEntry>>((ref) {
  return ref.read(statsRepositoryProvider).getReadingHistory();
});

final genreStatsProvider = FutureProvider<List<GenreStat>>((ref) {
  return ref.read(statsRepositoryProvider).getGenreStats();
});
