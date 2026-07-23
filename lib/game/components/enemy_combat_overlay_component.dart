import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../content/ids.dart';
import 'enemy_component.dart';
import 'talisman_presentation_component.dart';
import '../content/combat_visual_factory.dart';
import '../content/actor_render_sizes.dart';
import '../combat/attack_spec.dart';
import '../combat/attack_visual_event.dart';

class EnemyWarningOverlayComponent extends PositionComponent {
  EnemyWarningOverlayComponent({
    required this.enemy,
    int? stableOrder,
    this.visualFactory,
  }) : stableOrder = stableOrder ?? _nextStableOrder++,
       super(
         position: enemy.position,
         size: enemy.size.clone(),
         anchor: Anchor.center,
         priority: AttackPresentationPriority.warning,
       );

  final EnemyComponent enemy;
  static int _nextStableOrder = 0;
  final int stableOrder;
  double _warningAlpha = .85;
  double get warningAlpha => _warningAlpha;

  static void rankByDistance(
    Iterable<EnemyWarningOverlayComponent> overlays, {
    required Vector2 playerPosition,
  }) {
    final ranked = overlays.toList()
      ..sort((left, right) {
        final distance = left.enemy.position
            .distanceToSquared(playerPosition)
            .compareTo(right.enemy.position.distanceToSquared(playerPosition));
        if (distance != 0) return distance;
        return left.stableOrder.compareTo(right.stableOrder);
      });
    for (var index = 0; index < ranked.length; index += 1) {
      ranked[index]._warningAlpha = .85 * (index < 8 ? 1 : .5);
    }
  }

  final CombatVisualFactory? visualFactory;
  PositionComponent? _delegate;
  PositionComponent? get registryVisual => _delegate;
  (EnemyBehaviorKind, int)? _delegateKey;
  double _visualRadius = 0;
  double _visualLength = 0;
  bool get usesRegistryVisual => _delegate != null;
  bool get startsImageLoadOnMount => false;
  bool get ownsDamageResolution => false;
  double get visualRadius => _visualRadius;
  double get visualLength => _visualLength;
  static const radialActiveDiameter = 114.0;
  static const lineActiveLength = 109.0;

  @override
  void update(double dt) {
    super.update(dt);
    position.setFrom(enemy.position);
    size.setFrom(enemy.size);
    _syncWarningVisual();
  }

  void _syncWarningVisual() {
    final warning = enemy.warningSnapshot;
    if (warning == null) {
      _removeDelegate();
      return;
    }
    final effectId = switch (warning.kind) {
      EnemyBehaviorKind.dash ||
      EnemyBehaviorKind.doubleDash ||
      EnemyBehaviorKind.dive ||
      EnemyBehaviorKind.thrust => 'enemy_line_telegraph',
      EnemyBehaviorKind.ranged => 'enemy_ranged_telegraph',
      EnemyBehaviorKind.shockwave ||
      EnemyBehaviorKind.scream => 'enemy_radial_telegraph',
      _ => null,
    };
    final key = effectId == null ? null : (warning.kind, warning.phaseToken);
    if (key == _delegateKey) {
      return;
    }
    _removeDelegate();
    if (effectId == null ||
        visualFactory == null ||
        visualFactory!.images.containsKey(_assetKey(effectId)) != true) {
      return;
    }
    final radial = effectId == 'enemy_radial_telegraph';
    _visualRadius = radial
        ? warning.range + ActorRenderSizes.playerCollision / 2
        : 0;
    _visualLength = radial
        ? 0
        : warning.range +
              enemy.size.x / 2 +
              ActorRenderSizes.playerCollision / 2;
    final visual = visualFactory!.create(
      _overlayVisualEvent(effectId, warning.durationSeconds),
    );
    if (radial) {
      visual
        ..position = center
        ..scale = Vector2.all(_visualRadius * 2 / radialActiveDiameter);
    } else {
      final direction = warning.direction;
      visual
        ..position = center + direction * (_visualLength / 2)
        ..scale = Vector2(_visualLength / lineActiveLength, 34 / 128)
        ..angle = math.atan2(direction.y, direction.x);
    }
    // The factory component has no image I/O; advance its presentation clock
    // to the immutable snapshot progress before mounting it.
    visual.update(warning.durationSeconds * warning.progress);
    add(visual);
    _delegate = visual;
    _delegateKey = key;
  }

