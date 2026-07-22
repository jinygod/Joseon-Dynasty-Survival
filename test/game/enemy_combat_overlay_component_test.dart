import 'dart:math' show pi;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
import 'package:pixel_survivor/game/components/attack_effect_component.dart';
import 'package:pixel_survivor/game/components/enemy_combat_overlay_component.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/content/enemy_behavior_definitions.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';
import 'package:pixel_survivor/game/content/ids.dart';

void main() {
  test(
    'overlay style limits warning opacity and keeps shields as low arcs',
    () {
      expect(EnemyCombatOverlayStyle.warningAlpha, lessThanOrEqualTo(.32));
      expect(EnemyCombatOverlayStyle.shieldSweepRadians, closeTo(pi / 2, 1e-9));
      expect(EnemyCombatOverlayStyle.usesFullBodyRectangle, isFalse);
    },
  );

  test(
    'enemy warning overlay stays above attack effects while body stays below',
    () {
      final enemy = EnemyComponent.fromDefinition(
        enemyDefinitionFor(plagueCrow)!,
      )..position.setValues(20, 30);
      final warning = EnemyWarningOverlayComponent(enemy: enemy);
      final attack = AttackEffectComponent(
        instance: AttackInstance(
          spec: AttackSpec(
            id: 'master',
            shape: AttackShape.circle,
            damage: 1,
            range: 0,
            angleRadians: 0,
            radius: 20,
            width: 0,
            windupSeconds: 0,
            activeSeconds: .1,
            lingerSeconds: .1,
            knockback: 0,
            slowFraction: 0,
            traits: const {AttackTrait.master},
            presentation: AttackPresentation.master,
          ),
          origin: Vector2.zero(),
          direction: Vector2(1, 0),
          sequenceIndex: 0,
        ),
      );

      warning.update(0);
      expect(enemy.priority, lessThan(attack.priority));
      expect(warning.priority, greaterThan(attack.priority));
      expect(warning.position, enemy.position);
    },
  );

  test('warning ranks keep the nearest eight at the normal opacity', () {
    final overlays = List.generate(10, (index) {
      final enemy = EnemyComponent(
        enemyId: 'warning-$index',
        maxHealth: 1,
        moveSpeed: 0,
        damage: 0,
        position: Vector2(index.toDouble(), 0),
      );
      return EnemyWarningOverlayComponent(enemy: enemy);
    });

    EnemyWarningOverlayComponent.rankByDistance(
      overlays,
      playerPosition: Vector2.zero(),
    );

    for (var index = 0; index < 8; index += 1) {
      expect(
        overlays[index].warningAlpha,
        EnemyCombatOverlayStyle.warningAlpha,
      );
    }
    expect(overlays[8].warningAlpha, EnemyCombatOverlayStyle.warningAlpha * .5);
    expect(overlays[9].warningAlpha, EnemyCombatOverlayStyle.warningAlpha * .5);
  });

  test('warning rank falls back to stable spawn order for exact ties', () {
    final overlays = List.generate(10, (index) {
      return EnemyWarningOverlayComponent(
        enemy: EnemyComponent(
          enemyId: 'same-warning',
          maxHealth: 1,
          moveSpeed: 0,
          damage: 0,
          position: Vector2(40, 40),
        ),
        stableOrder: index,
      );
    });

    EnemyWarningOverlayComponent.rankByDistance(
      overlays.reversed,
      playerPosition: Vector2.zero(),
    );

    for (final overlay in overlays) {
      expect(
        overlay.warningAlpha,
        overlay.stableOrder < 8
            ? EnemyCombatOverlayStyle.warningAlpha
            : EnemyCombatOverlayStyle.warningAlpha * .5,
        reason: 'stable order ${overlay.stableOrder}',
      );
    }
  });

  test('enemy body render has no duplicate legacy shield arc', () async {
    final enemy = EnemyComponent(
      enemyId: 'shield-body',
      maxHealth: 1,
      moveSpeed: 0,
      damage: 0,
      behaviorType: EnemyBehaviorType.tank,
    );
    final recorder = ui.PictureRecorder();
    enemy.render(ui.Canvas(recorder));
    final image = await recorder.endRecording().toImage(64, 64);
    addTearDown(image.dispose);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    expect(_countExactColor(data!, const ui.Color(0xffbde0fe)), 0);
  });

  test('shield block feedback is visually distinct and short lived', () {
    var expirations = 0;
    final effect = ShieldBlockEffectComponent(
      position: Vector2(10, 20),
      facingDirection: Vector2(0, -1),
      onExpired: () => expirations += 1,
    );

    expect(effect.facingDirection, Vector2(0, -1));
    expect(effect.lifetime, lessThanOrEqualTo(.3));
    expect(
      effect.priority,
      lessThan(
        EnemyWarningOverlayComponent(
          enemy: EnemyComponent(
            enemyId: 'warning-priority',
            maxHealth: 1,
            moveSpeed: 0,
            damage: 0,
          ),
        ).priority,
      ),
    );
    effect.update(effect.lifetime);
    effect.update(1);
    expect(expirations, 1);
  });

  test('dash warning renders a filled lane with readable chevrons', () async {
    final enemy = EnemyComponent(
      enemyId: 'telegraph-dash',
      maxHealth: 1,
      moveSpeed: 400,
      damage: 0,
      behaviorProfile: const EnemyBehaviorProfile(
        id: 'telegraph-dash',
        kind: EnemyBehaviorKind.dash,
        warningSeconds: 1,
        activeSeconds: .5,
      ),
      targetPositionProvider: (_) => Vector2(800, 0),
    );
    enemy.update(.05);
    final overlay = EnemyWarningOverlayComponent(enemy: enemy);

    final image = await _renderComponent(overlay, width: 720, height: 96);
    addTearDown(image.dispose);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    expect(_countVisiblePixels(data!), greaterThan(3000));
  });

  test(
    'ranged warning renders a multi-ring reticle at its locked endpoint',
    () async {
      final enemy = EnemyComponent(
        enemyId: 'telegraph-ranged',
        maxHealth: 1,
        moveSpeed: 0,
        damage: 0,
        behaviorProfile: const EnemyBehaviorProfile(
          id: 'telegraph-ranged',
          kind: EnemyBehaviorKind.ranged,
          warningSeconds: 1,
          range: 120,
        ),
        targetPositionProvider: (_) => Vector2(120, 0),
      );
      enemy.update(.05);
      final overlay = EnemyWarningOverlayComponent(enemy: enemy);

      final image = await _renderComponent(overlay, width: 200, height: 96);
      addTearDown(image.dispose);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

      expect(_countVisiblePixels(data!), greaterThan(150));
    },
  );
}

Future<ui.Image> _renderComponent(
  EnemyWarningOverlayComponent component, {
  required int width,
  required int height,
}) {
  final recorder = ui.PictureRecorder();
  component.render(ui.Canvas(recorder));
  return recorder.endRecording().toImage(width, height);
}

int _countVisiblePixels(ByteData data) {
  var count = 0;
  for (var offset = 3; offset < data.lengthInBytes; offset += 4) {
    if (data.getUint8(offset) > 0) count += 1;
  }
  return count;
}

int _countExactColor(ByteData data, ui.Color color) {
  final argb = color.toARGB32();
  final red = (argb >> 16) & 0xff;
  final green = (argb >> 8) & 0xff;
  final blue = argb & 0xff;
  final alpha = (argb >> 24) & 0xff;
  var count = 0;
  for (var offset = 0; offset < data.lengthInBytes; offset += 4) {
    if (data.getUint8(offset) == red &&
        data.getUint8(offset + 1) == green &&
        data.getUint8(offset + 2) == blue &&
        data.getUint8(offset + 3) == alpha) {
      count += 1;
    }
  }
  return count;
}
