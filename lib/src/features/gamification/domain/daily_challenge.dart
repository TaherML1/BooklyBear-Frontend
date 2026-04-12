class DailyChallenge {
  final String date;
  final int goalPages;
  final int pagesReadToday;
  final bool isCompleted;
  final bool newlyCompleted;
  final int xpReward;
  final String description;

  DailyChallenge({
    required this.date,
    required this.goalPages,
    required this.pagesReadToday,
    required this.isCompleted,
    required this.newlyCompleted,
    required this.xpReward,
    required this.description,
  });

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      date: json['date']?.toString() ?? '',
      goalPages: (json['goalPages'] as num?)?.toInt() ?? 0,
      pagesReadToday: (json['pagesReadToday'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] == true,
      newlyCompleted: json['newlyCompleted'] == true,
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 0,
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'goalPages': goalPages,
      'pagesReadToday': pagesReadToday,
      'isCompleted': isCompleted,
      'newlyCompleted': newlyCompleted,
      'xpReward': xpReward,
      'description': description,
    };
  }
}
