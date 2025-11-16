import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/auth_state_provider.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/search_screen.dart'; // <-- 1. IMPORT
import '../screens/book_details_screen.dart'; // <-- 2. IMPORT
import '../screens/profile_screen.dart';
// We turn GoRouter into a Provider so it can read other providers
final goRouterProvider = Provider<GoRouter>((ref) {
  // Watch the auth state
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    
    // This function runs on every navigation change
    redirect: (BuildContext context, GoRouterState state) {
      
      // If we are loading, show the splash screen
      if (authState == AuthState.loading) {
        return '/splash';
      }

      final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
      
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
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),

      // --- 3. ADD NEW ROUTES BELOW ---
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/book/:isbn', // We pass the isbn as a URL parameter
        builder: (context, state) {
          // Extract the isbn from the URL
          final isbn = state.pathParameters['isbn']!;
          return BookDetailsScreen(isbn: isbn);
        },
      ),
       GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});