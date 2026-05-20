import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFFD83B73);
  static const Color primaryDark = Color(0xFFA91F55);
  static const Color secondary = Color(0xFF8F1948);
  static const Color accent = Color(0xFFD83B73);
  static const Color accentAlt = Color(0xFFA91F55);
  static const Color success = Color(0xFF6C8B7A);
  static const Color warning = Color(0xFFD08A47);
  static const Color danger = Color(0xFFC75B63);
  static const Color background = Color(0xFFF5F5F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF8DDE5);
  static const Color arena = Color(0xFFF5F5F6);
  static const Color arenaPanel = Color(0xFFFFFFFF);
  static const Color arenaPanelAlt = Color(0xFFF8DDE5);
  static const Color textDark = Color(0xFF202124);
  static const Color textMuted = Color(0xFF6F7177);
  static const Color border = Color(0xFFE5E5EA);

  static const Color cardTeal = Color(0xFF8AA79B);
  static const Color cardClay = Color(0xFFF0B8A8);
  static const Color cardSky = Color(0xFF9AAEB8);
  static const Color cardGold = Color(0xFFF4C56A);
  static const Color cardOlive = Color(0xFFA7B99C);
  static const Color cardCoral = Color(0xFFEF8DA7);
  static const Color cardMint = Color(0xFFD9E7DF);
  static const Color cardSand = Color(0xFFFFE1D8);

  static const List<Color> appGradient = [
    background,
    background,
  ];

  static const List<Color> arenaGradient = [
    background,
    background,
  ];

  static const List<List<Color>> categoryPalettes = [
    [surface, primaryDark],
    [cardSand, cardClay],
    [cardMint, cardTeal],
    [Color(0xFFE8EEF1), cardSky],
    [Color(0xFFFFF2CC), cardGold],
    [Color(0xFFEAF1E6), cardOlive],
    [Color(0xFFFFE2EA), cardCoral],
    [Color(0xFFF1EAF0), secondary],
  ];

  static const List<Color> iconAccentColors = [
    primary,
    secondary,
    cardCoral,
    cardTeal,
    cardSky,
    cardOlive,
    warning,
    danger,
  ];

  static List<Color> categoryPalette(int index) =>
      categoryPalettes[index % categoryPalettes.length];

  static Color iconAccent(int index) =>
      iconAccentColors[index % iconAccentColors.length];

  static bool needsLightIconSurface(Color color) =>
      color == primary ||
      color == primaryDark ||
      color == secondary ||
      color == accent ||
      color == accentAlt ||
      color == cardCoral ||
      color == danger;

  static Color iconSurface(Color color) =>
      needsLightIconSurface(color) ? surface : color.withValues(alpha: 0.16);

  static Color iconBorder(Color color) => needsLightIconSurface(color)
      ? color.withValues(alpha: 0.24)
      : color.withValues(alpha: 0.22);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: 'Tajawal',
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: surface,
        surfaceTint: surfaceAlt,
        error: danger,
        tertiary: accent,
      ),
      fontFamily: 'Tajawal',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
        headlineLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: textDark),
        bodyMedium: TextStyle(fontSize: 14, color: textMuted),
        labelMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: textMuted,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ).apply(fontFamily: 'Tajawal'),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: const TextStyle(fontFamily: 'Tajawal'),
        hintStyle: const TextStyle(fontFamily: 'Tajawal', color: textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: border),
        ),
        color: surface,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: const BorderSide(color: border, width: 1.5),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary.withValues(alpha: 0.34)
              : border.withValues(alpha: 0.55),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: surfaceAlt,
          foregroundColor: textDark,
          selectedBackgroundColor: primary,
          selectedForegroundColor: Colors.white,
          side: const BorderSide(color: border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentTextStyle:
            base.textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),
      scaffoldBackgroundColor: background,
    );
  }
}
