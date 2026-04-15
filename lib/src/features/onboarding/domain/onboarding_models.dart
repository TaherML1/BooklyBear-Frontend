import 'package:flutter/material.dart';

class ReaderArchetype {
  final String key;
  final String displayName;
  final String emoji;
  final String description;
  final String tagline;
  final Color color;

  const ReaderArchetype({
    required this.key,
    required this.displayName,
    required this.emoji,
    required this.description,
    required this.tagline,
    required this.color,
  });

  factory ReaderArchetype.fromJson(Map<String, dynamic> json) {
    return ReaderArchetype(
      key: json['key'] ?? 'the_explorer',
      displayName: json['displayName'] ?? 'The Explorer',
      emoji: json['emoji'] ?? '🧭',
      description: json['description'] ?? '',
      tagline: json['tagline'] ?? '',
      color: _parseColor(json['color']),
    );
  }

  static Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF4CAF50);
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}

/// Genre option for Step 1
class GenreOption {
  final String key;
  final String displayName;
  final String emoji;

  const GenreOption({
    required this.key,
    required this.displayName,
    required this.emoji,
  });
}

const List<GenreOption> availableGenres = [
  GenreOption(key: 'fiction', displayName: 'Fiction', emoji: '📖'),
  GenreOption(key: 'non-fiction', displayName: 'Non-Fiction', emoji: '📰'),
  GenreOption(key: 'fantasy', displayName: 'Fantasy', emoji: '🧙‍♂️'),
  GenreOption(key: 'sci-fi', displayName: 'Sci-Fi', emoji: '🚀'),
  GenreOption(key: 'mystery', displayName: 'Mystery', emoji: '🔍'),
  GenreOption(key: 'thriller', displayName: 'Thriller', emoji: '🔪'),
  GenreOption(key: 'romance', displayName: 'Romance', emoji: '💕'),
  GenreOption(key: 'history', displayName: 'History', emoji: '🏛️'),
  GenreOption(key: 'science', displayName: 'Science', emoji: '🔬'),
  GenreOption(key: 'philosophy', displayName: 'Philosophy', emoji: '🧠'),
  GenreOption(key: 'self-help', displayName: 'Self-Help', emoji: '🌱'),
  GenreOption(key: 'horror', displayName: 'Horror', emoji: '👻'),
  GenreOption(key: 'biography', displayName: 'Biography', emoji: '👤'),
  GenreOption(key: 'young-adult', displayName: 'Young Adult', emoji: '✨'),
];

/// Reading habit options for Step 3
class HabitOption {
  final String key;
  final String displayName;
  final String emoji;
  final String subtitle;

  const HabitOption({
    required this.key,
    required this.displayName,
    required this.emoji,
    this.subtitle = '',
  });
}

const List<HabitOption> paceOptions = [
  HabitOption(key: 'casual', displayName: 'Casual', emoji: '🐢', subtitle: 'A few pages a week'),
  HabitOption(key: 'moderate', displayName: 'Moderate', emoji: '📖', subtitle: 'A book a month'),
  HabitOption(key: 'avid', displayName: 'Avid', emoji: '🔥', subtitle: 'Multiple books a month'),
];

const List<HabitOption> pageRangeOptions = [
  HabitOption(key: 'short', displayName: 'Short & Sweet', emoji: '📄', subtitle: 'Under 200 pages'),
  HabitOption(key: 'medium', displayName: 'Just Right', emoji: '📕', subtitle: '200 – 400 pages'),
  HabitOption(key: 'long', displayName: 'Epic Reads', emoji: '📚', subtitle: '400+ pages'),
];

const List<HabitOption> frequencyOptions = [
  HabitOption(key: 'daily', displayName: 'Every Day', emoji: '☀️', subtitle: 'Reading is a daily ritual'),
  HabitOption(key: 'few_times_week', displayName: 'Few Times a Week', emoji: '📅', subtitle: '3-5 days a week'),
  HabitOption(key: 'weekly', displayName: 'Weekly', emoji: '🗓️', subtitle: 'Once or twice a week'),
  HabitOption(key: 'few_times_month', displayName: 'Few Times a Month', emoji: '🌙', subtitle: 'When the mood strikes'),
];

const List<HabitOption> dailyTimeOptions = [
  HabitOption(key: 'under_15', displayName: 'Under 15 min', emoji: '⏱️', subtitle: 'Quick bursts'),
  HabitOption(key: '15_to_30', displayName: '15 – 30 min', emoji: '⏰', subtitle: 'A nice chapter'),
  HabitOption(key: '30_to_60', displayName: '30 – 60 min', emoji: '🕐', subtitle: 'Deep reading sessions'),
  HabitOption(key: 'over_60', displayName: 'Over 1 hour', emoji: '📚', subtitle: 'Marathoner!'),
];
