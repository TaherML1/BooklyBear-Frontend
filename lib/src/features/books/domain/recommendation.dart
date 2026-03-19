import 'book.dart';

class Recommendation {
  final Book book;
  final double score;
  final String? explanation;

  Recommendation({
    required this.book,
    required this.score,
    this.explanation,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      book: Book.fromJson(json['book'] ?? {}),
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      explanation: json['explanation']?.toString(),
    );
  }
}
