import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/character_stat_presenter.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';

void main() {
  test('character stats are rounded integer presentation values', () {
    final stats = characterDisplayStats(characterDefinitions.first);

    expect(stats.health, 105);
    expect(stats.moveSpeed, 125);
    expect(stats.attack, isA<int>());
  });
}
