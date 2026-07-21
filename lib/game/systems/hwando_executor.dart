import 'dart:math';

import 'package:flame/components.dart';

import '../combat/attack_spec.dart';
import '../content/weapon_definitions.dart';
import '../content/weapon_level_definitions.dart';

class HwandoTickInput {
  const HwandoTickInput({
    required this.dt,
    required this.level,
    required this.origin,
    required this.aimDirection,
    required this.damageMultiplier,
    required this.sizeMultiplier,
  });

  final double dt;
  final int level;
  final Vector2 origin;
  final Vector2 aimDirection;
  final double damageMultiplier;
  final double sizeMultiplier;
}

class HwandoExecutor {
  static const maxKillRefundPerCycle = .24;

  final List<_ScheduledHwandoStage> _stages = [];
  double _cooldown = 0;
  double _refundedThisCycle = 0;
  int _cycleLevel = 0;
  _FrozenHwandoInput? _cycleInput;

  List<AttackInstance> tick(HwandoTickInput input) {
    final dt = input.dt.clamp(0, .05).toDouble();
    _cooldown = max(0, _cooldown - dt);

    if (_stages.isNotEmpty) {
      for (final stage in _stages) {
        stage.remainingSeconds -= dt;
      }
      final ready = _stages
          .where((stage) => stage.remainingSeconds <= 0)
          .toList(growable: false);
      _stages.removeWhere((stage) => stage.remainingSeconds <= 0);
      if (ready.isNotEmpty) {
        final cycleInput = _cycleInput!;
        return [for (final stage in ready) stage.instantiate(cycleInput)];
      }
      return const [];
    }

    if (_cooldown > 0 || input.level == 0) return const [];

    final level = weaponLevelFor(hwandoSlash, input.level);
    _cooldown = level.cooldownSeconds;
    _refundedThisCycle = 0;
    _cycleLevel = input.level;
    _cycleInput = _FrozenHwandoInput.from(input, level);
    _stages.addAll(_scheduleFor(input.level));
    return tick(
      HwandoTickInput(
        dt: 0,
        level: input.level,
        origin: input.origin,
        aimDirection: input.aimDirection,
        damageMultiplier: input.damageMultiplier,
        sizeMultiplier: input.sizeMultiplier,
      ),
    );
  }

  void recordKill({required int count}) {
    if (_cycleLevel != 5 || count <= 0) return;
    final refund = min(maxKillRefundPerCycle - _refundedThisCycle, count * .06);
    if (refund <= 0) return;
    _cooldown = max(0, _cooldown - refund);
    _refundedThisCycle += refund;
  }
}

class _FrozenHwandoInput {
  _FrozenHwandoInput.from(HwandoTickInput input, this.level)
    : origin = input.origin.clone(),
      direction = _unit(input.aimDirection),
      damage = level.damage * input.damageMultiplier,
      range = level.range * input.sizeMultiplier,
      sizeMultiplier = input.sizeMultiplier,
      knockback = level.knockback;

  final Vector2 origin;
  final Vector2 direction;
  final double damage;
  final double range;
  final double sizeMultiplier;
  final double knockback;
  final WeaponLevelDefinition level;
}

class _ScheduledHwandoStage {
  _ScheduledHwandoStage(this.id, this.remainingSeconds, this.sequenceIndex);

  final String id;
  double remainingSeconds;
  final int sequenceIndex;

  AttackInstance instantiate(_FrozenHwandoInput input) {
    final isMaster = id.startsWith('hwando_master_');
    final isCircle = id == 'hwando_master_circle';
    final isLine = id == 'hwando_blade_wave' || id == 'hwando_master_finisher';
    final isWide = input.level.isMaster || input.range >= 88;
    final shape = isCircle
        ? AttackShape.circle
        : isLine
        ? AttackShape.line
        : AttackShape.sector;
    final traits = <AttackTrait>{
      AttackTrait.melee,
      if (isLine) AttackTrait.projectile,
      if (isLine) AttackTrait.piercing,
      if (isMaster) AttackTrait.master,
    };
    final direction = _stageDirection(input.direction, id);

    return AttackInstance(
      spec: AttackSpec(
        id: id,
        shape: shape,
        damage: input.damage,
        range: isCircle ? 0 : input.range * (isLine ? 1.35 : 1),
        angleRadians: shape == AttackShape.sector
            ? (isMaster && id != 'hwando_master_opener'
                  ? pi
                  : isWide
                  ? pi * .75
                  : pi / 2)
            : 0,
        radius: isCircle ? input.range : 0,
        width: isLine ? 18 * input.sizeMultiplier : 0,
        windupSeconds: 0,
        activeSeconds: .08,
        lingerSeconds: isLine ? .16 : .12,
        knockback: input.knockback,
        slowFraction: 0,
        traits: traits,
        presentation: isMaster
            ? AttackPresentation.master
            : isLine
            ? AttackPresentation.strong
            : AttackPresentation.normal,
      ),
      origin: input.origin,
      direction: direction,
      sequenceIndex: sequenceIndex,
    );
  }
}

Vector2 _stageDirection(Vector2 aim, String id) {
  final offset = switch (id) {
    'hwando_slash_left' => -pi / 4,
    'hwando_slash_right' => pi / 4,
    'hwando_master_left' => -pi / 2,
    'hwando_master_right' => pi / 2,
    _ => 0.0,
  };
  if (offset == 0) return aim.clone();
  final cosine = cos(offset);
  final sine = sin(offset);
  return Vector2(aim.x * cosine - aim.y * sine, aim.x * sine + aim.y * cosine);
}

List<_ScheduledHwandoStage> _scheduleFor(int level) => switch (level) {
  1 || 2 => [_ScheduledHwandoStage('hwando_slash', 0, 0)],
  3 => [
    _ScheduledHwandoStage('hwando_slash_left', 0, 0),
    _ScheduledHwandoStage('hwando_slash_right', .10, 1),
  ],
  4 || 5 => [
    _ScheduledHwandoStage('hwando_slash_left', 0, 0),
    _ScheduledHwandoStage('hwando_slash_right', .10, 1),
    _ScheduledHwandoStage('hwando_blade_wave', .18, 2),
  ],
  6 => [
    _ScheduledHwandoStage('hwando_master_opener', 0, 0),
    _ScheduledHwandoStage('hwando_master_left', .10, 1),
    _ScheduledHwandoStage('hwando_master_right', .20, 2),
    _ScheduledHwandoStage('hwando_master_circle', .32, 3),
    _ScheduledHwandoStage('hwando_master_finisher', .46, 4),
  ],
  _ => throw RangeError.range(level, 1, 6, 'level'),
};

Vector2 _unit(Vector2 direction) {
  if (direction.length2 == 0) return Vector2(1, 0);
  return direction.clone()..normalize();
}
