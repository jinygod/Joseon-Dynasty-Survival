import 'dart:typed_data';

enum ArtAssetStatus { temporary, approved }

class SpriteAtlasContract {
  const SpriteAtlasContract({
    required this.id,
    required this.runtimePath,
    required this.frameWidth,
    required this.frameHeight,
    required this.columns,
    required this.rows,
    required this.requiresTransparency,
    required this.status,
  });

  final String id;
  final String runtimePath;
  final int frameWidth;
  final int frameHeight;
  final int columns;
  final int rows;
  final bool requiresTransparency;
  final ArtAssetStatus status;

  String get assetKey => runtimePath.replaceFirst('assets/', '');
  int get pixelWidth => frameWidth * columns;
  int get pixelHeight => frameHeight * rows;

  int frameIndex({required int column, required int row}) {
    if (column < 0 || column >= columns) {
      throw RangeError.range(column, 0, columns - 1, 'column');
    }
    if (row < 0 || row >= rows) {
      throw RangeError.range(row, 0, rows - 1, 'row');
    }
    return row * columns + column;
  }

  List<String> validatePngHeader(Uint8List bytes) {
    const signature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length < 26) {
      return const ['invalid PNG signature'];
    }
    for (var index = 0; index < signature.length; index += 1) {
      if (bytes[index] != signature[index]) {
        return const ['invalid PNG signature'];
      }
    }

    final header = ByteData.sublistView(bytes);
    final width = header.getUint32(16, Endian.big);
    final height = header.getUint32(20, Endian.big);
    final errors = <String>[];
    if (width != pixelWidth || height != pixelHeight) {
      errors.add(
        'expected ${pixelWidth}x$pixelHeight PNG, found ${width}x$height',
      );
    }
    if (requiresTransparency && bytes[25] != 6) {
      errors.add('expected RGBA PNG color type 6, found ${bytes[25]}');
    }
    return errors;
  }
}

/// Future enemy sheets whose visual specification is locked before generation.
const Map<String, SpriteAtlasContract> missingEightVisualContracts =
    <String, SpriteAtlasContract>{
      'sakkat_specter': SpriteAtlasContract(
        id: 'sakkat_specter',
        runtimePath: 'assets/images/enemies/sakkat_specter_128.png',
        frameWidth: 128,
        frameHeight: 128,
        columns: 4,
        rows: 4,
        requiresTransparency: true,
        status: ArtAssetStatus.temporary,
      ),
      'plague_crow': SpriteAtlasContract(
        id: 'plague_crow',
        runtimePath: 'assets/images/enemies/plague_crow_128.png',
        frameWidth: 128,
        frameHeight: 128,
        columns: 4,
        rows: 4,
        requiresTransparency: true,
        status: ArtAssetStatus.temporary,
      ),
      'spear_bandit': SpriteAtlasContract(
        id: 'spear_bandit',
        runtimePath: 'assets/images/enemies/spear_bandit_128.png',
        frameWidth: 128,
        frameHeight: 128,
        columns: 4,
        rows: 4,
        requiresTransparency: true,
        status: ArtAssetStatus.temporary,
      ),
      'rotten_herbalist': SpriteAtlasContract(
        id: 'rotten_herbalist',
        runtimePath: 'assets/images/enemies/rotten_herbalist_128.png',
        frameWidth: 128,
        frameHeight: 128,
        columns: 4,
        rows: 4,
        requiresTransparency: true,
        status: ArtAssetStatus.temporary,
      ),
      'grave_ember': SpriteAtlasContract(
        id: 'grave_ember',
        runtimePath: 'assets/images/enemies/grave_ember_128.png',
        frameWidth: 128,
        frameHeight: 128,
        columns: 4,
        rows: 4,
        requiresTransparency: true,
        status: ArtAssetStatus.temporary,
      ),
      'black_hat_assassin': SpriteAtlasContract(
        id: 'black_hat_assassin',
        runtimePath: 'assets/images/enemies/black_hat_assassin_128.png',
        frameWidth: 128,
        frameHeight: 128,
        columns: 4,
        rows: 4,
        requiresTransparency: true,
        status: ArtAssetStatus.temporary,
      ),
      'broken_jangseung_spirit': SpriteAtlasContract(
        id: 'broken_jangseung_spirit',
        runtimePath: 'assets/images/enemies/broken_jangseung_spirit_128.png',
        frameWidth: 128,
        frameHeight: 128,
        columns: 4,
        rows: 4,
        requiresTransparency: true,
        status: ArtAssetStatus.temporary,
      ),
      'sorrowful_maiden_ghost': SpriteAtlasContract(
        id: 'sorrowful_maiden_ghost',
        runtimePath: 'assets/images/enemies/sorrowful_maiden_ghost_128.png',
        frameWidth: 128,
        frameHeight: 128,
        columns: 4,
        rows: 4,
        requiresTransparency: true,
        status: ArtAssetStatus.temporary,
      ),
    };

abstract final class ReplaceableArtCatalog {
  /// The reviewed runtime slots for the first balanced-casual combat set.
  ///
  /// Their contracts are declared before the PNGs land so loaders can keep
  /// using the established fallback artwork until each replacement is bundled.
  static const representativeAtlasIds = <String>{
    'exorcist_dosa_balanced_casual',
    'plague_rat_swarm_balanced_casual',
    'vengeful_spirit_balanced_casual',
    'sakkat_specter_balanced_casual',
    'dokkaebi_balanced_casual',
    'bandit_balanced_casual',
  };

