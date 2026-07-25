import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'combat/attack_geometry.dart';
import 'combat/attack_spec.dart';
import 'combat/attack_timeline.dart';
import 'combat/attack_visual_event.dart';
import 'combat/projectile_sweep_geometry.dart';
import 'components/combat_geometry_debug_component.dart';
import 'components/hwando_vfx_component.dart';
import 'components/projectile_component.dart';
import 'components/projectile_contact_vfx_component.dart';
import 'components/projectile_geometry_debug_component.dart';
import 'content/attack_visual_registry.dart';
import 'content/combat_asset_preloader.dart';
import 'content/combat_visual_factory.dart';
import 'content/projectile_presentation_spec.dart';
import 'content/weapon_definitions.dart';

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
    required this.showVisualBounds,
    required this.showHitbox,
    required this.showHurtbox,
    required this.showContactPoint,
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
  final bool showVisualBounds;
  final bool showHitbox;
  final bool showHurtbox;
  final bool showContactPoint;
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
    bool? showVisualBounds,
    bool? showHitbox,
    bool? showHurtbox,
    bool? showContactPoint,
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
    showVisualBounds: showVisualBounds ?? this.showVisualBounds,
    showHitbox: showHitbox ?? this.showHitbox,
    showHurtbox: showHurtbox ?? this.showHurtbox,
    showContactPoint: showContactPoint ?? this.showContactPoint,
    showAnchor: showAnchor ?? this.showAnchor,
  );
}

