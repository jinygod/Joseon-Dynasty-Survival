import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
import 'package:pixel_survivor/game/combat/combat_visual_theme.dart';
import 'package:pixel_survivor/game/systems/weapon_synergy_resolver.dart';

void main() {
  test(
    'stable attack identities select the representative weapon palettes',
    () {
      final slash = CombatVisualTheme.forAttack(
        _attack(id: 'hwando_slash', shape: AttackShape.sector),
      );
      final master = CombatVisualTheme.forAttack(
        _attack(
          id: 'hwando_master_finisher',
          shape: AttackShape.line,
          presentation: AttackPresentation.master,
        ),
      );
      final strong = CombatVisualTheme.forAttack(
        _attack(
          id: 'hwando_blade_wave',
          shape: AttackShape.line,
          presentation: AttackPresentation.strong,
        ),
      );
      final seal = CombatVisualTheme.forAttack(
        _attack(id: 'talisman_explosion', shape: AttackShape.circle),
      );
      final synergy = CombatVisualTheme.forAttack(
        _attack(
          id: sealingSlash,
          shape: AttackShape.circle,
          presentation: AttackPresentation.synergy,
        ),
      );

      expect(slash.coreColor, const Color(0xffeafcff));
      expect(slash.edgeColor, const Color(0xff7bdff2));
      expect(slash.family, CombatVisualFamily.hwando);
      expect(master.edgeColor, const Color(0xffffd166));
      expect(strong.edgeColor, const Color(0xffffd166));
      expect(master.strokeWidth, greaterThan(slash.strokeWidth));
      expect(
        master.trailLifetimeSeconds,
        greaterThan(slash.trailLifetimeSeconds),
      );
      expect(master.afterimageCount, lessThanOrEqualTo(3));
      expect(seal.coreColor, const Color(0xffffd166));
      expect(seal.edgeColor, const Color(0xffd1495b));
      expect(seal.family, CombatVisualFamily.talisman);
      expect(synergy.isSynergy, isTrue);
      expect(synergy.family, CombatVisualFamily.synergy);
      expect(synergy.maxAlpha, lessThanOrEqualTo(.88));
    },
  );

  test(
    'presentation geometry is frozen from the immutable attack instance',
    () {
      final origin = Vector2(12, 18);
      final direction = Vector2(0, 5);
      final attack = _attack(
        id: 'hwando_master_left',
        shape: AttackShape.sector,
        origin: origin,
        direction: direction,
        range: 96,
        angleRadians: math.pi,
        activeSeconds: .08,
        lingerSeconds: .12,
        presentation: AttackPresentation.master,
      );
      final geometry = AttackVisualGeometry.fromAttack(attack);

      origin.setValues(300, 300);
      direction.setValues(-1, 0);

      expect(geometry.origin, Vector2(12, 18));
      expect(geometry.direction, Vector2(0, 1));
      expect(geometry.range, 96);
      expect(geometry.angleRadians, math.pi);
      expect(geometry.activeSeconds, .08);
      expect(geometry.lingerSeconds, .12);
    },
  );

  test('presentation contract carries no damage or collision ownership', () {
    final attack = _attack(
      id: 'hwando_slash',
      shape: AttackShape.sector,
      damage: 999,
    );
    final geometry = AttackVisualGeometry.fromAttack(attack);

    expect(geometry.toString(), isNot(contains('999')));
    expect(
      CombatVisualTheme.forAttack(attack).toString(),
      isNot(contains('999')),
    );
    for (final path in [
      'lib/game/components/attack_effect_component.dart',
      'lib/game/components/talisman_presentation_component.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, isNot(contains('DamageEvent')));
      expect(source, isNot(contains('AttackGeometry.contains')));
      expect(source, isNot(contains('takeDamage(')));
      expect(source, isNot(contains('collectDamageEvents(')));
    }
  });
}

AttackInstance _attack({
  required String id,
  required AttackShape shape,
  AttackPresentation presentation = AttackPresentation.normal,
  Vector2? origin,
  Vector2? direction,
  double damage = 1,
  double range = 48,
  double angleRadians = math.pi / 2,
  double radius = 36,
  double width = 12,
  double activeSeconds = .08,
  double lingerSeconds = .14,
}) => AttackInstance(
  spec: AttackSpec(
    id: id,
    shape: shape,
    damage: damage,
    range: range,
    angleRadians: angleRadians,
    radius: radius,
    width: width,
    windupSeconds: 0,
    activeSeconds: activeSeconds,
    lingerSeconds: lingerSeconds,
    knockback: 0,
    slowFraction: 0,
    traits: const {},
    presentation: presentation,
  ),
  origin: origin ?? Vector2.zero(),
  direction: direction ?? Vector2(1, 0),
  sequenceIndex: 0,
);
