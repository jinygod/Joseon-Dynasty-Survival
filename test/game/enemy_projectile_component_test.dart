import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:pixel_survivor/game/components/enemy_projectile_component.dart';
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
    'hostile projectile renders a bright outlined core with a tail',
    () async {
      final projectile = EnemyProjectileComponent(
        sourceId: 'sakkat_specter',
        damage: 7,
        position: Vector2.zero(),
        velocity: Vector2(-150, 0),
      );
      final recorder = ui.PictureRecorder();
      projectile.render(ui.Canvas(recorder));
      final image = await recorder.endRecording().toImage(64, 32);
      addTearDown(image.dispose);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

      expect(_countVisiblePixels(data!), greaterThan(150));
    },
  );
}

int _countVisiblePixels(ByteData data) {
  var count = 0;
  for (var offset = 3; offset < data.lengthInBytes; offset += 4) {
    if (data.getUint8(offset) > 0) count += 1;
  }
  return count;
}
