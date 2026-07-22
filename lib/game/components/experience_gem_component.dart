import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../content/combat_effect_atlas.dart';
import 'player_component.dart';

class ExperienceGemComponent extends PositionComponent {
  static const _maximumVisualScale = 1.65;

  ExperienceGemComponent({
    required this.experienceValue,
    Vector2? position,
    this.pickupRadius = 28,
    Vector2? size,
  }) : super(
         position: position ?? Vector2.zero(),
         size: size ?? Vector2.all(20),
         anchor: Anchor.center,
       );

  int experienceValue;
  final double pickupRadius;
  double _age = 0;
  Image? _atlasImage;

  double get visualScale => visualScaleForValue(experienceValue);
  double get haloOpacity => haloOpacityForValue(experienceValue);

  static double visualScaleForValue(int value) {
    final normalizedValue = max(1, value);
    return (1 + (sqrt(normalizedValue) - 1) * .08)
        .clamp(1, _maximumVisualScale)
        .toDouble();
  }

  static double haloOpacityForValue(int value) {
    final scaleProgress =
        (visualScaleForValue(value) - 1) / (_maximumVisualScale - 1);
    return (.16 + scaleProgress * .24).clamp(.16, .40).toDouble();
  }

  void absorbExperience(int amount) {
    if (amount > 0) experienceValue += amount;
  }

  @override
  void onLoad() {
    super.onLoad();
    unawaited(_loadAtlas());
  }

  Future<void> _loadAtlas() async {
    _atlasImage = await CombatEffectAtlas.load(this);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
  }

  bool canBePickedUpBy(PlayerComponent player, {double additionalRadius = 0}) {
    final effectiveRadius = pickupRadius + additionalRadius;
    return position.distanceToSquared(player.position) <=
        effectiveRadius * effectiveRadius;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final center = Offset(size.x / 2, size.y / 2);
    final visualExtent = size.x * visualScale;
    final pulse = 1 + sin(_age * 5.5) * .06;
    final coreRadius = visualExtent * .31;
    final diamond = Path()
      ..moveTo(center.dx, center.dy - coreRadius)
      ..lineTo(center.dx + coreRadius, center.dy)
      ..lineTo(center.dx, center.dy + coreRadius)
      ..lineTo(center.dx - coreRadius, center.dy)
      ..close();

    canvas.drawCircle(
      center,
      visualExtent * .56 * pulse,
      Paint()..color = const Color(0xff58c7ff).withValues(alpha: haloOpacity),
    );
    canvas.drawCircle(
      center,
      visualExtent * .42,
      Paint()..color = const Color(0xff1c7ec9).withValues(alpha: .28),
    );
    canvas.drawPath(diamond, Paint()..color = const Color(0xff45b9f5));

    final image = _atlasImage;
    if (image != null) {
      final accentExtent = visualExtent * .38;
      CombatEffectAtlas.sprite(
        image,
        kind: CombatEffectKind.experience,
        frame: ((_age / 0.10).floor()) % CombatEffectAtlas.framesPerEffect,
      ).render(
        canvas,
        position: Vector2(
          center.dx - accentExtent / 2,
          center.dy - accentExtent / 2,
        ),
        size: Vector2.all(accentExtent),
      );
    }

    canvas.drawPath(
      diamond,
      Paint()
        ..color = const Color(0xffffffff).withValues(alpha: .94)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    for (var index = 0; index < 2; index++) {
      final angle = _age * 3.6 + index * pi;
      final orbitRadius = visualExtent * .47;
      final sparkCenter = Offset(
        center.dx + cos(angle) * orbitRadius,
        center.dy + sin(angle) * orbitRadius,
      );
      canvas.drawCircle(
        sparkCenter,
        1.1 + (visualScale - 1) * 1.2,
        Paint()..color = const Color(0xffffffff).withValues(alpha: .78),
      );
    }
  }
}
