import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../combat/attack_visual_event.dart';
import '../content/attack_visual_registry.dart';
import 'talisman_presentation_component.dart';

class RegistryVfxComponent extends PositionComponent {
  RegistryVfxComponent({
    required AttackVisualEvent event,
    required AttackVisualSpec spec,
    required Map<String, Image> images,
    required CombatVisualCategory expectedCategory,
    this.onExpired,
  }) : event = _validatedEvent(event, spec, expectedCategory),
       spec = spec,
       super(
         position: event.origin,
         anchor: Anchor.center,
         priority: AttackPresentationPriority.attack,
       ) {
    _layers =
        spec.layers
            .map(
              (layer) => _CachedVisualLayer(
                layer,
                images[layer.assetKey] == null
                    ? const []
                    : List<Sprite>.generate(
                        layer.frameCount,
                        (frame) => Sprite(
                          images[layer.assetKey]!,
                          srcPosition: Vector2(frame * layer.frameSize, 0),
                          srcSize: Vector2.all(layer.frameSize),
                        ),
                      ),
              ),
            )
            .toList(growable: false)
          ..sort(
            (left, right) =>
                left.spec.priorityOffset.compareTo(right.spec.priorityOffset),
          );
  }

  final AttackVisualEvent event;
  final AttackVisualSpec spec;
  final void Function()? onExpired;
  late final List<_CachedVisualLayer> _layers;
  double _age = 0;
  bool _expired = false;

  static AttackVisualEvent _validatedEvent(
    AttackVisualEvent event,
    AttackVisualSpec spec,
    CombatVisualCategory expectedCategory,
  ) {
    if (event.effectId != spec.effectId) {
      throw ArgumentError.value(
        event.effectId,
        'event.effectId',
        'must match spec.effectId (${spec.effectId})',
      );
    }
    if (spec.category != expectedCategory) {
      throw ArgumentError.value(
        spec.category,
        'spec.category',
        'must be ${expectedCategory.name}',
      );
    }
    return event;
  }

  double get facingAngle => math.atan2(event.direction.y, event.direction.x);

  bool get _hasTerminalDuration =>
      !event.duration.isFinite || event.duration <= 0;

  double get progress {
    final duration = event.duration;
    if (_hasTerminalDuration) return 1;
    final value = _age / duration;
    if (!value.isFinite) return value.isNegative ? 0 : 1;
    return value.clamp(0, 1).toDouble();
  }

  @override
  bool get isRemoving => super.isRemoving || (!isMounted && _expired);

  @override
  void update(double dt) {
    if (!dt.isFinite) return;
    super.update(dt);
    _age += dt;
    if (!_expired && (_hasTerminalDuration || _age >= event.duration)) {
      _expired = true;
      onExpired?.call();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final progress = this.progress;
    for (final layer in _layers) {
      if (!_isActive(layer.spec, progress) || layer.sprites.isEmpty) continue;
      final localProgress = _localProgress(layer.spec, progress);
      final frame = (localProgress * layer.sprites.length).floor().clamp(
        0,
        layer.sprites.length - 1,
      );
      final frameSize = layer.spec.frameSize;
      canvas.save();
      if (spec.rotateWithDirection) canvas.rotate(facingAngle);
      layer.sprites[frame].render(
        canvas,
        position: Vector2.all(-frameSize / 2),
        size: Vector2.all(frameSize),
      );
      canvas.restore();
    }
  }

  bool _isActive(AttackVisualLayerSpec layer, double progress) {
    if (progress < layer.startFraction || progress > layer.endFraction) {
      return false;
    }
    return layer.id != 'impact' || _age >= event.impactAt;
  }

  double _localProgress(AttackVisualLayerSpec layer, double progress) {
    final span = layer.endFraction - layer.startFraction;
    if (span <= 0) return 1;
    return ((progress - layer.startFraction) / span).clamp(0, 1).toDouble();
  }
}

class _CachedVisualLayer {
  const _CachedVisualLayer(this.spec, this.sprites);

  final AttackVisualLayerSpec spec;
  final List<Sprite> sprites;
}