  static const List<SpriteAtlasContract>
  _bundledAtlases = <SpriteAtlasContract>[
    SpriteAtlasContract(
      id: 'bandit_balanced_casual',
      runtimePath: 'assets/images/monsters/bandit_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 4,
      rows: 4,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'exorcist_dosa_balanced_casual',
      runtimePath: 'assets/images/player/exorcist_dosa_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 4,
      rows: 4,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'plague_rat_swarm_balanced_casual',
      runtimePath: 'assets/images/monsters/plague_rat_swarm_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 4,
      rows: 4,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'vengeful_spirit_balanced_casual',
      runtimePath: 'assets/images/monsters/vengeful_spirit_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 4,
      rows: 4,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'sakkat_specter_balanced_casual',
      runtimePath: 'assets/images/enemies/sakkat_specter_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 4,
      rows: 4,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'dokkaebi_balanced_casual',
      runtimePath: 'assets/images/monsters/dokkaebi_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 4,
      rows: 4,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'exorcist_swordswoman_player',
      runtimePath: 'assets/images/player/exorcist_swordswoman_static_64.png',
      frameWidth: 64,
      frameHeight: 64,
      columns: 1,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'weapon_effects_atlas',
      runtimePath: 'assets/images/effects/weapon_effects_atlas_64.png',
      frameWidth: 64,
      frameHeight: 64,
      columns: 4,
      rows: 4,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'combat_effects_atlas',
      runtimePath: 'assets/images/effects/combat_effects_atlas_64.png',
      frameWidth: 64,
      frameHeight: 64,
      columns: 4,
      rows: 5,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'hwando_release_windup_128',
      runtimePath: 'assets/images/vfx/hwando/hwando_windup_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 4,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.approved,
    ),
    SpriteAtlasContract(
      id: 'hwando_release_strike_128',
      runtimePath: 'assets/images/vfx/hwando/hwando_strike_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 6,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.approved,
    ),
    SpriteAtlasContract(
      id: 'hwando_release_recovery_128',
      runtimePath: 'assets/images/vfx/hwando/hwando_recovery_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 4,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.approved,
    ),
    SpriteAtlasContract(
      id: 'hwando_release_contact_128',
      runtimePath: 'assets/images/vfx/hwando/hwando_contact_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 6,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.approved,
    ),
    SpriteAtlasContract(
      id: 'hwando_slash_trail_128',
      runtimePath: 'assets/images/vfx/hwando_slash_trail_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 6,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'hwando_slash_impact_128',
      runtimePath: 'assets/images/vfx/hwando_slash_impact_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 5,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'hwando_blade_wave_trail_128',
      runtimePath: 'assets/images/vfx/hwando_blade_wave_trail_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 6,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'hwando_blade_wave_impact_128',
      runtimePath: 'assets/images/vfx/hwando_blade_wave_impact_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 5,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'hwando_master_circle_trail_128',
      runtimePath: 'assets/images/vfx/hwando_master_circle_trail_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 8,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'hwando_master_circle_impact_128',
      runtimePath: 'assets/images/vfx/hwando_master_circle_impact_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 6,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'hwando_master_finisher_trail_128',
      runtimePath: 'assets/images/vfx/hwando_master_finisher_trail_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 8,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'hwando_master_finisher_impact_128',
      runtimePath: 'assets/images/vfx/hwando_master_finisher_impact_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 6,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'sealing_slash_128',
      runtimePath: 'assets/images/vfx/player/sealing_slash_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 6,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'wind_thunder_fan_128',
      runtimePath: 'assets/images/vfx/player/wind_thunder_fan_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 6,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'singijeon_128',
      runtimePath: 'assets/images/projectiles/player/singijeon_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 4,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'jangseung_ward_128',
      runtimePath: 'assets/images/zones/player/jangseung_ward_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 8,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'frost_field_128',
      runtimePath: 'assets/images/zones/player/frost_field_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 8,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'talisman_attachment_128',
      runtimePath: 'assets/images/vfx/player/talisman_attachment_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 4,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'talisman_transfer_128',
      runtimePath: 'assets/images/vfx/player/talisman_transfer_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 6,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'talisman_explosion_128',
      runtimePath: 'assets/images/vfx/player/talisman_explosion_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 6,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'talisman_ward_128',
      runtimePath: 'assets/images/zones/player/talisman_ward_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 8,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'enemy_poison_pool_128',
      runtimePath: 'assets/images/vfx/enemy/poison_pool_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 8,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'enemy_shockwave_128',
      runtimePath: 'assets/images/vfx/enemy/shockwave_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 6,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'enemy_spirit_scream_128',
      runtimePath: 'assets/images/vfx/enemy/spirit_scream_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 6,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'enemy_line_telegraph_128',
      runtimePath: 'assets/images/vfx/enemy/line_telegraph_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 6,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'enemy_ranged_telegraph_128',
      runtimePath: 'assets/images/vfx/enemy/ranged_telegraph_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 6,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'enemy_radial_telegraph_128',
      runtimePath: 'assets/images/vfx/enemy/radial_telegraph_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 8,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'enemy_shield_block_flash_128',
      runtimePath: 'assets/images/vfx/enemy/shield_block_flash_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 5,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'sakkat_spirit_projectile_128',
      runtimePath:
          'assets/images/projectiles/enemy/sakkat_spirit_projectile_128.png',
      frameWidth: 128,
      frameHeight: 128,
      columns: 4,
      rows: 1,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
  ];

  static final List<SpriteAtlasContract> atlases = List.unmodifiable([
    ..._bundledAtlases,
    ...missingEightVisualContracts.values,
  ]);

  static SpriteAtlasContract byId(String id) {
    for (final contract in atlases) {
      if (contract.id == id) return contract;
    }
    throw ArgumentError.value(id, 'id', 'unknown sprite atlas');
  }
}
