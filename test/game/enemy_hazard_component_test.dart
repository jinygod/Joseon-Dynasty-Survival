import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:pixel_survivor/game/components/enemy_hazard_component.dart';
import 'package:pixel_survivor/game/components/player_component.dart';

void main() {
  test('poison damages once per interval and expires', () {
    final hazard = EnemyHazardComponent.poison(
      position: Vector2.zero(),
      damage: 4,
      sourceId: 'herbalist',
    );
    final player = PlayerComponent(
      slotIndex: 0,
      maxHealth: 100,
      moveSpeed: 100,
      position: Vector2.zero(),
    );

    expect(hazard.damageFor(player), 4);
    expect(hazard.damageFor(player), 0);
    hazard.update(.5);
    expect(hazard.damageFor(player), 4);
    hazard.update(3.5);
    expect(hazard.isExpired, isTrue);
    expect(hazard.damageFor(player), 0);
  });

  test('hazard does not damage players outside its radius', () {
    final hazard = EnemyHazardComponent.shockwave(
      position: Vector2.zero(),
      radius: 20,
      damage: 10,
      sourceId: 'jangseung',
    );
    final player = PlayerComponent(
      slotIndex: 0,
      maxHealth: 100,
      moveSpeed: 100,
      position: Vector2(100, 0),
    );

    expect(hazard.damageFor(player), 0);
  });

  test(
    'poison, shockwave, and scream hazards have distinct silhouettes',
    () async {
      final hazards = [
        EnemyHazardComponent.poison(
          position: Vector2.zero(),
          damage: 1,
          sourceId: 'poison',
        ),
        EnemyHazardComponent.shockwave(
          position: Vector2.zero(),
          radius: 38,
          damage: 1,
          sourceId: 'shockwave',
        ),
        EnemyHazardComponent.scream(
          position: Vector2.zero(),
          radius: 38,
          damage: 1,
          sourceId: 'scream',
        ),
      ];

      final counts = <int>[];
      for (final hazard in hazards) {
        final image = await _renderHazard(hazard);
        addTearDown(image.dispose);
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        counts.add(_countVisiblePixels(data!));
      }

      expect(counts.toSet(), hasLength(3));
    },
  );
}

Future<ui.Image> _renderHazard(EnemyHazardComponent hazard) {
  final recorder = ui.PictureRecorder();
  hazard.render(ui.Canvas(recorder));
  return recorder.endRecording().toImage(96, 96);
}

int _countVisiblePixels(ByteData data) {
  var count = 0;
  for (var offset = 3; offset < data.lengthInBytes; offset += 4) {
    if (data.getUint8(offset) > 0) count += 1;
  }
  return count;
}
