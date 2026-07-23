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

abstract final class ReplaceableArtCatalog {
  static const atlases = <SpriteAtlasContract>[
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
      id: 'plague_rat_swarm',
      runtimePath: 'assets/images/monsters/plague_rat_swarm_24.png',
      frameWidth: 24,
      frameHeight: 24,
      columns: 4,
      rows: 4,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'bandit',
      runtimePath: 'assets/images/monsters/bandit_32.png',
      frameWidth: 32,
      frameHeight: 32,
      columns: 4,
      rows: 4,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'dokkaebi',
      runtimePath: 'assets/images/monsters/dokkaebi_32.png',
      frameWidth: 32,
      frameHeight: 32,
      columns: 4,
      rows: 4,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'vengeful_spirit',
      runtimePath: 'assets/images/monsters/vengeful_spirit_32.png',
      frameWidth: 32,
      frameHeight: 32,
      columns: 4,
      rows: 4,
      requiresTransparency: true,
      status: ArtAssetStatus.temporary,
    ),
    SpriteAtlasContract(
      id: 'fallen_general',
      runtimePath: 'assets/images/monsters/fallen_general_64.png',
      frameWidth: 64,
      frameHeight: 64,
      columns: 4,
      rows: 4,
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
  ];

  static SpriteAtlasContract byId(String id) {
    for (final contract in atlases) {
      if (contract.id == id) return contract;
    }
    throw ArgumentError.value(id, 'id', 'unknown sprite atlas');
  }
}
