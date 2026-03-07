import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/auth_state_provider.dart';
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
import '../screens/focus_timer_screen.dart';

// Key for the root navigator (the one that handles full-screen pushes)
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

// We turn GoRouter into a Provider so it can read other providers
final goRouterProvider = Provider<GoRouter>((ref) {
  // Watch the auth state
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',

    // This function runs on every navigation change
    redirect: (BuildContext context, GoRouterState state) {
      // If we are loading, show the splash screen
      if (authState == AuthState.loading) {
        return '/splash';
      }

      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      // If we are NOT authenticated...
      if (authState == AuthState.unauthenticated) {
        // ...and trying to go anywhere *but* login/signup, redirect to login.
        return isLoggingIn ? null : '/login';
      }

      // If we ARE authenticated...
      if (authState == AuthState.authenticated) {
        // ...and trying to go to login/signup/splash, redirect to home.
        if (isLoggingIn || state.matchedLocation == '/splash') {
          return '/home';
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
        path: '/book/:isbn', // Full screen push outside the shell
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final isbn = state.pathParameters['isbn']!;
          return BookDetailsScreen(isbn: isbn);
        },
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
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
