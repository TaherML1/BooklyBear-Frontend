import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:booklybear/src/routing/app_router.dart';

void main() {
  runApp(const ProviderScope(child: BooklyBearApp()));
}

// Make this a ConsumerWidget to read the router provider
class BooklyBearApp extends ConsumerWidget {
  const BooklyBearApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router provider
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'BooklyBear',
      debugShowCheckedModeBanner: false,
      
      // Connect GoRouter
      routerConfig: router, // Use the provider

      // Material 3 Theme
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown, // Bear color! 🐻
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        
        // Nice input styling globally
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.brown, width: 2),
          ),
        ),
      ),
    );
  }
}