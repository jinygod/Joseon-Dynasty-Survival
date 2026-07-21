import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/ids.dart';
import 'package:pixel_survivor/game/content/playtest_content_policy.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';

void main() {
  test(
    'playtest policy opens every implemented base weapon without mutating input',
    () {
      final saved = <WeaponId>{hwandoSlash};
      final resolved = const PlaytestContentPolicy(
        unlockAllBaseWeapons: true,
      ).resolveWeaponIds(saved);
      expect(resolved, weaponDefinitions.map((item) => item.id).toSet());
      expect(saved, {hwandoSlash});
    },
  );

  test('normal policy preserves the supplied unlock set', () {
    expect(
      const PlaytestContentPolicy(
        unlockAllBaseWeapons: false,
      ).resolveWeaponIds({hwandoSlash, talismanThrow}),
      {hwandoSlash, talismanThrow},
    );
  });
}
