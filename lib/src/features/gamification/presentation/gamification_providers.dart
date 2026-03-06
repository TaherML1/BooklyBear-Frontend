import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/gamification_repository.dart';
import '../domain/gamification_status.dart';

final gamificationStatusProvider = FutureProvider<GamificationStatus>((
  ref,
) async {
  final repository = ref.watch(gamificationRepositoryProvider);
  return repository.getStatus();
});
