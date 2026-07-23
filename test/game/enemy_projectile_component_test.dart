import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/enemy_projectile_component.dart';
import 'package:pixel_survivor/game/components/projectile_vfx_component.dart';
import 'package:pixel_survivor/game/content/combat_visual_factory.dart';
import 'package:pixel_survivor/game/components/player_component.dart';

void main() {
  test('hostile projectile advances and expires after its lifetime', () {
    final projectile = EnemyProjectileComponent(
      sourceId: 'sakkat_specter',
      damage: 7,
      position: Vector2.zero(),
      velocity: Vector2(150, 0),
      lifetime: 2,
    );

    projectile.update(.5);
    expect(projectile.position.x, 75);
    expect(projectile.isExpired, isFalse);
    projectile.update(1.5);
    expect(projectile.isExpired, isTrue);
  });

  test('hostile projectile registers only one player overlap', () {
    final projectile = EnemyProjectileComponent(
      sourceId: 'sakkat_specter',
      damage: 7,
      position: Vector2.zero(),
      velocity: Vector2.zero(),
    );
    final player = PlayerComponent(
      slotIndex: 0,
      maxHealth: 100,
      moveSpeed: 100,
      position: Vector2.zero(),
    );

    expect(projectile.overlapsPlayer(player), isTrue);
    expect(projectile.registerHit(), isTrue);
    expect(projectile.registerHit(), isFalse);
    expect(projectile.isSpent, isTrue);
  });

  test(
    'sakkat projectile visible footprint does not alter its 10px hitbox',
    () {
      final projectile = EnemyProjectileComponent(
        sourceId: 'sakkat_specter',
        damage: 1,
        position: Vector2.zero(),
        velocity: Vector2.zero(),
      );
      expect(projectile.size, Vector2.all(10));
      expect(projectile.minimumVisibleFootprint, greaterThanOrEqualTo(34));
      expect(projectile.visualBoxSize, greaterThanOrEqualTo(84));
      expect(projectile.ownsDamageResolution, isFalse);
    },
  );

  test('sakkat projectile composes a centered cached registry child', () async {
    final recorder = PictureRecorder();
    Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint());
    final image = await recorder.endRecording().toImage(1, 1);
    final projectile = EnemyProjectileComponent(
      sourceId: 'sakkat_specter',
      damage: 1,
      position: Vector2.zero(),
      velocity: Vector2(1, 0),
      visualFactory: CombatVisualFactory(
        images: {'projectiles/enemy/sakkat_spirit_projectile_128.png': image},
      ),
    );
    projectile.onMount();
    expect(projectile.registryVisual, isA<ProjectileVfxComponent>());
    expect(projectile.registryVisual!.position, projectile.center);
    expect(
      projectile.registryVisual!.scale.x,
      closeTo(projectile.visualBoxSize / 128, .001),
    );
  });
}
