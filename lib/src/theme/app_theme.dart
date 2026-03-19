import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Tokens
  static const Color primary = Color(0xFF061B0E);
  static const Color primaryContainer = Color(0xFF1B3022);
  static const Color onPrimary = Color(0xFFFFFFFF);
  
  static const Color surface = Color(0xFFFCF9EE);
  static const Color surfaceContainerLow = Color(0xFFF7F4E9);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1C1C15);
  static const Color outlineVariant = Color(0xFFC3C8C1);

  static ThemeData get themeData {
    // Fonts
    final baseTextTheme = GoogleFonts.interTextTheme();
    
    // Create text theme based on Editorial Curator design
    final textTheme = baseTextTheme.copyWith(
      displayLarge: GoogleFonts.notoSerif(textStyle: baseTextTheme.displayLarge?.copyWith(color: onSurface)),
      displayMedium: GoogleFonts.notoSerif(textStyle: baseTextTheme.displayMedium?.copyWith(color: onSurface)),
      displaySmall: GoogleFonts.notoSerif(textStyle: baseTextTheme.displaySmall?.copyWith(color: onSurface)),
      headlineLarge: GoogleFonts.notoSerif(textStyle: baseTextTheme.headlineLarge?.copyWith(color: onSurface, letterSpacing: 0.5)),
      headlineMedium: GoogleFonts.notoSerif(textStyle: baseTextTheme.headlineMedium?.copyWith(color: onSurface, letterSpacing: 0.2)),
      headlineSmall: GoogleFonts.notoSerif(textStyle: baseTextTheme.headlineSmall?.copyWith(color: onSurface)),
      titleLarge: GoogleFonts.notoSerif(textStyle: baseTextTheme.titleLarge?.copyWith(color: onSurface)),
      titleMedium: GoogleFonts.inter(textStyle: baseTextTheme.titleMedium?.copyWith(color: onSurface)),
      titleSmall: GoogleFonts.inter(textStyle: baseTextTheme.titleSmall?.copyWith(color: onSurface)),
      bodyLarge: GoogleFonts.inter(textStyle: baseTextTheme.bodyLarge?.copyWith(color: onSurface)),
      bodyMedium: GoogleFonts.inter(textStyle: baseTextTheme.bodyMedium?.copyWith(color: onSurface)),
      bodySmall: GoogleFonts.inter(textStyle: baseTextTheme.bodySmall?.copyWith(color: onSurface)),
      labelLarge: GoogleFonts.inter(textStyle: baseTextTheme.labelLarge?.copyWith(color: onSurface)),
      labelMedium: GoogleFonts.inter(textStyle: baseTextTheme.labelMedium?.copyWith(color: onSurface)),
      labelSmall: GoogleFonts.inter(textStyle: baseTextTheme.labelSmall?.copyWith(color: onSurface)),
    );

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        primaryContainer: primaryContainer,
        onPrimary: onPrimary,
        surface: surface,
        onSurface: onSurface,
        outlineVariant: outlineVariant, // For subtle lines if needed
      ),
      scaffoldBackgroundColor: surface,
      useMaterial3: true,
      textTheme: textTheme,
      
      // No-Line Rule: Transparent dividers
      dividerTheme: const DividerThemeData(
        color: Colors.transparent, 
        space: 24, // Use spacing rather than lines
        thickness: 0,
      ),
      
      // No-Line Rule: Cards with no border and tonal layering
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0, // Depth is achieved by placing on `surfaceContainerLow` or `surface`
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide.none, // Strictly no line
        ),
      ),

      // Input fields matching the minimal variant styling
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // Strictly no line
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          // "Shift background to surface-container-lowest and add a Ghost Border of primary at 20% opacity"
          borderSide: BorderSide(color: primary.withAlpha(51), width: 1),
        ),
      ),
    );
  }
}
