import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

@immutable
class WorldRuntimeConfig {
  WorldRuntimeConfig({
    required Vector2 worldSize,
    required this.chunkSize,
    required this.cameraZoom,
    required Vector2 cameraDeadZone,
    required this.cameraFollowSharpness,
    required this.zoneHysteresis,
    required this.maxActiveExperienceGems,
  }) : _worldSize = worldSize.clone(),
       _cameraDeadZone = cameraDeadZone.clone();

  static final standard = WorldRuntimeConfig(
    worldSize: Vector2(2048, 5120),
    chunkSize: 512,
    cameraZoom: .90,
    cameraDeadZone: Vector2(18, 24),
    cameraFollowSharpness: 8,
    zoneHysteresis: 64,
    maxActiveExperienceGems: 96,
  );

  final Vector2 _worldSize;
  final double chunkSize;
  final double cameraZoom;
  final Vector2 _cameraDeadZone;
  final double cameraFollowSharpness;
  final double zoneHysteresis;
  final int maxActiveExperienceGems;

  Vector2 get worldSize => _worldSize.clone();
  Vector2 get cameraDeadZone => _cameraDeadZone.clone();

  int get chunkColumns => (_worldSize.x / chunkSize).round();
  int get chunkRows => (_worldSize.y / chunkSize).round();
  Rect get worldBounds => Rect.fromLTWH(0, 0, _worldSize.x, _worldSize.y);
}
