import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import 'combat/attack_spec.dart';
import 'combat/attack_visual_event.dart';
import 'content/attack_visual_registry.dart';
import 'content/combat_asset_preloader.dart';
import 'content/combat_visual_factory.dart';

enum VfxGalleryBackground { moonlit, plague, neutral }

@immutable
class VfxGalleryStatus {
  const VfxGalleryStatus({
    required this.selectedEffectId,
    required this.currentFrame,
    required this.activeProductionComponentCount,
    required this.directionIndex,
    required this.speed,
    required this.looping,
    required this.background,
    required this.showActorReference,
    required this.showHitbox,
    required this.showAnchor,
  });

  final String selectedEffectId;
  final int currentFrame;
  final int activeProductionComponentCount;
  final int directionIndex;
  final double speed;
  final bool looping;
  final VfxGalleryBackground background;
  final bool showActorReference;
  final bool showHitbox;
  final bool showAnchor;

  VfxGalleryStatus copyWith({
    String? selectedEffectId,
    int? currentFrame,
    int? activeProductionComponentCount,
    int? directionIndex,
    double? speed,
    bool? looping,
    VfxGalleryBackground? background,
    bool? showActorReference,
    bool? showHitbox,
    bool? showAnchor,
  }) => VfxGalleryStatus(
    selectedEffectId: selectedEffectId ?? this.selectedEffectId,
    currentFrame: currentFrame ?? this.currentFrame,
    activeProductionComponentCount:
        activeProductionComponentCount ?? this.activeProductionComponentCount,
    directionIndex: directionIndex ?? this.directionIndex,
    speed: speed ?? this.speed,
    looping: looping ?? this.looping,
    background: background ?? this.background,
    showActorReference: showActorReference ?? this.showActorReference,
    showHitbox: showHitbox ?? this.showHitbox,
    showAnchor: showAnchor ?? this.showAnchor,
  );
}

class VfxGalleryGame extends FlameGame {
  VfxGalleryGame({
    Map<String, Image>? visualImages,
    this.loadVisualAssets = true,
    this.visualAssetLoader,
  }) : _injectedImages = visualImages == null
           ? null
           : Map.unmodifiable(visualImages),
       status = ValueNotifier(
         VfxGalleryStatus(
           selectedEffectId: AttackVisualRegistry.effectIds.first,
           currentFrame: 0,
           activeProductionComponentCount: 0,
           directionIndex: 0,
           speed: 1,
           looping: true,
           background: VfxGalleryBackground.moonlit,
           showActorReference: false,
           showHitbox: false,
           showAnchor: false,
         ),
       );

  final Map<String, Image>? _injectedImages;
  final bool loadVisualAssets;
  final Future<Image> Function(String key)? visualAssetLoader;
  final ValueNotifier<VfxGalleryStatus> status;
  late final CombatVisualFactory factory;

  PositionComponent? get activeProductionComponent => _activeComponent;

