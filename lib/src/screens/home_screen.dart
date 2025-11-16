import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // <-- IMPORT GoRouter
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/presentation/auth_controller.dart'; 

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BooklyBear'),
        actions: [
          // --- 1. ADD PROFILE BUTTON ---
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              context.push('/profile');
            },
          ),
          // --- 2. EXISTING LOGOUT BUTTON ---
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_books, size: 100, color: Colors.brown),
            const SizedBox(height: 20),
            Text(
              'Your Library is Empty',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            const Text('Start by searching for a book!'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/search'); // Navigate to search screen
              },
              icon: const Icon(Icons.search),
              label: const Text('Search Books'),
            )
          ],
        ),
      ),
    );
  }
}