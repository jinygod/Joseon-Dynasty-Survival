import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'talisman_presentation_component.dart';

class HwandoContactVfxComponent extends PositionComponent {
  HwandoContactVfxComponent({
    required Vector2 position,
    required Vector2 direction,
    required Image image,
    this.onExpired,
  }) : _direction = _unit(direction),
       _sprites = _spritesFor(image),
       super(
         position: position.clone(),
         size: Vector2.all(36),
         anchor: Anchor.center,
         priority: AttackPresentationPriority.impact,
       );

  HwandoContactVfxComponent.withoutImageForTesting({
    required Vector2 position,
    required Vector2 direction,
    this.onExpired,
  }) : _direction = _unit(direction),
       _sprites = const [],
       super(
         position: position.clone(),
         size: Vector2.all(36),
         anchor: Anchor.center,
         priority: AttackPresentationPriority.impact,
       );

  static const lifetime = .15;
  static const frameCount = 6;
  static const frameSize = 128.0;

  final Vector2 _direction;
  final List<Sprite> _sprites;
  final void Function()? onExpired;
  double _age = 0;
  bool _expired = false;

  double get facingAngle => math.atan2(_direction.y, _direction.x);

  @override
  bool get isRemoving => super.isRemoving || (!isMounted && _expired);

  @override
  void update(double dt) {
    super.update(dt);
    if (dt.isFinite && dt > 0) _age += dt;
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
    final frame = (progress * frameCount).floor().clamp(0, frameCount - 1);
    canvas.save();
    canvas.rotate(facingAngle);
    _sprites[frame].render(canvas, size: size);
    canvas.restore();
  }
}

List<Sprite> _spritesFor(Image image) => List<Sprite>.generate(
  HwandoContactVfxComponent.frameCount,
  (frame) => Sprite(
    image,
    srcPosition: Vector2(frame * HwandoContactVfxComponent.frameSize, 0),
    srcSize: Vector2.all(HwandoContactVfxComponent.frameSize),
  ),
);

Vector2 _unit(Vector2 value) {
  if (value.length2 == 0) return Vector2(1, 0);
  return value.clone()..normalize();
}
