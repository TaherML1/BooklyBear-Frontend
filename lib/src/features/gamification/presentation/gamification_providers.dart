import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/gamification_repository.dart';
import '../domain/gamification_status.dart';
import '../domain/achievement.dart';
import '../domain/daily_challenge.dart';

final gamificationStatusProvider = FutureProvider<GamificationStatus>((
  ref,
) async {
  final repository = ref.watch(gamificationRepositoryProvider);
  return repository.getStatus();
});

final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  final repository = ref.watch(gamificationRepositoryProvider);
  return repository.getAchievements();
});

final todaysChallengeProvider = FutureProvider<DailyChallenge>((ref) async {
  final repository = ref.watch(gamificationRepositoryProvider);
  return repository.getTodaysChallenge();
});
