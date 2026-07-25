import 'dart:ui';

import 'package:flame/components.dart';

import 'ids.dart';
import 'weapon_definitions.dart';
import 'weapon_effect_atlas.dart';

class ProjectilePresentationSpec {
  const ProjectilePresentationSpec({
    required this.weaponId,
    required this.assetKey,
    required this.frameSize,
    required this.frameCount,
    required this.atlasRow,
    required this.frameSeconds,
    required this.renderWidth,
    required this.renderHeight,
    required this.bodyLength,
    required this.bodyWidth,
    required this.hitInsetFraction,
    required this.rotateWithVelocity,
    this.assetForwardAngle = 0,
    this.filterQuality = FilterQuality.medium,
  });

  final WeaponId weaponId;
  final String assetKey;
  final double frameSize;
  final int frameCount;
  final int atlasRow;
  final double frameSeconds;
  final double renderWidth;
  final double renderHeight;
  final double bodyLength;
  final double bodyWidth;
  final double hitInsetFraction;
  final bool rotateWithVelocity;
  final double assetForwardAngle;
  final FilterQuality filterQuality;

  Vector2 get renderSize => Vector2(renderWidth, renderHeight);
  Vector2 get bodySize => Vector2(bodyLength, bodyWidth);
  Vector2 get hitBodySize => bodySize * (1 - hitInsetFraction);
}

abstract final class ProjectilePresentationSpecs {
  static const byWeapon = <WeaponId, ProjectilePresentationSpec>{
    gakgungShot: ProjectilePresentationSpec(
      weaponId: gakgungShot,
      assetKey: WeaponEffectAtlas.assetKey,
      frameSize: 64,
      frameCount: 4,
      atlasRow: WeaponEffectAtlas.bowRow,
      frameSeconds: .08,
      renderWidth: 28,
      renderHeight: 28,
      bodyLength: 24,
      bodyWidth: 6,
      hitInsetFraction: .10,
      rotateWithVelocity: true,
    ),
    singijeonVolley: ProjectilePresentationSpec(
      weaponId: singijeonVolley,
      assetKey: 'projectiles/player/singijeon_128.png',
      frameSize: 128,
      frameCount: 4,
      atlasRow: 0,
      frameSeconds: .07,
      renderWidth: 30,
      renderHeight: 24,
      bodyLength: 25,
      bodyWidth: 9,
      hitInsetFraction: .10,
      rotateWithVelocity: true,
    ),
    matchlockCannon: ProjectilePresentationSpec(
      weaponId: matchlockCannon,
      assetKey: 'projectiles/player/matchlock_shot_128.png',
      frameSize: 128,
      frameCount: 4,
      atlasRow: 0,
      frameSeconds: .055,
      renderWidth: 22,
      renderHeight: 18,
      bodyLength: 15,
      bodyWidth: 10,
      hitInsetFraction: .10,
      rotateWithVelocity: true,
    ),
    hawkSummon: ProjectilePresentationSpec(
      weaponId: hawkSummon,
      assetKey: 'projectiles/player/hawk_flight_128.png',
      frameSize: 128,
      frameCount: 4,
      atlasRow: 0,
      frameSeconds: .085,
      renderWidth: 34,
      renderHeight: 24,
      bodyLength: 28,
      bodyWidth: 16,
      hitInsetFraction: .10,
      rotateWithVelocity: true,
    ),
  };

  static final Set<String> requiredAssetKeys = Set.unmodifiable(
    byWeapon.values.map((spec) => spec.assetKey),
  );

  static ProjectilePresentationSpec forWeapon(WeaponId weaponId) {
    final spec = byWeapon[weaponId];
    if (spec == null) {
      throw ArgumentError.value(
        weaponId,
        'weaponId',
        'No projectile presentation is registered',
      );
    }
    return spec;
  }
}
