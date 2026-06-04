import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../routing/app_router.dart';
import '../domain/achievement.dart';
import 'gamification_providers.dart';
import '../../library/presentation/library_providers.dart';
import '../../social/data/post_repository.dart';

final achievementUnlockManagerProvider = Provider<void>((ref) {
  // Listen to other actions that trigger gamification updates
  ref.listen(gamificationStatusProvider, (previous, next) {
    ref.invalidate(achievementsProvider);
  });
  ref.listen(libraryProvider, (previous, next) {
    ref.invalidate(achievementsProvider);
  });
  ref.listen(timelineProvider, (previous, next) {
    ref.invalidate(achievementsProvider);
  });

  // Listen to achievements updates and check for new unlocks
  ref.listen<AsyncValue<List<Achievement>>>(achievementsProvider, (previous, next) {
    if (previous == null || previous.value == null || next.value == null) return;

    final oldList = previous.value!;
    final newList = next.value!;

    for (final newAch in newList) {
      if (newAch.unlocked) {
        final oldAch = oldList.firstWhere(
          (a) => a.id == newAch.id,
          orElse: () => Achievement(
            id: newAch.id,
            name: newAch.name,
            description: newAch.description,
            icon: newAch.icon,
            xpReward: newAch.xpReward,
            unlocked: false, // Assume it was locked if not in list
          ),
        );

        if (!oldAch.unlocked) {
          // Trigger the celebration popup on the global navigator context
          final context = rootNavigatorKey.currentContext;
          if (context != null) {
            _showUnlockCelebrationDialog(context, newAch);
          }
        }
      }
    }
  });
});

void _showUnlockCelebrationDialog(BuildContext context, Achievement ach) {
  final assetPath = 'assets/achievements/${ach.id}.png';
  showDialog(
    context: context,
    barrierDismissible: false, // Require tapping "Awesome!" to close
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF2D6A4F).withAlpha(120),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2D6A4F).withAlpha(30),
                blurRadius: 24,
                spreadRadius: 8,
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ACHIEVEMENT UNLOCKED!',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF2D6A4F),
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 20),
              // Glow animation container
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2D6A4F).withAlpha(45),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.emoji_events_rounded,
                    size: 70,
                    color: Color(0xFF2D6A4F),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                ach.name,
                style: GoogleFonts.notoSerif(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                ach.description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bolt, color: Colors.orange, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '+${ach.xpReward} XP Earned',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2D6A4F), Color(0xFF40916C)],
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Awesome!',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
