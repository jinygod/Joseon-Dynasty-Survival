import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/projectile_presentation_spec.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_effect_atlas.dart';

void main() {
  test('every moving player projectile has a complete presentation', () {
    expect(ProjectilePresentationSpecs.byWeapon.keys, {
      gakgungShot,
      singijeonVolley,
      matchlockCannon,
      hawkSummon,
    });

    for (final entry in ProjectilePresentationSpecs.byWeapon.entries) {
      final spec = entry.value;
      expect(spec.weaponId, entry.key);
      expect(spec.frameSize, greaterThan(0));
      expect(spec.frameCount, greaterThan(0));
      expect(spec.frameSeconds, greaterThan(0));
      expect(spec.renderSize.x, greaterThan(0));
      expect(spec.renderSize.y, greaterThan(0));
      expect(spec.bodySize.x, lessThanOrEqualTo(spec.renderSize.x));
      expect(spec.bodySize.y, lessThanOrEqualTo(spec.renderSize.y));
    }
  });

  test('hit bodies stay exactly ten percent inside visible bodies', () {
    for (final spec in ProjectilePresentationSpecs.byWeapon.values) {
      expect(spec.hitInsetFraction, .10);
      expect(spec.hitBodySize.x, closeTo(spec.bodySize.x * .90, 0.0001));
      expect(spec.hitBodySize.y, closeTo(spec.bodySize.y * .90, 0.0001));
    }
  });

  test('preload keys cover every projectile presentation asset once', () {
    expect(ProjectilePresentationSpecs.requiredAssetKeys, {
      WeaponEffectAtlas.assetKey,
      'projectiles/player/singijeon_128.png',
      'projectiles/player/matchlock_shot_128.png',
      'projectiles/player/hawk_flight_128.png',
    });
  });

  test('unknown weapon IDs fail closed instead of using generic art', () {
    expect(
      () => ProjectilePresentationSpecs.forWeapon('unknown_projectile'),
      throwsA(isA<ArgumentError>()),
    );
  });
}
