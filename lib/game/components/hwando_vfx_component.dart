import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../combat/attack_visual_event.dart';
import '../content/attack_visual_registry.dart';
import 'talisman_presentation_component.dart';

class HwandoVfxComponent extends PositionComponent {
  HwandoVfxComponent({
    required this.event,
    required Map<String, Image> images,
    this.onExpired,
  }) : _visual = AttackVisualRegistry.byId(event.effectId),
       super(
         position: event.origin,
         anchor: Anchor.center,
         priority: AttackPresentationPriority.attack,
       ) {
    _layers =
        _visual.layers
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
  final void Function()? onExpired;
  final AttackVisualSpec _visual;
  late final List<_CachedVisualLayer> _layers;
  double _age = 0;
  bool _expired = false;

  double get facingAngle => math.atan2(event.direction.y, event.direction.x);

  double get progress {
    final duration = event.duration;
    if (!duration.isFinite || duration <= 0) return 1;
    final value = _age / duration;
    if (!value.isFinite) return value.isNegative ? 0 : 1;
    return value.clamp(0, 1).toDouble();
  }

  @override
  bool get isRemoving => super.isRemoving || (!isMounted && _expired);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (!_expired && _age >= event.duration) {
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
      if (_visual.rotateWithDirection) canvas.rotate(facingAngle);
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
