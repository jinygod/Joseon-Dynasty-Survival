import 'package:flame/components.dart';

enum AttackVisualStatus { ready, generatedReview, temporary, missing }

enum CombatVisualCategory { hwando, projectile, area, telegraph, status }

class AttackVisualLayerSpec {
  const AttackVisualLayerSpec({
    required this.id,
    required this.assetKey,
    required this.frameSize,
    required this.frameCount,
    required this.anchor,
    required this.priorityOffset,
    required this.startFraction,
    required this.endFraction,
  });

  final String id;
  final String assetKey;
  final double frameSize;
  final int frameCount;
  final Anchor anchor;
  final int priorityOffset;
  final double startFraction;
  final double endFraction;
}

class AttackVisualSpec {
  const AttackVisualSpec({
    required this.effectId,
    required this.category,
    required this.status,
    required this.layers,
    required this.rotateWithDirection,
  });

  final String effectId;
  final CombatVisualCategory category;
  final AttackVisualStatus status;
  final List<AttackVisualLayerSpec> layers;
  final bool rotateWithDirection;
}

class MissingAttackVisualException implements Exception {
  const MissingAttackVisualException(this.effectId);

  final String effectId;

  @override
  String toString() => 'Missing attack visual for $effectId';
}

abstract final class AttackVisualRegistry {
  static const _slashLayers = <AttackVisualLayerSpec>[
    AttackVisualLayerSpec(
      id: 'trail',
      assetKey: 'vfx/hwando_slash_trail_128.png',
      frameSize: 128,
      frameCount: 6,
      anchor: Anchor.center,
      priorityOffset: 0,
      startFraction: 0,
      endFraction: .75,
    ),
    AttackVisualLayerSpec(
      id: 'impact',
      assetKey: 'vfx/hwando_slash_impact_128.png',
      frameSize: 128,
      frameCount: 5,
      anchor: Anchor.center,
      priorityOffset: 1,
      startFraction: .2,
      endFraction: 1,
    ),
  ];

  static const _bladeWaveLayers = <AttackVisualLayerSpec>[
    AttackVisualLayerSpec(
      id: 'trail',
      assetKey: 'vfx/hwando_blade_wave_trail_128.png',
      frameSize: 128,
      frameCount: 6,
      anchor: Anchor.center,
      priorityOffset: 0,
      startFraction: 0,
      endFraction: .8,
    ),
    AttackVisualLayerSpec(
      id: 'impact',
      assetKey: 'vfx/hwando_blade_wave_impact_128.png',
      frameSize: 128,
      frameCount: 5,
      anchor: Anchor.center,
      priorityOffset: 1,
      startFraction: .25,
      endFraction: 1,
    ),
  ];

  static const _masterCircleLayers = <AttackVisualLayerSpec>[
    AttackVisualLayerSpec(
      id: 'trail',
      assetKey: 'vfx/hwando_master_circle_trail_128.png',
      frameSize: 128,
      frameCount: 8,
      anchor: Anchor.center,
      priorityOffset: 0,
      startFraction: 0,
      endFraction: 1,
    ),
    AttackVisualLayerSpec(
      id: 'impact',
      assetKey: 'vfx/hwando_master_circle_impact_128.png',
      frameSize: 128,
      frameCount: 6,
      anchor: Anchor.center,
      priorityOffset: 1,
      startFraction: .15,
      endFraction: 1,
    ),
  ];

  static const _masterFinisherLayers = <AttackVisualLayerSpec>[
    AttackVisualLayerSpec(
      id: 'trail',
      assetKey: 'vfx/hwando_master_finisher_trail_128.png',
      frameSize: 128,
      frameCount: 8,
      anchor: Anchor.center,
      priorityOffset: 0,
      startFraction: 0,
      endFraction: .8,
    ),
    AttackVisualLayerSpec(
      id: 'impact',
      assetKey: 'vfx/hwando_master_finisher_impact_128.png',
      frameSize: 128,
      frameCount: 6,
      anchor: Anchor.center,
      priorityOffset: 1,
      startFraction: .2,
      endFraction: 1,
    ),
  ];

  static const _specs = <String, AttackVisualSpec>{
    'hwando_slash': AttackVisualSpec(
      effectId: 'hwando_slash',
      category: CombatVisualCategory.hwando,
      status: AttackVisualStatus.generatedReview,
      layers: _slashLayers,
      rotateWithDirection: true,
    ),
    'hwando_slash_left': AttackVisualSpec(
      effectId: 'hwando_slash_left',
      category: CombatVisualCategory.hwando,
      status: AttackVisualStatus.generatedReview,
      layers: _slashLayers,
      rotateWithDirection: true,
    ),
    'hwando_slash_right': AttackVisualSpec(
      effectId: 'hwando_slash_right',
      category: CombatVisualCategory.hwando,
      status: AttackVisualStatus.generatedReview,
      layers: _slashLayers,
      rotateWithDirection: true,
    ),
    'hwando_blade_wave': AttackVisualSpec(
      effectId: 'hwando_blade_wave',
      category: CombatVisualCategory.hwando,
      status: AttackVisualStatus.generatedReview,
      layers: _bladeWaveLayers,
      rotateWithDirection: true,
    ),
    'hwando_master_opener': AttackVisualSpec(
      effectId: 'hwando_master_opener',
      category: CombatVisualCategory.hwando,
      status: AttackVisualStatus.generatedReview,
      layers: _slashLayers,
      rotateWithDirection: true,
    ),
    'hwando_master_left': AttackVisualSpec(
      effectId: 'hwando_master_left',
      category: CombatVisualCategory.hwando,
      status: AttackVisualStatus.generatedReview,
      layers: _slashLayers,
      rotateWithDirection: true,
    ),
    'hwando_master_right': AttackVisualSpec(
      effectId: 'hwando_master_right',
      category: CombatVisualCategory.hwando,
      status: AttackVisualStatus.generatedReview,
      layers: _slashLayers,
      rotateWithDirection: true,
    ),
    'hwando_master_circle': AttackVisualSpec(
      effectId: 'hwando_master_circle',
      category: CombatVisualCategory.hwando,
      status: AttackVisualStatus.generatedReview,
      layers: _masterCircleLayers,
      rotateWithDirection: false,
    ),
    'hwando_master_finisher': AttackVisualSpec(
      effectId: 'hwando_master_finisher',
      category: CombatVisualCategory.hwando,
      status: AttackVisualStatus.generatedReview,
      layers: _masterFinisherLayers,
      rotateWithDirection: true,
    ),
  };

  static final List<String> requiredAssetKeys = List.unmodifiable(
    _specs.values
        .expand((spec) => spec.layers)
        .map((layer) => layer.assetKey)
        .toSet(),
  );

  static AttackVisualSpec byId(String effectId) {
    final spec = _specs[effectId];
    if (spec != null) return spec;
    throw MissingAttackVisualException(effectId);
  }
}