class VfxGalleryGame extends FlameGame {
  static const projectileEffectIds = <String>[
    gakgungShot,
    singijeonVolley,
    matchlockCannon,
    hawkSummon,
  ];

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
           showVisualBounds: false,
           showHitbox: false,
           showHurtbox: false,
           showContactPoint: false,
           showAnchor: false,
         ),
       );

  final Map<String, Image>? _injectedImages;
  final bool loadVisualAssets;
  final Future<Image> Function(String key)? visualAssetLoader;
  final ValueNotifier<VfxGalleryStatus> status;
  late final CombatVisualFactory factory;

  List<String> get effectIds => List.unmodifiable({
    ...AttackVisualRegistry.effectIds,
    ...projectileEffectIds,
  });
  PositionComponent? get activeProductionComponent => _activeComponent;

  Map<String, Image> _images = const {};
  PositionComponent? _activeComponent;
  PositionComponent? _debugComponent;
  AttackVisualEvent? _activeEvent;
  double _elapsed = 0;
  bool _ready = false;
  bool _disposed = false;
  VfxGalleryStatus? _pendingStatus;
  bool _statusPublishScheduled = false;
  Vector2? _lastGallerySize;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _images =
        _injectedImages ??
        (loadVisualAssets
            ? await CombatAssetPreloader.loadWith({
                ...AttackVisualRegistry.requiredAssetKeys,
                ...ProjectilePresentationSpecs.requiredAssetKeys,
                ProjectileContactVfxComponent.assetKey,
              }, visualAssetLoader ?? images.load)
            : const {});
    factory = CombatVisualFactory(
      images: _images,
      allowMissingHwandoImages: !loadVisualAssets && _injectedImages == null,
    );
    _ready = true;
    _restartComponent();
  }

  @override
  void onGameResize(Vector2 size) {
    final sizeChanged = _lastGallerySize != size;
    _lastGallerySize = size.clone();
    super.onGameResize(size);
    if (!_ready || !sizeChanged) return;
    _restartComponent(publishStatus: false);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      processLifecycleEvents();
      _publishRestartStatus();
    });
  }

  @override
  Color backgroundColor() => switch (status.value.background) {
    VfxGalleryBackground.moonlit => const Color(0xff1d3344),
    VfxGalleryBackground.plague => const Color(0xff3f4930),
    VfxGalleryBackground.neutral => const Color(0xffd8d2c2),
  };

  void selectEffect(String effectId) {
    if (!effectIds.contains(effectId)) return;
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

  void step() {
    setLooping(false);
    final selectedId = status.value.selectedEffectId;
    final projectile = ProjectilePresentationSpecs.byWeapon[selectedId];
    final frames =
        projectile?.frameCount ??
        AttackVisualRegistry.byId(
          selectedId,
        ).layers.fold<int>(0, (total, layer) => total + layer.frameCount);
    final duration = projectile == null
        ? (_activeEvent?.duration ?? 1)
        : projectile.frameSeconds * projectile.frameCount;
    final stepSeconds = duration.isFinite && duration > 0
        ? duration / frames
        : 1 / frames;
    update(stepSeconds / status.value.speed);
  }

  void setBackground(VfxGalleryBackground background) {
    if (background == status.value.background) return;
    _setStatus(status.value.copyWith(background: background));
    _restartComponent();
  }

  void setShowActorReference(bool value) =>
      _setGeometryStatus(status.value.copyWith(showActorReference: value));
  void setShowVisualBounds(bool value) =>
      _setGeometryStatus(status.value.copyWith(showVisualBounds: value));
  void setShowHitbox(bool value) =>
      _setGeometryStatus(status.value.copyWith(showHitbox: value));
  void setShowHurtbox(bool value) =>
      _setGeometryStatus(status.value.copyWith(showHurtbox: value));
  void setShowContactPoint(bool value) =>
      _setGeometryStatus(status.value.copyWith(showContactPoint: value));
  void setShowAnchor(bool value) =>
      _setGeometryStatus(status.value.copyWith(showAnchor: value));

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
    _updateDebugTimeline();
    _publishFrame();
  }

  void _restartComponent({bool publishStatus = true}) {
    if (!_ready) return;
    _activeComponent?.removeFromParent();
    _debugComponent?.removeFromParent();
    _debugComponent = null;
    _elapsed = 0;
    final weaponId = status.value.selectedEffectId;
    final projectileSpec = ProjectilePresentationSpecs.byWeapon[weaponId];
    late final PositionComponent component;
    if (projectileSpec != null) {
      _activeEvent = null;
      component = ProjectileComponent(
        weaponId: weaponId,
        damage: 0,
        position: size / 2,
        velocity: _selectedDirection * 36,
        lifetime: 2.2,
        visualImage: _images[projectileSpec.assetKey],
      );
    } else {
      final event = _eventForSelection();
      _activeEvent = event;
      component = factory.create(event);
    }
    _activeComponent = component;
    add(component);
    _syncDebugComponent();
    if (publishStatus) {
      _publishRestartStatus();
    }
  }

  void _setGeometryStatus(VfxGalleryStatus next) {
    _setStatus(next);
    _syncDebugComponent();
  }

  void _syncDebugComponent() {
    if (!kDebugMode) return;
    final value = status.value;
    final anyVisible =
        value.showActorReference ||
        value.showVisualBounds ||
        value.showHitbox ||
        value.showHurtbox ||
        value.showContactPoint ||
        value.showAnchor;
    if (!anyVisible) {
      _debugComponent?.removeFromParent();
      _debugComponent = null;
      return;
    }
    final projectileSpec =
        ProjectilePresentationSpecs.byWeapon[value.selectedEffectId];
    if (projectileSpec != null) {
      _syncProjectileDebug(projectileSpec, value);
      return;
    }
    final event = _activeEvent;
    final contract = event?.presentationContract;
    if (contract == null) {
      _debugComponent?.removeFromParent();
      _debugComponent = null;
      return;
    }
    var debug = _debugComponent;
    if (debug is! CombatGeometryDebugComponent || debug.contract != contract) {
      _debugComponent?.removeFromParent();
      final target =
          contract.visualSector.origin +
          contract.visualSector.direction * (contract.hitSector.radius * .75);
      final contact = AttackGeometry.sectorContact(
        contract.hitSector,
        target,
        12,
      );
      if (contact == null) return;
      debug = CombatGeometryDebugComponent(
        contract: contract,
        targetCenter: target,
        targetRadius: 12,
        contact: contact,
      );
      _debugComponent = debug;
      add(debug);
    }
    debug
      ..showVisualBounds = value.showVisualBounds
      ..showHitbox = value.showHitbox
      ..showHurtbox = value.showHurtbox || value.showActorReference
      ..showContactPoint = value.showContactPoint || value.showAnchor;
    _updateDebugTimeline();
  }

  void _updateDebugTimeline() {
    final debug = _debugComponent;
    final component = _activeComponent;
    if (debug is! CombatGeometryDebugComponent ||
        component is! HwandoVfxComponent) {
      return;
    }
    debug.phase = component.phase;
    final timing = debug.contract.timing;
    final end = switch (component.phase) {
      AttackPhase.windup => timing.windupSeconds,
      AttackPhase.active => timing.activeEndsAt,
      AttackPhase.recovery => timing.totalSeconds,
      AttackPhase.complete => timing.totalSeconds,
    };
    debug.remainingMilliseconds = math.max(
      0,
      ((end - _elapsed) * 1000).round(),
    );
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

  Vector2 get _selectedDirection {
    final angle = status.value.directionIndex * math.pi / 4;
    return Vector2(math.cos(angle), math.sin(angle));
  }

  void _syncProjectileDebug(
    ProjectilePresentationSpec spec,
    VfxGalleryStatus value,
  ) {
    final direction = _selectedDirection;
    final center = size / 2;
    final previous = center - direction * 90;
    final current = center + direction * 30;
    final hurtCenter = center + direction * 10;
    const hurtRadius = 13.0;
    final contact = ProjectileSweepGeometry.firstContact(
      previousCenter: previous,
      currentCenter: current,
      direction: direction,
      hitBodySize: spec.hitBodySize,
      hurtCenter: hurtCenter,
      hurtRadius: hurtRadius,
    );
    if (contact == null) return;
    _debugComponent?.removeFromParent();
    final debug =
        ProjectileGeometryDebugComponent(
            weaponId: spec.weaponId,
            previousCenter: previous,
            currentCenter: current,
            direction: direction,
            visualBodySize: spec.bodySize,
            hitBodySize: spec.hitBodySize,
            hurtCenter: hurtCenter,
            hurtRadius: hurtRadius,
            contact: contact,
            autoExpire: false,
          )
          ..showVisualBody = value.showVisualBounds
          ..showHitBody = value.showHitbox
          ..showSweep = value.showAnchor
          ..showHurtbox = value.showHurtbox || value.showActorReference
          ..showContact = value.showContactPoint
          ..showWeaponId = true;
    _debugComponent = debug;
    add(debug);
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
    final selectedId = status.value.selectedEffectId;
    final projectile = ProjectilePresentationSpecs.byWeapon[selectedId];
    final frameCount =
        projectile?.frameCount ??
        AttackVisualRegistry.byId(
          selectedId,
        ).layers.fold<int>(0, (total, layer) => total + layer.frameCount);
    final eventDuration = projectile == null
        ? (_activeEvent?.duration ?? 1)
        : projectile.frameSeconds * projectile.frameCount;
    final duration = eventDuration.isFinite && eventDuration > 0
        ? eventDuration
        : 1.0;
    final progress = (_elapsed / duration).clamp(0, 1).toDouble();
    final frame = (progress * frameCount).floor().clamp(0, frameCount - 1);
    _setStatus(status.value.copyWith(currentFrame: frame));
  }

  void _setStatus(VfxGalleryStatus next) {
    if (_disposed) return;
    if (status.value == next) return;
    SchedulerBinding binding;
    try {
      binding = SchedulerBinding.instance;
    } on FlutterError {
      status.value = next;
      return;
    }
    final phase = binding.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      status.value = next;
      return;
    }
    _pendingStatus = next;
    if (_statusPublishScheduled) return;
    _statusPublishScheduled = true;
    binding.addPostFrameCallback((_) {
      _statusPublishScheduled = false;
      if (_disposed) return;
      final pending = _pendingStatus;
      _pendingStatus = null;
      if (pending != null && status.value != pending) {
        status.value = pending;
      }
    });
  }

  int get _liveProductionComponentCount {
    final component = _activeComponent;
    return component != null &&
            !component.isRemoving &&
            children.contains(component)
        ? 1
        : 0;
  }

  void _publishRestartStatus() {
    _setStatus(
      status.value.copyWith(
        currentFrame: 0,
        activeProductionComponentCount: _liveProductionComponentCount,
      ),
    );
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
