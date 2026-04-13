import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';

/// Notifier to cache and manage dominant colors for book spines smoothly.
class BookPaletteNotifier extends StateNotifier<Map<String, Color>> {
  BookPaletteNotifier() : super({});

  /// Extracts and caches the dominant color from the given image URL.
  Future<Color> getOrFetchDominantColor(String isbn, String coverImageUrl) async {
    if (state.containsKey(isbn)) {
      return state[isbn]!;
    }

    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        NetworkImage(coverImageUrl),
        maximumColorCount: 10,
      );

      // Prioritize dominant or vibrant colors
      final color = paletteGenerator.dominantColor?.color 
            ?? paletteGenerator.vibrantColor?.color 
            ?? const Color(0xFF5D4037); // fallback wood brown

      // Cache it
      state = {...state, isbn: color};
      return color;
    } catch (e) {
      debugPrint('Failed to extract palette for $isbn: $e');
      final fallback = const Color(0xFF5D4037);
      state = {...state, isbn: fallback};
      return fallback;
    }
  }

  /// Returns the cached color instantly for synchronous UI builds.
  /// If it's not cached yet, it triggers an async fetch and returns a fallback color.
  Color getColorSync(String isbn, String coverImageUrl) {
    if (state.containsKey(isbn)) {
      return state[isbn]!;
    }
    
    // Kick off background fetch
    getOrFetchDominantColor(isbn, coverImageUrl);

    // Provide a rich dark fallback color based on ISBN hash until extraction completes
    const fallbackPalette = [
      Color(0xFF1B2A4A), Color(0xFF2D4A3E), Color(0xFF5C1A2A), 
      Color(0xFF3E2723), Color(0xFF4A3728), Color(0xFF2E3B4E)
    ];
    return fallbackPalette[isbn.hashCode.abs() % fallbackPalette.length];
  }
}

final bookPaletteProvider = StateNotifierProvider<BookPaletteNotifier, Map<String, Color>>(
  (ref) => BookPaletteNotifier(),
);
