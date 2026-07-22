import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import 'attack_spec.dart';

enum CombatVisualFamily { hwando, talisman, synergy, neutral }

/// Presentation-only values selected from immutable attack identity.
///
/// This contract deliberately excludes damage, targeting, and collision data.
@immutable
class CombatVisualTheme {
  const CombatVisualTheme({
    required this.coreColor,
    required this.edgeColor,
    required this.strokeWidth,
    required this.maxAlpha,
    required this.trailLifetimeSeconds,
    required this.afterimageCount,
    required this.isSynergy,
    required this.family,
  });

  final Color coreColor;
  final Color edgeColor;
  final double strokeWidth;
  final double maxAlpha;
  final double trailLifetimeSeconds;
  final int afterimageCount;
  final bool isSynergy;
  final CombatVisualFamily family;

  static CombatVisualTheme forAttack(AttackInstance attack) {
    final id = attack.spec.id;
    if (id == 'sealing_slash' ||
        attack.spec.presentation == AttackPresentation.synergy) {
      return const CombatVisualTheme(
        coreColor: Color(0xffffd166),
        edgeColor: Color(0xff7bdff2),
        strokeWidth: 8,
        maxAlpha: .88,
        trailLifetimeSeconds: .22,
        afterimageCount: 2,
        isSynergy: true,
        family: CombatVisualFamily.synergy,
      );
    }
    if (id.startsWith('hwando_')) {
      final master = attack.spec.presentation == AttackPresentation.master;
      final emphasized =
          master || attack.spec.presentation == AttackPresentation.strong;
      return CombatVisualTheme(
        coreColor: const Color(0xffeafcff),
        edgeColor: emphasized
            ? const Color(0xffffd166)
            : const Color(0xff7bdff2),
        strokeWidth: master ? 12 : 7,
        maxAlpha: .86,
        trailLifetimeSeconds: master ? .24 : .16,
        afterimageCount: master ? 3 : 1,
        isSynergy: false,
        family: CombatVisualFamily.hwando,
      );
    }
    if (id.startsWith('talisman_')) {
      return const CombatVisualTheme(
        coreColor: Color(0xffffd166),
        edgeColor: Color(0xffd1495b),
        strokeWidth: 7,
        maxAlpha: .84,
        trailLifetimeSeconds: .2,
        afterimageCount: 2,
        isSynergy: false,
        family: CombatVisualFamily.talisman,
      );
    }
    return const CombatVisualTheme(
      coreColor: Color(0xfff4ead2),
      edgeColor: Color(0xff9fb3c8),
      strokeWidth: 5,
      maxAlpha: .78,
      trailLifetimeSeconds: .14,
      afterimageCount: 1,
      isSynergy: false,
      family: CombatVisualFamily.neutral,
    );
  }
}

/// The exact geometry and timing that a renderer is allowed to consume.
///
/// Values are copied from [AttackInstance] once. Presentation code cannot grow
/// beyond gameplay geometry or mutate the attack after it has been resolved.
@immutable
class AttackVisualGeometry {
  AttackVisualGeometry.fromAttack(AttackInstance attack)
    : shape = attack.spec.shape,
      _origin = attack.origin,
      _direction = attack.direction,
      range = attack.spec.range,
      angleRadians = attack.spec.angleRadians,
      radius = attack.spec.radius,
      width = attack.spec.width,
      windupSeconds = attack.spec.windupSeconds,
      activeSeconds = attack.spec.activeSeconds,
      lingerSeconds = attack.spec.lingerSeconds;

  final AttackShape shape;
  final Vector2 _origin;
  final Vector2 _direction;
  final double range;
  final double angleRadians;
  final double radius;
  final double width;
  final double windupSeconds;
  final double activeSeconds;
  final double lingerSeconds;

  Vector2 get origin => _origin.clone();
  Vector2 get direction => _direction.clone();

  @override
  String toString() =>
      'AttackVisualGeometry($shape, origin: $_origin, direction: $_direction, '
      'range: $range, angle: $angleRadians, radius: $radius, width: $width, '
      'timing: $windupSeconds/$activeSeconds/$lingerSeconds)';
}
