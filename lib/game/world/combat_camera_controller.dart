import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'world_runtime_config.dart';

/// Keeps a combat camera centered on its target without exposing empty world.
class CombatCameraController {
  CombatCameraController({
    required this.camera,
    required this.config,
    required this.targetPosition,
    required this.shakeOffset,
    Vector2? initialPosition,
  }) :
       _testVisibleSize = null,
       _basePosition = (initialPosition ?? Vector2.zero()).clone();

  CombatCameraController.test({
    required this.config,
    required Vector2 initialPosition,
    Vector2? visibleSize,
  }) : camera = null,
       targetPosition = null,
       shakeOffset = null,
       _testVisibleSize = (visibleSize ?? Vector2.zero()).clone(),
       _basePosition = initialPosition.clone();

  final CameraComponent? camera;
  final WorldRuntimeConfig config;
  final Vector2 Function()? targetPosition;
  final Vector2 Function()? shakeOffset;
  final Vector2? _testVisibleSize;
  final Vector2 _basePosition;

  Vector2 get basePosition => _basePosition.clone();

  void snapTo(Vector2 position) {
    _basePosition.setFrom(_clamp(position, _visibleSize));
    _writeViewfinder();
  }

  void update(double dt) {
    final target = targetPosition?.call();
    if (target != null) follow(target, dt: dt);
    _writeViewfinder();
  }

  void follow(Vector2 target, {required double dt}) {
    if (!_isFiniteVector(target)) return;
    final safeDt = dt.isFinite && dt > 0 ? dt.clamp(0, .05).toDouble() : 0.0;
    final desired = _desiredAfterDeadZone(target);
    final alpha = 1 - math.exp(-config.cameraFollowSharpness * safeDt);
    _basePosition.add((desired - _basePosition) * alpha);
    _basePosition.setFrom(_clamp(_basePosition, _visibleSize));
  }

  Vector2 _desiredAfterDeadZone(Vector2 target) {
    final halfDeadZone = config.cameraDeadZone / 2;
    final desired = _basePosition.clone();
    final delta = target - _basePosition;
    if (delta.x > halfDeadZone.x) desired.x = target.x - halfDeadZone.x;
    if (delta.x < -halfDeadZone.x) desired.x = target.x + halfDeadZone.x;
    if (delta.y > halfDeadZone.y) desired.y = target.y - halfDeadZone.y;
    if (delta.y < -halfDeadZone.y) desired.y = target.y + halfDeadZone.y;
    return desired;
  }

  Vector2 get _visibleSize {
    final camera = this.camera;
    if (camera == null) return _testVisibleSize ?? config.worldSize;
    final zoom = camera.viewfinder.zoom;
    final viewport = camera.viewport.virtualSize;
    if (!zoom.isFinite || zoom <= 0 || !_isFiniteVector(viewport)) {
      return config.worldSize;
    }
    return viewport / zoom;
  }

  void _writeViewfinder() {
    final camera = this.camera;
    if (camera == null) return;
    final visibleSize = _visibleSize;
    final base = _clamp(_basePosition, visibleSize);
    _basePosition.setFrom(base);
    final shake = shakeOffset?.call() ?? Vector2.zero();
    final finalCenter = _isFiniteVector(shake)
        ? _clamp(base + shake, visibleSize)
        : base;
    camera.viewfinder.position = finalCenter;
  }

  Vector2 _clamp(Vector2 desired, Vector2 visibleSize) => clampCenter(
    desired: desired,
    visibleSize: visibleSize,
    worldBounds: config.worldBounds,
  );

  static Vector2 clampCenter({
    required Vector2 desired,
    required Vector2 visibleSize,
    required Rect worldBounds,
  }) {
    if (!_isFiniteVector(desired) ||
        !_isFiniteVector(visibleSize) ||
        !worldBounds.left.isFinite ||
        !worldBounds.top.isFinite ||
        !worldBounds.width.isFinite ||
        !worldBounds.height.isFinite ||
        worldBounds.width < 0 ||
        worldBounds.height < 0 ||
        visibleSize.x < 0 ||
        visibleSize.y < 0) {
      return Vector2(worldBounds.center.dx.isFinite ? worldBounds.center.dx : 0,
          worldBounds.center.dy.isFinite ? worldBounds.center.dy : 0);
    }
    return Vector2(
      _clampAxis(desired.x, visibleSize.x, worldBounds.left, worldBounds.width),
      _clampAxis(desired.y, visibleSize.y, worldBounds.top, worldBounds.height),
    );
  }

  static double _clampAxis(
    double desired,
    double visible,
    double worldStart,
    double worldLength,
  ) {
    final worldCenter = worldStart + worldLength / 2;
    if (visible >= worldLength) return worldCenter;
    final halfVisible = visible / 2;
    return desired.clamp(
      worldStart + halfVisible,
      worldStart + worldLength - halfVisible,
    ).toDouble();
  }

  static bool _isFiniteVector(Vector2 value) =>
      value.x.isFinite && value.y.isFinite;
}
