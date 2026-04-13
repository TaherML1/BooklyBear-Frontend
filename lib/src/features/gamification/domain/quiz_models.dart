class QuizQuestion {
  final String id;
  final String questionText;
  final List<String> options;
  final int? correctOptionIndex;

  QuizQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    this.correctOptionIndex,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String,
      questionText: json['questionText'] as String,
      options: List<String>.from(json['options'] ?? []),
      correctOptionIndex: json['correctOptionIndex'] as int?,
    );
  }
}

class Quiz {
  final String id;
  final String title;
  final String description;
  final String type;
  final String? bookId;
  final int xpReward;
  final String? badgeIcon;
  final String? badgeName;
  final List<QuizQuestion> questions;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.bookId,
    required this.xpReward,
    this.badgeIcon,
    this.badgeName,
    required this.questions,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      type: json['type'] as String,
      bookId: json['bookId'] as String?,
      xpReward: json['xpReward'] as int? ?? 0,
      badgeIcon: json['badgeIcon'] as String?,
      badgeName: json['badgeName'] as String?,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class UserBadge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final DateTime earnedAt;

  UserBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.earnedAt,
  });

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    return UserBadge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String,
      earnedAt: json['earnedAt'] != null
          ? DateTime.parse(json['earnedAt'] as String)
          : DateTime.now(),
    );
  }
}

class QuizAttemptResult {
  final int score;
  final bool passed;
  final int xpEarned;
  final UserBadge? newlyEarnedBadge;

  QuizAttemptResult({
    required this.score,
    required this.passed,
    required this.xpEarned,
    this.newlyEarnedBadge,
  });

  factory QuizAttemptResult.fromJson(Map<String, dynamic> json) {
    return QuizAttemptResult(
      score: json['score'] as int? ?? 0,
      passed: json['passed'] as bool? ?? false,
      xpEarned: json['xpEarned'] as int? ?? 0,
      newlyEarnedBadge: json['newlyEarnedBadge'] != null
          ? UserBadge.fromJson(json['newlyEarnedBadge'])
          : null,
    );
  }
}
