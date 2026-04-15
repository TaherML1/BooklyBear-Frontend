import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/auth_state_provider.dart';
import '../features/onboarding/data/onboarding_repository.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/search_screen.dart';
import '../screens/book_details_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/main_scaffold.dart';
import '../screens/library_screen.dart';
import '../screens/groups_screen.dart';
import '../screens/group_details_screen.dart';
import '../screens/create_group_screen.dart';
import '../screens/friends_list_screen.dart';
import '../screens/public_profile_screen.dart';
import '../screens/focus_timer_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/discovery/presentation/book_swipe_screen.dart';

// Key for the root navigator (the one that handles full-screen pushes)
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Tri-state for onboarding: null = not yet checked, true = completed, false = needs onboarding
final onboardingCompletedProvider = StateProvider<bool?>((ref) => null);

// We turn GoRouter into a Provider so it can read other providers
final goRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _RouterRefreshListenable(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshListenable,

    // This function runs on every navigation change OR refreshListenable notification
    redirect: (BuildContext context, GoRouterState state) {
      // READ the auth state (don't watch here to avoid recreating GoRouter)
      final authState = ref.read(authStateProvider);
      
      // If we are loading, show the splash screen
      if (authState == AuthState.loading) {
        return '/splash';
      }

      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';
      final isOnboarding = state.matchedLocation == '/onboarding';

      // If we are NOT authenticated...
      if (authState == AuthState.unauthenticated) {
        // ...and trying to go anywhere *but* login/signup, redirect to login.
        return isLoggingIn ? null : '/login';
      }

      // If we ARE authenticated...
      if (authState == AuthState.authenticated) {
        // ...and trying to go to login/signup/splash...
        if (isLoggingIn || state.matchedLocation == '/splash') {
          // Check onboarding status before going home
          final onboardingDone = ref.read(onboardingCompletedProvider);
          
          if (onboardingDone == null) {
            // Not yet checked — trigger the async check
            _checkOnboardingStatus(ref);
            // Show splash while we check
            return '/splash';
          }
          
          if (onboardingDone == false) {
            return '/onboarding';
          }
          
          return '/home';
        }

        // If they're already on /onboarding, let them stay
        if (isOnboarding) {
          return null;
        }
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/book/:isbn', // Full screen push outside the shell
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final isbn = state.pathParameters['isbn']!;
          return BookDetailsScreen(isbn: isbn);
        },
      ),
      GoRoute(
        path: '/discover',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BookSwipeScreen(),
      ),
      GoRoute(
        path: '/timer/:userBookId', // Full-screen focus timer outside the shell
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final userBookId = state.pathParameters['userBookId']!;
          final bookTitle = state.uri.queryParameters['title'] ?? 'Your Book';
          return FocusTimerScreen(
            userBookId: userBookId,
            bookTitle: bookTitle,
          );
        },
      ),

      // --- StatefulShellRoute for BottomNavigationBar ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Branch 1: Discover / Search
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          // Branch 2: Library
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => const LibraryScreen(),
              ),
            ],
          ),
          // Branch 3: Groups
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/groups',
                builder: (context, state) => const GroupsScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const CreateGroupScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => GroupDetailsScreen(groupId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          // Branch 4: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'friends',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const FriendsListScreen(),
                  ),
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      return EditProfileScreen(
                        initialDisplayName: extra?['displayName'] ?? '',
                        initialBio: extra?['bio'],
                      );
                    },
                  ),
                  GoRoute(
                    path: ':username',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => PublicProfileScreen(username: state.pathParameters['username']!),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Fetches onboarding status from the API and updates the cached provider.
/// This triggers a router refresh which re-evaluates the redirect.
Future<void> _checkOnboardingStatus(Ref ref) async {
  try {
    final repo = ref.read(onboardingRepositoryProvider);
    final status = await repo.getOnboardingStatus();
    ref.read(onboardingCompletedProvider.notifier).state =
        status['completed'] == true;
  } catch (e) {
    // On error, assume onboarding is done so we don't block the user
    ref.read(onboardingCompletedProvider.notifier).state = true;
  }
}

/// Listens to both authState AND onboardingCompleted to trigger router refreshes.
class _RouterRefreshListenable extends ChangeNotifier {
  _RouterRefreshListenable(Ref ref) {
    ref.listen(authStateProvider, (_, next) {
      // Reset onboarding status when auth changes (login/logout)
      if (next == AuthState.unauthenticated) {
        ref.read(onboardingCompletedProvider.notifier).state = null;
      }
      notifyListeners();
    });
    ref.listen(onboardingCompletedProvider, (_, __) => notifyListeners());
  }
}
