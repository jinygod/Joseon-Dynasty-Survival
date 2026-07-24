import 'package:flutter/material.dart';

/// Shared typography and colors for Joseon-inspired application surfaces.
abstract final class JoseonUiTheme {
  static const displayFontFamily = 'SongMyung';
  static const bodyFontFamily = 'GowunBatang';

  static const navy = Color(0xff14233b);
  static const ivory = Color(0xfff5edd7);
  static const paper = ivory;
  static const jade = Color(0xff216b5a);
  static const crimson = Color(0xff9e2f2f);
  static const gold = Color(0xffb8862c);
  static const ink = Color(0xff2b251d);
  static const danger = crimson;
  static const unlocked = jade;

  static const panelBorderWidth = 1.0;
  static const compactSpacing = 8.0;
  static const compactRadius = BorderRadius.all(Radius.circular(8));
  static const panelRadius = BorderRadius.all(Radius.circular(12));

  static const displayStyle = TextStyle(
    fontFamily: displayFontFamily,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );

  static ThemeData create() {
    final typography = Typography.material2021(
      platform: TargetPlatform.android,
    );
    final bodyTextTheme = typography.englishLike.apply(
      bodyColor: ink,
      displayColor: ink,
      fontFamily: bodyFontFamily,
    );

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
      typography: typography,
      textTheme: bodyTextTheme.copyWith(
        displayLarge: bodyTextTheme.displayLarge?.copyWith(
          fontFamily: displayFontFamily,
          fontWeight: displayStyle.fontWeight,
          letterSpacing: displayStyle.letterSpacing,
        ),
        displayMedium: bodyTextTheme.displayMedium?.copyWith(
          fontFamily: displayFontFamily,
          fontWeight: displayStyle.fontWeight,
          letterSpacing: displayStyle.letterSpacing,
        ),
        displaySmall: bodyTextTheme.displaySmall?.copyWith(
          fontFamily: displayFontFamily,
          fontWeight: displayStyle.fontWeight,
          letterSpacing: displayStyle.letterSpacing,
        ),
        headlineLarge: bodyTextTheme.headlineLarge?.copyWith(
          fontFamily: displayFontFamily,
          fontWeight: displayStyle.fontWeight,
          letterSpacing: displayStyle.letterSpacing,
        ),
        headlineMedium: bodyTextTheme.headlineMedium?.copyWith(
          fontFamily: displayFontFamily,
          fontWeight: displayStyle.fontWeight,
          letterSpacing: displayStyle.letterSpacing,
        ),
        headlineSmall: bodyTextTheme.headlineSmall?.copyWith(
          fontFamily: displayFontFamily,
          fontWeight: displayStyle.fontWeight,
          letterSpacing: displayStyle.letterSpacing,
        ),
      ),
    );
  }
}
