import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/joseon_ui_theme.dart';

void main() {
  test('theme uses bundled Joseon font families', () {
    final theme = JoseonUiTheme.create();

    expect(
      theme.textTheme.bodyMedium?.fontFamily,
      JoseonUiTheme.bodyFontFamily,
    );
    expect(
      JoseonUiTheme.displayStyle.fontFamily,
      JoseonUiTheme.displayFontFamily,
    );
  });

  test('theme preserves Material text metrics across Joseon families', () {
    final textTheme = JoseonUiTheme.create().textTheme;

    expect(textTheme.displayLarge?.fontFamily, JoseonUiTheme.displayFontFamily);
    expect(
      textTheme.headlineMedium?.fontFamily,
      JoseonUiTheme.displayFontFamily,
    );
    expect(textTheme.titleMedium?.fontFamily, JoseonUiTheme.bodyFontFamily);
    expect(textTheme.bodyMedium?.fontFamily, JoseonUiTheme.bodyFontFamily);
    expect(textTheme.labelLarge?.fontFamily, JoseonUiTheme.bodyFontFamily);

    expect(textTheme.displayLarge?.fontSize, isNotNull);
    expect(textTheme.headlineMedium?.fontSize, isNotNull);
    expect(textTheme.titleMedium?.fontSize, isNotNull);
    expect(textTheme.bodyMedium?.fontSize, isNotNull);
    expect(textTheme.labelLarge?.fontSize, isNotNull);
  });

  test('pubspec registers every offline font and license', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('assets/fonts/SongMyung-Regular.ttf'));
    expect(pubspec, contains('assets/fonts/GowunBatang-Regular.ttf'));
    expect(pubspec, contains('assets/fonts/GowunBatang-Bold.ttf'));
    expect(pubspec, contains('assets/fonts/licenses/'));
  });
}
