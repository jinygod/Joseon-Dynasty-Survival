import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../combat/attack_spec.dart';
import '../combat/attack_visual_event.dart';
import '../combat/combat_vfx_primitives.dart';
import '../content/combat_visual_factory.dart';
import '../content/attack_visual_registry.dart';

class WardAuraComponent extends PositionComponent {
  WardAuraComponent({
    required this.positionProvider,
    required this.radiusProvider,
    CombatVfxTier Function()? tierProvider,
    CombatVisualFactory? visualFactory,
  }) : _tierProvider = tierProvider ?? _normalTier,
       super(anchor: Anchor.center) {
    if (visualFactory != null) attachVisuals(visualFactory);
  }

  final Vector2 Function() positionProvider;
  final double Function() radiusProvider;
  final CombatVfxTier Function() _tierProvider;
  CombatVfxTier get visualTier => _tierProvider();
  List<double> get guardianAngles {
    final count = visualTier == CombatVfxTier.master ? 8 : 4;
    return List<double>.generate(
      count,
      (index) => index * 2 * math.pi / count,
      growable: false,
    );
  }

  PositionComponent? _registryVisual;
  bool _hasRegistrySprite = false;

  String get visualEffectId => 'jangseung_ward';
  bool get usesRegistryVisual => _registryVisual != null;
  bool get startsImageLoadOnMount => false;

  /// This aura is presentation-only and never resolves damage.
  bool get ownsDamageResolution => false;
  Vector2? get registryVisualLocalPosition => _registryVisual?.position.clone();
  Vector2? get registryVisualScale => _registryVisual?.scale.clone();

  void attachVisuals(CombatVisualFactory visualFactory) {
    if (_registryVisual != null) return;
    final visual = visualFactory.create(
      AttackVisualEvent.fromAttack(
        AttackInstance(
          spec: AttackSpec(
            id: visualEffectId,
            shape: AttackShape.circle,
            damage: 0,
            range: 0,
            angleRadians: 0,
            radius: 0,
            width: 0,
            windupSeconds: 0,
            activeSeconds: double.maxFinite,
            lingerSeconds: 0,
            knockback: 0,
            slowFraction: 0,
            traits: const {},
            presentation: AttackPresentation.normal,
          ),
          origin: Vector2.zero(),
          direction: Vector2(1, 0),
          sequenceIndex: 0,
        ),
      ),
    );
    _hasRegistrySprite = AttackVisualRegistry.byId(
      visualEffectId,
    ).layers.any((layer) => visualFactory.images.containsKey(layer.assetKey));
    _registryVisual = visual;
    add(visual);
  }

  static CombatVfxTier _normalTier() => CombatVfxTier.normal;

  @override
  void update(double dt) {
    super.update(dt);
    position.setFrom(positionProvider());
    final diameter = radiusProvider() * 2;
    size.setValues(diameter, diameter);
    _registryVisual
      ?..position = size / 2
      ..scale = Vector2.all(diameter / 128);
  }

  @override
  void render(Canvas canvas) {
    if (_hasRegistrySprite) return;
    final radius = size.x / 2;
    final center = Offset(radius, radius);
    final fill = Paint()..color = const Color(0x2239d98a);
    final ring = Paint()
      ..color = const Color(0xaa9bf6c7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(center, radius, ring);
    canvas.drawCircle(center, radius * .68, ring);
    for (var index = 0; index < 8; index += 1) {
      final angle = index * .7853981634;
      final point = Offset(
        center.dx + radius * .82 * math.cos(angle),
        center.dy + radius * .82 * math.sin(angle),
      );
      canvas.drawCircle(point, 3, ring);
    }
  }
}
