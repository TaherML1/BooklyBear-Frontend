import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:booklybear/src/routing/app_router.dart';
import 'package:booklybear/src/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
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
      theme: AppTheme.themeData,
    );
  }
}