  String _assetKey(String effectId) => switch (effectId) {
    'enemy_line_telegraph' => 'vfx/enemy/line_telegraph_128.png',
    'enemy_ranged_telegraph' => 'vfx/enemy/ranged_telegraph_128.png',
    _ => 'vfx/enemy/radial_telegraph_128.png',
  };

  void _removeDelegate() {
    _delegate?.removeFromParent();
    _delegate = null;
    _delegateKey = null;
    _visualRadius = 0;
    _visualLength = 0;
  }

  @override
  void render(Canvas canvas) {
    if (usesRegistryVisual) return;
    final warning = enemy.warningSnapshot;
    if (warning == null) return;
    final paint = Paint()
      ..color = const Color(0xd9ff476f)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final center = Offset(size.x / 2, size.y / 2);
    if (warning.kind == EnemyBehaviorKind.shockwave ||
        warning.kind == EnemyBehaviorKind.scream) {
      canvas.drawCircle(center, warning.range, paint);
      return;
    }
    final direction = warning.direction;
    canvas.drawLine(
      center,
      center + Offset(direction.x, direction.y) * warning.range,
      paint,
    );
    if (warning.kind == EnemyBehaviorKind.ranged) {
      canvas.drawCircle(center, 4 + warning.progress * 10, paint);
    }
  }
}

class ShieldBlockEffectComponent extends PositionComponent {
  ShieldBlockEffectComponent({
    required Vector2 position,
    required Vector2 facingDirection,
    this.onExpired,
    this.visualFactory,
  }) : _facingDirection = _unit(facingDirection),
       super(
         position: position,
         size: Vector2.all(44),
         anchor: Anchor.center,
         priority: AttackPresentationPriority.attachment,
       );

  static const _lifetime = .22;

  final Vector2 _facingDirection;
  final void Function()? onExpired;
  final CombatVisualFactory? visualFactory;
  double _age = 0;
  bool _expired = false;

  Vector2 get facingDirection => _facingDirection.clone();
  double get lifetime => _lifetime;
  PositionComponent? _registryVisual;
  PositionComponent? get registryVisual => _registryVisual;
  bool get usesRegistryVisual => _registryVisual != null;
  bool get startsImageLoadOnMount => false;
  bool get ownsDamageResolution => false;

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (!_expired && _age >= _lifetime) {
      _expired = true;
      onExpired?.call();
      removeFromParent();
    }
  }

  @override
  void onMount() {
    super.onMount();
    const key = 'vfx/enemy/shield_block_flash_128.png';
    if (visualFactory?.images.containsKey(key) != true) return;
    final visual = visualFactory!.create(
      _overlayVisualEvent('enemy_shield_block_flash', _lifetime),
    );
    visual
      ..position = center
      ..scale = Vector2.all(size.x / 128)
      ..angle = math.atan2(_facingDirection.y, _facingDirection.x);
    add(visual);
    _registryVisual = visual;
  }

  @override
  void render(Canvas canvas) {
    if (usesRegistryVisual) return;
    final progress = (_age / _lifetime).clamp(0, 1).toDouble();
    final angle = math.atan2(_facingDirection.y, _facingDirection.x);
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(22, 22), radius: 17 + progress * 4),
      angle - math.pi / 3,
      math.pi * 2 / 3,
      false,
      Paint()
        ..color = const Color(0xffe0fbfc).withValues(alpha: 1 - progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * (1 - progress) + 1
        ..strokeCap = StrokeCap.round,
    );
  }
}

AttackVisualEvent _overlayVisualEvent(String effectId, double duration) =>
    AttackVisualEvent.fromAttack(
      AttackInstance(
        spec: AttackSpec(
          id: effectId,
          shape: AttackShape.circle,
          damage: 0,
          range: 0,
          angleRadians: 0,
          radius: 0,
          width: 0,
          windupSeconds: 0,
          activeSeconds: duration,
          lingerSeconds: 0,
          knockback: 0,
          slowFraction: 0,
          traits: const {},
          presentation: AttackPresentation.master,
        ),
        origin: Vector2.zero(),
        direction: Vector2(1, 0),
        sequenceIndex: 0,
      ),
    );

Vector2 _unit(Vector2 direction) {
  if (direction.length2 == 0) return Vector2(1, 0);
  return direction.clone()..normalize();
}
