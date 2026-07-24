// ignore_for_file: prefer_const_constructors

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
  static const hwandoContactAssetKey = 'vfx/hwando/hwando_contact_128.png';

  static const _slashLayers = <AttackVisualLayerSpec>[
    AttackVisualLayerSpec(
      id: 'windup',
      assetKey: 'vfx/hwando/hwando_windup_128.png',
      frameSize: 128,
      frameCount: 4,
      anchor: Anchor.center,
      priorityOffset: 0,
      startFraction: 0,
      endFraction: .25,
    ),
    AttackVisualLayerSpec(
      id: 'strike',
      assetKey: 'vfx/hwando/hwando_strike_128.png',
      frameSize: 128,
      frameCount: 6,
      anchor: Anchor.center,
      priorityOffset: 1,
      startFraction: .25,
      endFraction: .583333,
    ),
    AttackVisualLayerSpec(
      id: 'recovery',
      assetKey: 'vfx/hwando/hwando_recovery_128.png',
      frameSize: 128,
      frameCount: 4,
      anchor: Anchor.center,
      priorityOffset: 0,
      startFraction: .583333,
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

  static const _sealingSlashLayers = <AttackVisualLayerSpec>[
    AttackVisualLayerSpec(
      id: 'trail',
      assetKey: 'vfx/player/sealing_slash_128.png',
      frameSize: 128,
      frameCount: 6,
      anchor: Anchor.center,
      priorityOffset: 0,
      startFraction: 0,
      endFraction: 1,
    ),
  ];

  static const _windThunderFanLayers = <AttackVisualLayerSpec>[
    AttackVisualLayerSpec(
      id: 'effect',
      assetKey: 'vfx/player/wind_thunder_fan_128.png',
      frameSize: 128,
      frameCount: 6,
      anchor: Anchor.center,
      priorityOffset: 0,
      startFraction: 0,
      endFraction: 1,
    ),
  ];

  static const _singijeonVolleyLayers = <AttackVisualLayerSpec>[
    AttackVisualLayerSpec(
      id: 'effect',
      assetKey: 'projectiles/player/singijeon_128.png',
      frameSize: 128,
      frameCount: 4,
      anchor: Anchor.center,
      priorityOffset: 0,
      startFraction: 0,
      endFraction: 1,
    ),
  ];

  static const _jangseungWardLayers = <AttackVisualLayerSpec>[
    AttackVisualLayerSpec(
      id: 'effect',
      assetKey: 'zones/player/jangseung_ward_128.png',
      frameSize: 128,
      frameCount: 8,
      anchor: Anchor.center,
      priorityOffset: 0,
      startFraction: 0,
      endFraction: 1,
    ),
  ];

  static const _frostFlaskLayers = <AttackVisualLayerSpec>[
    AttackVisualLayerSpec(
      id: 'effect',
      assetKey: 'zones/player/frost_field_128.png',
      frameSize: 128,
      frameCount: 8,
      anchor: Anchor.center,
      priorityOffset: 0,
      startFraction: 0,
      endFraction: 1,
    ),
  ];

  static const _talismanAttachmentLayers = <AttackVisualLayerSpec>[
    AttackVisualLayerSpec(
      id: 'effect',
      assetKey: 'vfx/player/talisman_attachment_128.png',
      frameSize: 128,
      frameCount: 4,
      anchor: Anchor.center,
      priorityOffset: 0,
      startFraction: 0,
      endFraction: 1,
    ),
  ];

  static const _talismanTransferLayers = <AttackVisualLayerSpec>[
    AttackVisualLayerSpec(
      id: 'effect',
      assetKey: 'vfx/player/talisman_transfer_128.png',
      frameSize: 128,
      frameCount: 6,
      anchor: Anchor.center,
      priorityOffset: 0,
      startFraction: 0,
      endFraction: 1,
    ),
  ];

  static const _talismanExplosionLayers = <AttackVisualLayerSpec>[
    AttackVisualLayerSpec(
      id: 'effect',
      assetKey: 'vfx/player/talisman_explosion_128.png',
      frameSize: 128,
      frameCount: 6,
      anchor: Anchor.center,
      priorityOffset: 0,
      startFraction: 0,
      endFraction: 1,
    ),
  ];

  static const _talismanWardLayers = <AttackVisualLayerSpec>[
    AttackVisualLayerSpec(
      id: 'effect',
      assetKey: 'zones/player/talisman_ward_128.png',
      frameSize: 128,
      frameCount: 8,
      anchor: Anchor.center,
      priorityOffset: 0,
      startFraction: 0,
      endFraction: 1,
    ),
  ];

  static final _specs = <String, AttackVisualSpec>{
    'enemy_poison_pool': _enemySpec(
      'enemy_poison_pool',
      CombatVisualCategory.area,
      'vfx/enemy/poison_pool_128.png',
      8,
      false,
    ),
    'enemy_shockwave': _enemySpec(
      'enemy_shockwave',
      CombatVisualCategory.area,
      'vfx/enemy/shockwave_128.png',
      6,
      false,
    ),
    'enemy_spirit_scream': _enemySpec(
      'enemy_spirit_scream',
      CombatVisualCategory.area,
      'vfx/enemy/spirit_scream_128.png',
      6,
      false,
    ),
    'enemy_line_telegraph': _enemySpec(
      'enemy_line_telegraph',
      CombatVisualCategory.telegraph,
      'vfx/enemy/line_telegraph_128.png',
      6,
      true,
    ),
    'enemy_ranged_telegraph': _enemySpec(
      'enemy_ranged_telegraph',
      CombatVisualCategory.telegraph,
      'vfx/enemy/ranged_telegraph_128.png',
      6,
      true,
    ),
    'enemy_radial_telegraph': _enemySpec(
      'enemy_radial_telegraph',
      CombatVisualCategory.telegraph,
      'vfx/enemy/radial_telegraph_128.png',
      8,
      false,
    ),
    'enemy_shield_block_flash': _enemySpec(
      'enemy_shield_block_flash',
      CombatVisualCategory.status,
      'vfx/enemy/shield_block_flash_128.png',
      5,
      true,
    ),
    'sakkat_spirit_projectile': _enemySpec(
      'sakkat_spirit_projectile',
      CombatVisualCategory.projectile,
      'projectiles/enemy/sakkat_spirit_projectile_128.png',
      4,
      true,
    ),
    'hwando_slash': AttackVisualSpec(
      effectId: 'hwando_slash',
      category: CombatVisualCategory.hwando,
      status: AttackVisualStatus.ready,
      layers: _slashLayers,
      rotateWithDirection: true,
    ),
    'hwando_slash_left': AttackVisualSpec(
      effectId: 'hwando_slash_left',
      category: CombatVisualCategory.hwando,
      status: AttackVisualStatus.ready,
      layers: _slashLayers,
      rotateWithDirection: true,
    ),
    'hwando_slash_right': AttackVisualSpec(
      effectId: 'hwando_slash_right',
      category: CombatVisualCategory.hwando,
      status: AttackVisualStatus.ready,
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
      status: AttackVisualStatus.ready,
      layers: _slashLayers,
      rotateWithDirection: true,
    ),
    'hwando_master_left': AttackVisualSpec(
      effectId: 'hwando_master_left',
      category: CombatVisualCategory.hwando,
      status: AttackVisualStatus.ready,
      layers: _slashLayers,
      rotateWithDirection: true,
    ),
    'hwando_master_right': AttackVisualSpec(
      effectId: 'hwando_master_right',
      category: CombatVisualCategory.hwando,
      status: AttackVisualStatus.ready,
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
    'sealing_slash': AttackVisualSpec(
      effectId: 'sealing_slash',
      category: CombatVisualCategory.hwando,
      status: AttackVisualStatus.generatedReview,
      layers: _sealingSlashLayers,
      rotateWithDirection: true,
    ),
    'wind_thunder_fan': AttackVisualSpec(
      effectId: 'wind_thunder_fan',
      category: CombatVisualCategory.area,
      status: AttackVisualStatus.generatedReview,
      layers: _windThunderFanLayers,
      rotateWithDirection: true,
    ),
    'singijeon_volley': AttackVisualSpec(
      effectId: 'singijeon_volley',
      category: CombatVisualCategory.projectile,
      status: AttackVisualStatus.generatedReview,
      layers: _singijeonVolleyLayers,
      rotateWithDirection: true,
    ),
    'jangseung_ward': AttackVisualSpec(
      effectId: 'jangseung_ward',
      category: CombatVisualCategory.area,
      status: AttackVisualStatus.generatedReview,
      layers: _jangseungWardLayers,
      rotateWithDirection: false,
    ),
    'frost_flask': AttackVisualSpec(
      effectId: 'frost_flask',
      category: CombatVisualCategory.area,
      status: AttackVisualStatus.generatedReview,
      layers: _frostFlaskLayers,
      rotateWithDirection: false,
    ),
    'talisman_attachment': AttackVisualSpec(
      effectId: 'talisman_attachment',
      category: CombatVisualCategory.status,
      status: AttackVisualStatus.generatedReview,
      layers: _talismanAttachmentLayers,
      rotateWithDirection: false,
    ),
    'talisman_transfer': AttackVisualSpec(
      effectId: 'talisman_transfer',
      category: CombatVisualCategory.status,
      status: AttackVisualStatus.generatedReview,
      layers: _talismanTransferLayers,
      rotateWithDirection: true,
    ),
    'talisman_explosion': AttackVisualSpec(
      effectId: 'talisman_explosion',
      category: CombatVisualCategory.area,
      status: AttackVisualStatus.generatedReview,
      layers: _talismanExplosionLayers,
      rotateWithDirection: false,
    ),
    'talisman_small_ward': AttackVisualSpec(
      effectId: 'talisman_small_ward',
      category: CombatVisualCategory.area,
      status: AttackVisualStatus.generatedReview,
      layers: _talismanWardLayers,
      rotateWithDirection: false,
    ),
    'talisman_master_ward': AttackVisualSpec(
      effectId: 'talisman_master_ward',
      category: CombatVisualCategory.area,
      status: AttackVisualStatus.generatedReview,
      layers: _talismanWardLayers,
      rotateWithDirection: false,
    ),
  };

  static AttackVisualSpec _enemySpec(
    String effectId,
    CombatVisualCategory category,
    String assetKey,
    int frameCount,
    bool rotateWithDirection,
  ) => AttackVisualSpec(
    effectId: effectId,
    category: category,
    status: AttackVisualStatus.generatedReview,
    rotateWithDirection: rotateWithDirection,
    layers: [
      AttackVisualLayerSpec(
        id: 'effect',
        assetKey: assetKey,
        frameSize: 128,
        frameCount: frameCount,
        anchor: Anchor.center,
        priorityOffset: 0,
        startFraction: 0,
        endFraction: 1,
      ),
    ],
  );

  static final List<String> requiredAssetKeys = List.unmodifiable({
    ..._specs.values
        .expand((spec) => spec.layers)
        .map((layer) => layer.assetKey),
    hwandoContactAssetKey,
  });

  /// Stable, immutable IDs for tools that need to browse the production VFX.
  static final List<String> effectIds = List.unmodifiable(_specs.keys);

  static AttackVisualSpec byId(String effectId) {
    final spec = _specs[effectId];
    if (spec != null) return spec;
    throw MissingAttackVisualException(effectId);
  }
}
