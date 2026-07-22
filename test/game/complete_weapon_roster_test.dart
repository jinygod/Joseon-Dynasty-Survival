import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_level_definitions.dart';

void main() {
  test('base roster has twelve weapons with six levels and named masters', () {
    expect(weaponDefinitions, hasLength(12));
    expect(weaponDefinitions.map((definition) => definition.id).toSet(), {
      hwandoSlash,
      gakgungShot,
      talismanThrow,
      thunderCrashBomb,
      jangseungWard,
      singijeonVolley,
      frostFlask,
      windThunderFan,
      matchlockCannon,
      shamanBells,
      dokkaebiChain,
      hawkSummon,
    });

    for (final weapon in weaponDefinitions) {
      expect(weapon.maxLevel, 6, reason: weapon.id);
      expect(weapon.startsUnlocked, isTrue, reason: weapon.id);
      expect(weaponLevels[weapon.id], hasLength(6), reason: weapon.id);
      expect(weaponLevels[weapon.id]!.last.isMaster, isTrue, reason: weapon.id);
      expect(
        weaponLevels[weapon.id]!.last.masterName,
        isNotEmpty,
        reason: weapon.id,
      );
    }
  });

  test('gakgung level six is non-explosive moon-chasing mastery', () {
    final master = weaponLevelFor(gakgungShot, 6);

    expect(master.masterName, '관월추성');
    expect(master.projectileCount, 3);
    expect(master.pierce, greaterThanOrEqualTo(4));
    expect(master.chainCount, 2);
    expect(master.behaviorDescription, isNot(contains('폭발')));
  });
}
