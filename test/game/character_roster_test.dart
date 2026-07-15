import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/ids.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';

void main() {
  test('playtest roster has three distinct roles and starting weapons', () {
    expect(characterDefinitions.map((item) => item.id).toSet(), {
      rookieConstable,
      exorcistDosa,
      mountainHunter,
    });
    expect(characterDefinitions.map((item) => item.startingWeaponId).toSet(), {
      hwandoSlash,
      talismanThrow,
      gakgungShot,
    });
    expect(characterDefinitions.map((item) => item.passive).toSet(), {
      CharacterPassive.patrolGrit,
      CharacterPassive.exorcismScript,
      CharacterPassive.hawkEye,
    });
    expect(
      characterDefinitions.every(
        (item) =>
            item.passiveName.isNotEmpty && item.passiveDescription.isNotEmpty,
      ),
      isTrue,
    );
  });

  test('mountain hunter is the fast ranged critical character', () {
    final hunter = characterDefinitions.singleWhere(
      (item) => item.id == mountainHunter,
    );

    expect(hunter.maxHealth, 90);
    expect(hunter.moveSpeed, 140);
    expect(hunter.startingWeaponId, gakgungShot);
    expect(hunter.passive, CharacterPassive.hawkEye);
  });
}
