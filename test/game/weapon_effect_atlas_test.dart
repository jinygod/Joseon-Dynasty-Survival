import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/weapon_effect_atlas.dart';

void main() {
  test('atlas maps the four implemented weapons to distinct rows', () {
    expect(WeaponEffectAtlas.rowForWeapon('hwando_slash'), 0);
    expect(WeaponEffectAtlas.rowForWeapon('gakgung_shot'), 1);
    expect(WeaponEffectAtlas.rowForWeapon('talisman_throw'), 2);
    expect(WeaponEffectAtlas.rowForWeapon('thunder_crash_bomb'), 3);
    expect(WeaponEffectAtlas.rowForWeapon('unknown'), isNull);
  });

  test('effect progress always resolves to one of four frames', () {
    expect(WeaponEffectAtlas.frameForProgress(-1), 0);
    expect(WeaponEffectAtlas.frameForProgress(0.24), 0);
    expect(WeaponEffectAtlas.frameForProgress(0.25), 1);
    expect(WeaponEffectAtlas.frameForProgress(0.75), 3);
    expect(WeaponEffectAtlas.frameForProgress(2), 3);
  });
}
