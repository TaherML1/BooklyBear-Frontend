import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ─── The Editorial Curator Design System ────────────────────────────────────
/// Ported from the BooklyBear Stitch project's "Editorial Curator" design tokens.
///
/// Creative North Star: "The Digital Archivist"
/// – Scholarly, warm, tactile. Feels like a high-end literary journal.
/// – No-Line Rule: boundaries via tonal shifts, never 1px borders.
/// – Glassmorphism for floating elements.
/// – Ambient shadows, never hard drop shadows.
class AppTheme {
  AppTheme._();

  // ─── Primary ────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF061B0E);
  static const Color primaryContainer = Color(0xFF0A2012);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF728A77);
  static const Color primaryFixed = Color(0xFFCFE9D3);
  static const Color primaryFixedDim = Color(0xFFB4CDB8);
  static const Color onPrimaryFixed = Color(0xFF0A2012);
  static const Color onPrimaryFixedVariant = Color(0xFF364C3C);
  static const Color inversePrimary = Color(0xFFB4CDB8);

  // ─── Secondary ──────────────────────────────────────────────────────────
  static const Color secondary = Color(0xFF586158);
  static const Color secondaryContainer = Color(0xFFD9E2D8);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF5C655D);
  static const Color secondaryFixed = Color(0xFFDCE5DA);
  static const Color secondaryFixedDim = Color(0xFFC0C9BF);

  // ─── Tertiary ───────────────────────────────────────────────────────────
  static const Color tertiary = Color(0xFF000000);
  static const Color tertiaryContainer = Color(0xFF2A1520);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF9B7B89);
  static const Color tertiaryFixed = Color(0xFFFFD8E8);
  static const Color tertiaryFixedDim = Color(0xFFE1BDCC);

  // ─── Surfaces (The "Paper Stack") ───────────────────────────────────────
  static const Color surface = Color(0xFFFCF9EE);
  static const Color surfaceBright = Color(0xFFFCF9EE);
  static const Color surfaceDim = Color(0xFFDDDAD0);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF7F4E9);
  static const Color surfaceContainer = Color(0xFFF1EEE3);
  static const Color surfaceContainerHigh = Color(0xFFEBE8DD);
  static const Color surfaceContainerHighest = Color(0xFFE5E3D8);
  static const Color surfaceVariant = Color(0xFFE5E3D8);
  static const Color surfaceTint = Color(0xFF4D6452);
  static const Color inverseSurface = Color(0xFF31312A);
  static const Color inverseOnSurface = Color(0xFFF4F1E6);

  // ─── On-Surface ─────────────────────────────────────────────────────────
  static const Color onSurface = Color(0xFF1C1C16);
  static const Color onSurfaceVariant = Color(0xFF434843);
  static const Color onBackground = Color(0xFF1C1C16);

  // ─── Outline ────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFF737972);
  static const Color outlineVariant = Color(0xFFC3C8C1);

  // ─── Error ──────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  // ─── Design System Helpers ──────────────────────────────────────────────

  /// Ambient shadow – mimics a library‑lamp glow, not a hard drop shadow.
  static List<BoxShadow> get ambientShadow => [
        BoxShadow(
          color: onSurface.withAlpha(10), // ~4% opacity
          blurRadius: 40,
          offset: const Offset(0, 10),
        ),
      ];

  /// Ghost border — a "whisper" of a boundary (primary at 20% opacity, 2px).
  static Border get ghostBorder => Border.all(
        color: primary.withAlpha(51), // 20%
        width: 2,
      );

  /// Ghost border (light variant) for cards/containers.
  static Border get ghostBorderLight => Border.all(
        color: outlineVariant.withAlpha(38), // 15%
        width: 1,
      );

  /// Glassmorphism decoration for floating elements (nav bars, modals).
  static BoxDecoration get glassmorphism => BoxDecoration(
        color: surface.withAlpha(204), // 80%
        borderRadius: BorderRadius.circular(24),
      );

  /// Gradient for primary CTA buttons – primary → primaryContainer.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Section background — tonal shift for grouping (No-Line Rule).
  static BoxDecoration sectionDecoration({
    Color color = surfaceContainerLow,
    double radius = 16,
  }) =>
      BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      );

  /// Card decoration — elevated paper on the tonal stack.
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ambientShadow,
      );

  // ─── ThemeData ──────────────────────────────────────────────────────────

  static ThemeData get themeData {
    final baseTextTheme = GoogleFonts.interTextTheme();

    // Typography: Noto Serif for display/headline, Inter for body/label
    final textTheme = baseTextTheme.copyWith(
      displayLarge: GoogleFonts.notoSerif(
        textStyle: baseTextTheme.displayLarge?.copyWith(
          color: onSurface,
          letterSpacing: -0.5,
        ),
      ),
      displayMedium: GoogleFonts.notoSerif(
        textStyle: baseTextTheme.displayMedium?.copyWith(
          color: onSurface,
          letterSpacing: -0.25,
        ),
      ),
      displaySmall: GoogleFonts.notoSerif(
        textStyle: baseTextTheme.displaySmall?.copyWith(color: onSurface),
      ),
      headlineLarge: GoogleFonts.notoSerif(
        textStyle: baseTextTheme.headlineLarge?.copyWith(
          color: onSurface,
          letterSpacing: 0.5,
        ),
      ),
      headlineMedium: GoogleFonts.notoSerif(
        textStyle: baseTextTheme.headlineMedium?.copyWith(
          color: onSurface,
          letterSpacing: 0.2,
        ),
      ),
      headlineSmall: GoogleFonts.notoSerif(
        textStyle: baseTextTheme.headlineSmall?.copyWith(color: onSurface),
      ),
      titleLarge: GoogleFonts.notoSerif(
        textStyle: baseTextTheme.titleLarge?.copyWith(color: onSurface),
      ),
      titleMedium: GoogleFonts.inter(
        textStyle: baseTextTheme.titleMedium?.copyWith(color: onSurface),
      ),
      titleSmall: GoogleFonts.inter(
        textStyle: baseTextTheme.titleSmall?.copyWith(color: onSurface),
      ),
      bodyLarge: GoogleFonts.inter(
        textStyle: baseTextTheme.bodyLarge?.copyWith(
          color: onSurface,
          height: 1.6, // Editorial breathing room
        ),
      ),
      bodyMedium: GoogleFonts.inter(
        textStyle: baseTextTheme.bodyMedium?.copyWith(
          color: onSurface,
          height: 1.5,
        ),
      ),
      bodySmall: GoogleFonts.inter(
        textStyle: baseTextTheme.bodySmall?.copyWith(color: onSurfaceVariant),
      ),
      labelLarge: GoogleFonts.inter(
        textStyle: baseTextTheme.labelLarge?.copyWith(color: onSurface),
      ),
      labelMedium: GoogleFonts.inter(
        textStyle: baseTextTheme.labelMedium?.copyWith(color: onSurfaceVariant),
      ),
      labelSmall: GoogleFonts.inter(
        textStyle: baseTextTheme.labelSmall?.copyWith(color: onSurfaceVariant),
      ),
    );

    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      primaryFixed: primaryFixed,
      primaryFixedDim: primaryFixedDim,
      onPrimaryFixed: onPrimaryFixed,
      onPrimaryFixedVariant: onPrimaryFixedVariant,
      inversePrimary: inversePrimary,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      secondaryFixed: secondaryFixed,
      secondaryFixedDim: secondaryFixedDim,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      tertiaryFixed: tertiaryFixed,
      tertiaryFixedDim: tertiaryFixedDim,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      surface: surface,
      onSurface: onSurface,
      surfaceDim: surfaceDim,
      surfaceBright: surfaceBright,
      surfaceContainerLowest: surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHighest,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      inverseSurface: inverseSurface,
      onInverseSurface: inverseOnSurface,
      surfaceTint: surfaceTint,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      useMaterial3: true,
      textTheme: textTheme,

      // ── AppBar — transparent, editorial ───────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.notoSerif(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        iconTheme: const IconThemeData(color: onSurface, size: 22),
      ),

      // ── No-Line Rule: transparent dividers ────────────────────────────
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        space: 24,
        thickness: 0,
      ),

      // ── Cards — tonal layering, no borders, ambient shadow ────────────
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide.none,
        ),
      ),

      // ── Filled Buttons — gradient primary ─────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryContainer,
          foregroundColor: onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),

      // ── Elevated Buttons ──────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryContainer,
          foregroundColor: onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          elevation: 0,
        ),
      ),

      // ── Text Buttons — primary color, underlined on hover ─────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
      ),

      // ── Outlined Buttons — ghost border ───────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary.withAlpha(51), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),

      // ── Input fields — ghost border focus ─────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLow,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary.withAlpha(51), width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          color: onSurfaceVariant,
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.inter(
          color: outline,
          fontSize: 14,
        ),
      ),

      // ── Tabs — thin editorial indicator ───────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: onSurfaceVariant,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        dividerColor: Colors.transparent,
      ),

      // ── Navigation Bar — glassmorphism ────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: primaryFixed.withAlpha(100),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        iconTheme: const WidgetStatePropertyAll(
          IconThemeData(size: 22, color: onSurfaceVariant),
        ),
      ),

      // ── Chips — pill badges ───────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: primaryFixed,
        labelStyle: GoogleFonts.inter(
          color: onPrimaryFixed,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        shape: const StadiumBorder(),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      // ── Progress Indicator — 4px, editorial pace ──────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: surfaceContainerHighest,
        linearMinHeight: 4,
      ),

      // ── Bottom Sheet — glassmorphism ──────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      // ── Dialog ────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),

      // ── FAB — editorial gradient ──────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryContainer,
        foregroundColor: onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
        ),
      ),

      // ── Slider ────────────────────────────────────────────────────────
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: surfaceContainerHighest,
        thumbColor: primary,
        overlayColor: primary.withAlpha(25),
        trackHeight: 4,
      ),

      // ── Snackbar ──────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: inverseSurface,
        contentTextStyle: GoogleFonts.inter(color: inverseOnSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── ListTile ──────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // ── Popup Menu ────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
