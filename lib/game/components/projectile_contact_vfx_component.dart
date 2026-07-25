import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'talisman_presentation_component.dart';

class ProjectileContactVfxComponent extends PositionComponent {
  ProjectileContactVfxComponent({
    required Vector2 position,
    required Vector2 direction,
    required Image image,
    this.onExpired,
  }) : _direction = _unit(direction),
       _sprites = _spritesFor(image),
       super(
         position: position.clone(),
         size: Vector2.all(30),
         anchor: Anchor.center,
         priority: AttackPresentationPriority.impact,
       );

  ProjectileContactVfxComponent.withoutImageForTesting({
    required Vector2 position,
    required Vector2 direction,
    this.onExpired,
  }) : _direction = _unit(direction),
       _sprites = const [],
       super(
         position: position.clone(),
         size: Vector2.all(30),
         anchor: Anchor.center,
         priority: AttackPresentationPriority.impact,
       );

  static const assetKey = 'vfx/player/projectile_contact_128.png';
  static const lifetime = .14;
  static const frameSize = 128.0;
  static const frameTotal = 6;

  final Vector2 _direction;
  final List<Sprite> _sprites;
  final void Function()? onExpired;
  double _age = 0;
  bool _expired = false;

  bool get isExpired => _expired;
  int get frameCount => frameTotal;
  double get facingAngle => math.atan2(_direction.y, _direction.x);

  @override
  void update(double dt) {
    super.update(dt);
    if (dt.isFinite && dt > 0) {
      _age += dt;
    }
    if (!_expired && _age >= lifetime - 1e-9) {
      _expired = true;
      onExpired?.call();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_sprites.isEmpty) return;
    final progress = (_age / lifetime).clamp(0, 1).toDouble();
    final frame = (progress * frameTotal).floor().clamp(0, frameTotal - 1);
    canvas.save();
    canvas.rotate(facingAngle);
    _sprites[frame].render(canvas, size: size);
    canvas.restore();
  }
}

List<Sprite> _spritesFor(Image image) => List<Sprite>.generate(
  ProjectileContactVfxComponent.frameTotal,
  (frame) => Sprite(
    image,
    srcPosition: Vector2(frame * ProjectileContactVfxComponent.frameSize, 0),
    srcSize: Vector2.all(ProjectileContactVfxComponent.frameSize),
  ),
  growable: false,
);

Vector2 _unit(Vector2 value) {
  if (value.length2 == 0) return Vector2(1, 0);
  return value.clone()..normalize();
}
