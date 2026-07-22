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

  test('pubspec registers every offline font and license', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('assets/fonts/SongMyung-Regular.ttf'));
    expect(pubspec, contains('assets/fonts/GowunBatang-Regular.ttf'));
    expect(pubspec, contains('assets/fonts/GowunBatang-Bold.ttf'));
    expect(pubspec, contains('assets/fonts/licenses/'));
  });
}
