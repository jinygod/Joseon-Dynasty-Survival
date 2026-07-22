import 'package:flutter/material.dart';

/// Shared typography and colors for Joseon-inspired application surfaces.
abstract final class JoseonUiTheme {
  static const displayFontFamily = 'SongMyung';
  static const bodyFontFamily = 'GowunBatang';

  static const paper = Color(0xfff5edd7);
  static const jade = Color(0xff216b5a);
  static const crimson = Color(0xff9e2f2f);
  static const gold = Color(0xffb8862c);
  static const ink = Color(0xff2b251d);

  static const displayStyle = TextStyle(
    fontFamily: displayFontFamily,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );

  static ThemeData create() {
    const bodyStyle = TextStyle(fontFamily: bodyFontFamily, color: ink);

    return ThemeData(
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: jade,
        onPrimary: Colors.white,
        secondary: gold,
        onSecondary: ink,
        error: crimson,
        onError: Colors.white,
        surface: paper,
        onSurface: ink,
      ),
      scaffoldBackgroundColor: paper,
      splashFactory: NoSplash.splashFactory,
      useMaterial3: false,
      fontFamily: bodyFontFamily,
      textTheme: const TextTheme(
        displayLarge: displayStyle,
        displayMedium: displayStyle,
        displaySmall: displayStyle,
        headlineLarge: displayStyle,
        headlineMedium: displayStyle,
        headlineSmall: displayStyle,
        titleLarge: bodyStyle,
        titleMedium: bodyStyle,
        titleSmall: bodyStyle,
        bodyLarge: bodyStyle,
        bodyMedium: bodyStyle,
        bodySmall: bodyStyle,
        labelLarge: bodyStyle,
        labelMedium: bodyStyle,
        labelSmall: bodyStyle,
      ),
    );
  }
}
