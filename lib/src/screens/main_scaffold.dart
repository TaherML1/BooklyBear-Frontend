import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/gamification/presentation/achievement_unlock_manager.dart';
import '../theme/app_theme.dart';

class MainScaffold extends ConsumerWidget {
  const MainScaffold({
    super.key,
    required this.navigationShell,
  });

  /// The navigation shell and container for the branch Navigators.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Active achievement unlock checking globally
    ref.watch(achievementUnlockManagerProvider);

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface.withAlpha(204), // 80% opacity
              border: Border(
                top: BorderSide(
                  color: AppTheme.outlineVariant.withAlpha(38), // 15% ghost
                  width: 0.5,
                ),
              ),
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              indicatorColor: AppTheme.primaryFixed.withAlpha(80),
              surfaceTintColor: Colors.transparent,
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (int index) => _onTap(context, index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.local_library_outlined),
                  selectedIcon: Icon(Icons.local_library, color: AppTheme.primary),
                  label: 'Library',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_stories_outlined),
                  selectedIcon: Icon(Icons.auto_stories, color: AppTheme.primary),
                  label: 'Discover',
                ),
                NavigationDestination(
                  icon: Icon(Icons.library_books_outlined),
                  selectedIcon: Icon(Icons.library_books, color: AppTheme.primary),
                  label: 'Shelf',
                ),
                NavigationDestination(
                  icon: Icon(Icons.group_outlined),
                  selectedIcon: Icon(Icons.group, color: AppTheme.primary),
                  label: 'Clubs',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person, color: AppTheme.primary),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    // When navigating to a new branch, it's recommended to use the goBranch
    // method, as doing so makes sure the last navigation state of the
    // Navigator for the branch is restored.
    navigationShell.goBranch(
      index,
      // A common pattern when tapping an initial route is to navigate to the
      // initial location when tapping the item that is already active.
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