  Map<String, Image> _images = const {};
  PositionComponent? _activeComponent;
  double _elapsed = 0;
  bool _ready = false;
  bool _disposed = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _images =
        _injectedImages ??
        (loadVisualAssets
            ? await CombatAssetPreloader.loadWith(
                AttackVisualRegistry.requiredAssetKeys,
                visualAssetLoader ?? images.load,
              )
            : const {});
    factory = CombatVisualFactory(images: _images);
    _ready = true;
    _restartComponent();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_ready) _restartComponent(publishStatus: false);
  }

  @override
  Color backgroundColor() => switch (status.value.background) {
    VfxGalleryBackground.moonlit => const Color(0xff1d3344),
    VfxGalleryBackground.plague => const Color(0xff3f4930),
    VfxGalleryBackground.neutral => const Color(0xffd8d2c2),
  };

  void selectEffect(String effectId) {
    if (!AttackVisualRegistry.effectIds.contains(effectId)) return;
    _setStatus(status.value.copyWith(selectedEffectId: effectId));
    _restartComponent();
  }

  void setDirectionIndex(int index) {
    if (index < 0 || index > 7 || index == status.value.directionIndex) return;
    _setStatus(status.value.copyWith(directionIndex: index));
    _restartComponent();
  }

  void setSpeed(double speed) {
    if (!speed.isFinite || !const [.25, .5, 1.0].contains(speed)) return;
    _setStatus(status.value.copyWith(speed: speed));
  }

  void setLooping(bool looping) =>
      _setStatus(status.value.copyWith(looping: looping));

  void setBackground(VfxGalleryBackground background) {
    if (background == status.value.background) return;
    _setStatus(status.value.copyWith(background: background));
    _restartComponent();
  }

  void setShowActorReference(bool value) =>
      _setStatus(status.value.copyWith(showActorReference: value));
  void setShowHitbox(bool value) =>
      _setStatus(status.value.copyWith(showHitbox: value));
  void setShowAnchor(bool value) =>
      _setStatus(status.value.copyWith(showAnchor: value));

  @override
  void update(double dt) {
    if (!dt.isFinite) return;
    final scaledDt = dt * status.value.speed;
    if (!scaledDt.isFinite || scaledDt < 0) return;
    super.update(scaledDt);
    final component = _activeComponent;
    if (component == null || component.isRemoving) {
      if (status.value.looping) {
        _restartComponent();
      } else {
        _setStatus(status.value.copyWith(activeProductionComponentCount: 0));
      }
      return;
    }
    _elapsed += scaledDt;
    _publishFrame();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final center = size / 2;
    final guidePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xccf7e7a9);
    if (status.value.showActorReference) {
      canvas.drawCircle(center.toOffset(), 20, guidePaint);
    }
    if (status.value.showHitbox) {
      canvas.drawRect(
        Rect.fromCenter(center: center.toOffset(), width: 128, height: 72),
        guidePaint,
      );
    }
    if (status.value.showAnchor) {
      canvas.drawLine(
        Offset(center.x - 10, center.y),
        Offset(center.x + 10, center.y),
        guidePaint,
      );
      canvas.drawLine(
        Offset(center.x, center.y - 10),
        Offset(center.x, center.y + 10),
        guidePaint,
      );
    }
  }

  void _restartComponent({bool publishStatus = true}) {
    if (!_ready) return;
    _activeComponent?.removeFromParent();
    _elapsed = 0;
    final component = factory.create(_eventForSelection());
    _activeComponent = component;
    add(component);
    if (publishStatus) {
      _setStatus(
        status.value.copyWith(
          currentFrame: 0,
          activeProductionComponentCount: _liveProductionComponentCount,
        ),
      );
    }
  }

  AttackVisualEvent _eventForSelection() {
    final spec = AttackVisualRegistry.byId(status.value.selectedEffectId);
    final geometry = _geometryFor(spec.category, spec.effectId);
    final angle = status.value.directionIndex * math.pi / 4;
    return AttackVisualEvent.fromAttack(
      AttackInstance(
        spec: AttackSpec(
          id: spec.effectId,
          shape: geometry.shape,
          damage: 0,
          range: geometry.range,
          angleRadians: geometry.angleRadians,
          radius: geometry.radius,
          width: geometry.width,
          windupSeconds: .18,
          activeSeconds: .52,
          lingerSeconds: .3,
          knockback: 0,
          slowFraction: 0,
          traits: const {},
          presentation: AttackPresentation.normal,
        ),
        origin: size / 2,
        direction: Vector2(math.cos(angle), math.sin(angle)),
        sequenceIndex: 0,
      ),
    );
  }

  _GalleryGeometry _geometryFor(
    CombatVisualCategory category,
    String effectId,
  ) {
    if (category == CombatVisualCategory.hwando) {
      return const _GalleryGeometry(
        AttackShape.sector,
        120,
        math.pi / 2,
        0,
        72,
      );
    }
    if (category == CombatVisualCategory.projectile) {
      return const _GalleryGeometry(AttackShape.line, 230, 0, 0, 28);
    }
    if (category == CombatVisualCategory.telegraph &&
        effectId.contains('radial')) {
      return const _GalleryGeometry(AttackShape.circle, 0, 0, 100, 0);
    }
    if (category == CombatVisualCategory.telegraph) {
      return const _GalleryGeometry(AttackShape.line, 280, 0, 0, 72);
    }
    if (category == CombatVisualCategory.status) {
      return const _GalleryGeometry(AttackShape.circle, 0, 0, 42, 0);
    }
    return const _GalleryGeometry(AttackShape.circle, 0, 0, 96, 0);
  }

  void _publishFrame() {
    final layer = AttackVisualRegistry.byId(
      status.value.selectedEffectId,
    ).layers.first;
    const duration = 1.0;
    final progress = (_elapsed / duration).clamp(0, 1).toDouble();
    final frame = (progress * layer.frameCount).floor().clamp(
      0,
      layer.frameCount - 1,
    );
    _setStatus(status.value.copyWith(currentFrame: frame));
  }

  void _setStatus(VfxGalleryStatus next) {
    if (_disposed) return;
    if (status.value != next) status.value = next;
  }

  int get _liveProductionComponentCount {
    final component = _activeComponent;
    return component != null &&
            !component.isRemoving &&
            children.contains(component)
        ? 1
        : 0;
  }

  @override
  void onDispose() {
    if (_disposed) return;
    _disposed = true;
    status.dispose();
    super.onDispose();
  }
}

class _GalleryGeometry {
  const _GalleryGeometry(
    this.shape,
    this.range,
    this.angleRadians,
    this.radius,
    this.width,
  );
  final AttackShape shape;
  final double range;
  final double angleRadians;
  final double radius;
  final double width;
}
