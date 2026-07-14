import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';

import '../content/combat_effect_atlas.dart';

class CombatEffectComponent extends PositionComponent {
  CombatEffectComponent({
    required this.kind,
    required Vector2 position,
    this.lifetime = 0.32,
    this.onExpired,
    Vector2? size,
  }) : super(
         position: position,
         size: size ?? Vector2.all(36),
         anchor: Anchor.center,
         priority: 90,
       );

  final CombatEffectKind kind;
  final double lifetime;
  final void Function()? onExpired;

  double _age = 0;
  bool _didExpire = false;
  Image? _atlasImage;

  bool get isExpired => _age >= lifetime;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    unawaited(_loadAtlas());
  }

  Future<void> _loadAtlas() async {
    _atlasImage = await CombatEffectAtlas.load(this);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (isExpired && !_didExpire) {
      _didExpire = true;
      onExpired?.call();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final image = _atlasImage;
    if (image != null) {
      CombatEffectAtlas.sprite(
        image,
        kind: kind,
        frame: CombatEffectAtlas.frameForProgress(_age / lifetime),
      ).render(canvas, size: size);
      return;
    }

    final center = Offset(size.x / 2, size.y / 2);
    final color = switch (kind) {
      CombatEffectKind.experience => const Color(0xff3fbf7f),
      CombatEffectKind.hit => const Color(0xfff4ead2),
      CombatEffectKind.critical => const Color(0xfff2cc8f),
      CombatEffectKind.death => const Color(0xff263849),
      CombatEffectKind.warning => const Color(0xffe63946),
    };
    canvas.drawCircle(
      center,
      size.x * 0.3,
      Paint()
        ..color = color.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}
