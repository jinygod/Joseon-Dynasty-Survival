import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../combat/attack_presentation_contract.dart';
import '../combat/attack_timeline.dart';
import '../combat/attack_visual_event.dart';
import '../content/attack_visual_registry.dart';
import 'talisman_presentation_component.dart';

class HwandoVfxComponent extends PositionComponent {
  HwandoVfxComponent({
    required this.event,
    required Map<String, Image> images,
    this.allowMissingImages = false,
    this.onExpired,
  }) : _visual = AttackVisualRegistry.byId(event.effectId),
       contract = event.presentationContract,
       super(
         position: event.origin,
         size: Vector2.all(
           event.presentationContract == null
               ? 128
               : event.presentationContract!.visualSector.radius * 2,
         ),
         anchor: Anchor.center,
         angle: _facingAngleFor(event),
         priority: AttackPresentationPriority.attack,
       ) {
    _layers =
        _visual.layers
            .map(
              (layer) => _CachedVisualLayer(
                layer,
                _spritesFor(
                  layer,
                  images,
                  allowMissingImages: allowMissingImages,
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
  final AttackPresentationContract? contract;
  final bool allowMissingImages;
  final void Function()? onExpired;
  final AttackVisualSpec _visual;
  late final List<_CachedVisualLayer> _layers;
  double _age = 0;
  bool _expired = false;

  AttackTiming get _timing =>
      contract?.timing ??
      AttackTiming(
        windupSeconds: _safeDuration(event.windupSeconds),
        activeSeconds: _safeDuration(event.activeSeconds),
        recoverySeconds: _safeDuration(event.recoverySeconds),
      );

  double get visualRadius => contract?.visualSector.radius ?? 64;

  double get facingAngle {
    final direction = contract?.visualSector.direction ?? event.direction;
    return math.atan2(direction.y, direction.x);
  }

  AttackPhase get phase {
    final timing = _timing;
    if (_age >= timing.totalSeconds) return AttackPhase.complete;
    if (_age >= timing.activeEndsAt) return AttackPhase.recovery;
    if (_age >= timing.windupSeconds) return AttackPhase.active;
    return AttackPhase.windup;
  }

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
    super.update(dt);
    if (dt.isFinite && dt > 0) _age += dt;
    if (!_expired && (_hasTerminalDuration || _age >= event.duration)) {
      _expired = true;
      onExpired?.call();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final currentPhase = phase;
    if (currentPhase == AttackPhase.complete) return;
    for (final layer in _layers) {
      final isActive = contract == null
          ? _isLegacyLayerActive(layer.spec)
          : _isPhaseLayer(layer.spec, currentPhase);
      if (!isActive || layer.sprites.isEmpty) {
        continue;
      }
      final localProgress = contract == null
          ? _legacyLayerProgress(layer.spec)
          : _phaseProgress(currentPhase);
      final frame = (localProgress * layer.sprites.length).floor().clamp(
        0,
        layer.sprites.length - 1,
      );
      layer.sprites[frame].render(
        canvas,
        position: Vector2.zero(),
        size: Vector2.all(visualRadius * 2),
      );
    }
  }

  bool _isPhaseLayer(AttackVisualLayerSpec layer, AttackPhase currentPhase) {
    return switch (currentPhase) {
      AttackPhase.windup => layer.id == 'windup',
      AttackPhase.active => layer.id == 'strike',
      AttackPhase.recovery => layer.id == 'recovery',
      AttackPhase.complete => false,
    };
  }

  double _phaseProgress(AttackPhase currentPhase) {
    final timing = _timing;
    final (start, duration) = switch (currentPhase) {
      AttackPhase.windup => (0.0, timing.windupSeconds),
      AttackPhase.active => (timing.windupSeconds, timing.activeSeconds),
      AttackPhase.recovery => (timing.activeEndsAt, timing.recoverySeconds),
      AttackPhase.complete => (timing.totalSeconds, 0.0),
    };
    if (duration <= 0) return 1;
    return ((_age - start) / duration).clamp(0, 1).toDouble();
  }

  bool _isLegacyLayerActive(AttackVisualLayerSpec layer) {
    final value = progress;
    if (value < layer.startFraction || value > layer.endFraction) return false;
    return layer.id != 'impact' || _age >= event.impactAt;
  }

  double _legacyLayerProgress(AttackVisualLayerSpec layer) {
    final span = layer.endFraction - layer.startFraction;
    if (span <= 0) return 1;
    return ((progress - layer.startFraction) / span).clamp(0, 1).toDouble();
  }
}

double _safeDuration(double value) => value.isFinite && value >= 0 ? value : 0;

double _facingAngleFor(AttackVisualEvent event) {
  if (!AttackVisualRegistry.byId(event.effectId).rotateWithDirection) return 0;
  final direction =
      event.presentationContract?.visualSector.direction ?? event.direction;
  return math.atan2(direction.y, direction.x);
}

List<Sprite> _spritesFor(
  AttackVisualLayerSpec layer,
  Map<String, Image> images, {
  required bool allowMissingImages,
}) {
  final image = images[layer.assetKey];
  if (image == null) {
    if (allowMissingImages) return const [];
    throw StateError('Missing preloaded Hwando image: ${layer.assetKey}');
  }
  return List<Sprite>.generate(
    layer.frameCount,
    (frame) => Sprite(
      image,
      srcPosition: Vector2(frame * layer.frameSize, 0),
      srcSize: Vector2.all(layer.frameSize),
    ),
  );
}

class _CachedVisualLayer {
  const _CachedVisualLayer(this.spec, this.sprites);

  final AttackVisualLayerSpec spec;
  final List<Sprite> sprites;
}
