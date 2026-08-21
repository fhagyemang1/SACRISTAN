import 'package:flutter/material.dart';
import 'package:liturgical_calendar/liturgical_calendar.dart';

/// Central theme for SACRISTAN.
///
/// Design constraints driven directly by the target users (often older
/// adults, often under time pressure before Mass): large touch targets
/// (minimum 56dp, well above the 48dp platform minimums), high-contrast
/// text, generous spacing, and no control that requires a precise gesture
/// (no swipe-to-delete as the *only* way to do something destructive, no
/// tiny icon-only buttons without labels).
class AppTheme {
  AppTheme._();

  static const double minTouchTarget = 56;
  static const double bigTextScale = 1.15;

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6A1B2B), // deep liturgical red-violet
      brightness: brightness,
      // Bump contrast beyond Material's default tonal palette.
      contrastLevel: 0.5,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      visualDensity: VisualDensity.standard,
      textTheme: Typography.material2021(platform: TargetPlatform.android)
          .black
          .apply(fontSizeFactor: 1.05),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        materialTapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: const VisualDensity(horizontal: 2, vertical: 2),
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 16,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 1 : 2,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Maps a liturgical color to an actual paint color and a human-readable
/// label key, plus a safe-contrast text/icon color to paint on top of it.
class LiturgicalColorSwatch {
  final Color background;
  final Color foreground;
  final String labelKey; // resolved via AppLocalizations by the caller

  const LiturgicalColorSwatch(this.background, this.foreground, this.labelKey);
}

LiturgicalColorSwatch swatchFor(LiturgicalColor color, {bool dark = false}) {
  switch (color) {
    case LiturgicalColor.violet:
      return const LiturgicalColorSwatch(
          Color(0xFF5B3A8E), Colors.white, 'colorViolet');
    case LiturgicalColor.white:
      return dark
          ? const LiturgicalColorSwatch(
              Color(0xFFF5F1E8), Colors.black, 'colorWhite')
          : const LiturgicalColorSwatch(
              Color(0xFFFFFFFF), Colors.black87, 'colorWhite');
    case LiturgicalColor.red:
      return const LiturgicalColorSwatch(
          Color(0xFFB1121C), Colors.white, 'colorRed');
    case LiturgicalColor.green:
      return const LiturgicalColorSwatch(
          Color(0xFF1E6B3E), Colors.white, 'colorGreen');
    case LiturgicalColor.rose:
      return const LiturgicalColorSwatch(
          Color(0xFFE8A3B3), Colors.black87, 'colorRose');
    case LiturgicalColor.gold:
      return const LiturgicalColorSwatch(
          Color(0xFFC9A227), Colors.black87, 'colorGold');
    case LiturgicalColor.black:
      return const LiturgicalColorSwatch(
          Color(0xFF1A1A1A), Colors.white, 'colorBlack');
  }
}
