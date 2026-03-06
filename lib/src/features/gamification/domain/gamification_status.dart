class GamificationStatus {
  final int streak;
  final int level;
  final int xpProgress;
  final int nextLevelXp;
  final String? mascot;

  GamificationStatus({
    required this.streak,
    required this.level,
    required this.xpProgress,
    required this.nextLevelXp,
    this.mascot,
  });

  factory GamificationStatus.fromJson(Map<String, dynamic> json) {
    return GamificationStatus(
      streak: json['streak'] ?? 0,
      level: json['level'] ?? 1,
      xpProgress: json['xpProgress'] ?? 0,
      nextLevelXp: json['nextLevelXp'] ?? 150,
      mascot: json['mascot'],
    );
  }
}
