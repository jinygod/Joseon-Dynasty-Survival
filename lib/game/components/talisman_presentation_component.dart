import 'dart:ui';

import 'package:flame/components.dart';

import '../combat/attack_spec.dart';
import '../combat/attack_visual_event.dart';
import '../content/combat_visual_factory.dart';
import '../content/attack_visual_registry.dart';
import '../systems/talisman_executor.dart';

abstract final class AttackPresentationPriority {
  static const attack = 89;
  static const impact = 90;
  static const attachment = 92;
  static const warning = 120;
}

class TalismanAttachmentComponent extends PositionComponent {
  TalismanAttachmentComponent({
    required this.seal,
    CombatVisualFactory? visualFactory,
  }) : super(
         size: Vector2(12, 16),
         anchor: Anchor.center,
         priority: AttackPresentationPriority.attachment,
       ) {
    if (visualFactory != null) attachVisuals(visualFactory);
  }

  final AttachedTalisman seal;
  bool _usesRegistryVisual = false;
  bool _hasRegistrySprite = false;
  PositionComponent? _registryVisual;

  String get visualEffectId => 'talisman_attachment';
  bool get usesRegistryVisual => _usesRegistryVisual;
  bool get startsImageLoadOnMount => false;

  /// Only the presentation child is described here; it never resolves damage.
  bool get ownsDamageResolution => false;
  Vector2? get registryVisualLocalPosition => _registryVisual?.position.clone();
  Vector2? get registryVisualScale => _registryVisual?.scale.clone();

  void attachVisuals(CombatVisualFactory visualFactory) {
    if (_usesRegistryVisual) return;
    _usesRegistryVisual = true;
    _hasRegistrySprite = AttackVisualRegistry.byId(
      visualEffectId,
    ).layers.any((layer) => visualFactory.images.containsKey(layer.assetKey));
    final visual =
        visualFactory.create(
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
          )
          ..position = size / 2
          ..scale = Vector2.all(size.x / 128);
    _registryVisual = visual;
    add(visual);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final target = seal.target;
    position.setValues(
      target.position.x,
      target.position.y - target.size.y / 2 - 7,
    );
  }

  @override
  void render(Canvas canvas) {
    if (_hasRegistrySprite) return;
    final paper = RRect.fromRectAndRadius(
      Offset.zero & Size(size.x, size.y),
      const Radius.circular(1),
    );
    canvas.drawRRect(paper, Paint()..color = const Color(0xfffff4c2));
    canvas.drawRRect(
      paper,
      Paint()
        ..color = const Color(0xff8f1d2c)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final ink = Paint()
      ..color = seal.isCritical
          ? const Color(0xffff8c42)
          : const Color(0xffb4232f)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(Offset(size.x / 2, 3), Offset(size.x / 2, 13), ink)
      ..drawLine(const Offset(3, 6), Offset(size.x - 3, 6), ink)
      ..drawLine(const Offset(3, 10), Offset(size.x - 3, 10), ink);
  }
}

class TalismanTransferCueComponent extends PositionComponent {
  TalismanTransferCueComponent({
    required TalismanTransferCue cue,
    this.onExpired,
    CombatVisualFactory? visualFactory,
  }) : _source = cue.source,
       _target = cue.target,
       super(
         position: cue.source,
         priority: AttackPresentationPriority.attachment,
       ) {
    if (visualFactory != null) attachVisuals(visualFactory);
  }

  static const _lifetime = .2;

  final Vector2 _source;
  final Vector2 _target;
  final void Function()? onExpired;
  double _age = 0;
  bool _expired = false;
  bool _usesRegistryVisual = false;
  bool _hasRegistrySprite = false;
  PositionComponent? _registryVisual;

  Vector2 get source => _source.clone();
  Vector2 get target => _target.clone();
  double get lifetime => _lifetime;
  String get visualEffectId => 'talisman_transfer';
  bool get usesRegistryVisual => _usesRegistryVisual;
  bool get startsImageLoadOnMount => false;

  /// Only the presentation child is described here; it never resolves damage.
  bool get ownsDamageResolution => false;
  Vector2? get registryVisualLocalPosition => _registryVisual?.position.clone();
  Vector2? get registryVisualScale => _registryVisual?.scale.clone();

  void attachVisuals(CombatVisualFactory visualFactory) {
    if (_usesRegistryVisual) return;
    _usesRegistryVisual = true;
    _hasRegistrySprite = AttackVisualRegistry.byId(
      visualEffectId,
    ).layers.any((layer) => visualFactory.images.containsKey(layer.assetKey));
    final delta = _target - _source;
    final visual = visualFactory.create(
      AttackVisualEvent.fromAttack(
        AttackInstance(
          spec: AttackSpec(
            id: visualEffectId,
            shape: AttackShape.line,
            damage: 0,
            range: delta.length,
            angleRadians: 0,
            radius: 0,
            width: 0,
            windupSeconds: 0,
            activeSeconds: _lifetime,
            lingerSeconds: 0,
            knockback: 0,
            slowFraction: 0,
            traits: const {},
            presentation: AttackPresentation.normal,
          ),
          origin: Vector2.zero(),
          direction: delta,
          sequenceIndex: 0,
        ),
      ),
    )..scale = Vector2.all(28 / 128);
    _registryVisual = visual;
    add(visual);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    final progress = (_age / _lifetime).clamp(0, 1).toDouble();
    _registryVisual?.position = (_target - _source) * progress;
    if (!_expired && _age >= _lifetime) {
      _expired = true;
      onExpired?.call();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (_hasRegistrySprite) return;
    final progress = (_age / _lifetime).clamp(0, 1).toDouble();
    final delta = _target - _source;
    canvas.drawLine(
      Offset.zero,
      Offset(delta.x, delta.y),
      Paint()
        ..color = const Color(0xffffd166).withValues(alpha: 1 - progress)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(delta.x, delta.y),
      3 + progress * 2,
      Paint()
        ..color = const Color(0xffef4444).withValues(alpha: 1 - progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}
