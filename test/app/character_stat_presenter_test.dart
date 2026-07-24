import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/character_stat_presenter.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/ids.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';

void main() {
  test('character stats are rounded integer presentation values', () {
    const character = CharacterDefinition(
      id: 'presentation_test_character',
      name: 'Presentation test',
      maxHealth: 104.6,
      moveSpeed: 124.5,
      damageMultiplier: 1.26,
      startingWeaponId: hwandoSlash,
    );
    final stats = characterDisplayStats(character);

    expect(stats.health, 105);
    expect(stats.moveSpeed, 125);
    expect(stats.attack, 10);
    expect(stats.attack, isA<int>());
  });

  test('character display stats leave character definitions unchanged', () {
    final character = characterDefinitions.first;

    characterDisplayStats(character);

    expect(character.maxHealth, 105);
    expect(character.moveSpeed, 125);
    expect(character.damageMultiplier, 1);
  });
}
