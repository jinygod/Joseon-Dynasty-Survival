import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/art_style_guide.dart';
import 'package:pixel_survivor/game/content/asset_catalog.dart';

void main() {
  test('representative art brief locks the approved lineup', () {
    final brief = File(
      'docs/assets/prompts/balanced-casual-representative-set.md',
    ).readAsStringSync();
    for (final token in [
      'exorcist_dosa',
      'plague_rat_swarm',
      'vengeful_spirit',
      'sakkat_specter',
      'dokkaebi',
      '128x128',
      '4x4',
      'bold clean outline',
      'Joseon',
    ]) {
      expect(brief, contains(token));
    }
  });

  test('palette colors are unique opaque ARGB values', () {
    expect(JoseonArtStyle.palette, hasLength(11));
    expect(JoseonArtStyle.palette.values.toSet(), hasLength(11));
    expect(
      JoseonArtStyle.palette.values.every((color) => color >> 24 == 0xff),
      isTrue,
    );
  });

  test('native sprite sizes and integer display scales are fixed', () {
    expect(JoseonArtStyle.pickupSize, 16);
    expect(JoseonArtStyle.swarmSize, 24);
    expect(JoseonArtStyle.standardSize, 32);
    expect(JoseonArtStyle.bossSize, 64);
    expect(JoseonArtStyle.integerScales, [1, 2, 3, 4]);
  });

  test('combat slice character rendering contract is fixed', () {
    expect(JoseonArtStyle.characterHeadRatioMin, 3);
    expect(JoseonArtStyle.characterHeadRatioMax, 4);
    expect(JoseonArtStyle.cellShadeStepsMin, 2);
    expect(JoseonArtStyle.cellShadeStepsMax, 3);
    expect(JoseonArtStyle.outlineStyle, 'bold_clean');
    expect(JoseonArtStyle.allowsBulkFinalArt, isFalse);
    expect(JoseonArtStyle.temporaryActorVisualSizes, {
      'player': 108,
      'normalEnemy': 54,
      'eliteEnemy': 81,
      'boss': 126,
    });
  });

  test('Joseon character and monster vocabularies are explicit', () {
    expect(JoseonArtStyle.characterDesignCues.keys.toSet(), {
      'hwandoSwordsman',
      'mudang',
      'musketeer',
      'dokkaebiHunter',
    });
    expect(JoseonArtStyle.monsterSilhouetteCues.keys.toSet(), {
      'littleDokkaebi',
      'jarGhost',
      'jangseungGhost',
      'sakkatSpecter',
      'fireDokkaebi',
      'eggGhost',
      'underworldMinion',
      'tigerDemon',
      'plagueGhost',
      'fallenOfficer',
    });
    expect(
      JoseonArtStyle.characterDesignCues.values.every((cue) => cue.isNotEmpty),
      isTrue,
    );
    expect(
      JoseonArtStyle.monsterSilhouetteCues.values.every(
        (cue) => cue.isNotEmpty,
      ),
      isTrue,
    );
    expect(JoseonArtStyle.forbiddenDesignCues, [
      'japanese_samurai_armor',
      'chinese_wuxia_robes',
      'copied_commercial_game_assets',
    ]);
  });

  test('every catalog asset uses an approved native-size suffix', () {
    expect(
      JoseonArtStyle.hasApprovedSizeSuffix(
        'assets/images/player/exorcist_dosa_128.png',
      ),
      isTrue,
    );
    final paths = <String>[
      ...AssetCatalog.characters.values,
      ...AssetCatalog.monsters.values,
      ...AssetCatalog.weapons.values,
      ...AssetCatalog.augments.values,
      ...AssetCatalog.effects.values,
      ...AssetCatalog.stages.values,
      ...AssetCatalog.lobby.values,
      ...AssetCatalog.player.values,
    ];

    expect(paths, isNotEmpty);
    expect(paths.every(JoseonArtStyle.hasApprovedSizeSuffix), isTrue);
  });

  test('silhouette rules keep gameplay classes distinct', () {
    expect(JoseonArtStyle.silhouettes.keys.toSet(), {
      'player',
      'swarm',
      'chaser',
      'tank',
      'spirit',
      'boss',
    });
    for (final rule in JoseonArtStyle.silhouettes.values) {
      expect(rule.occupancyMin, greaterThanOrEqualTo(0.45));
      expect(rule.occupancyMax, lessThanOrEqualTo(0.9));
      expect(rule.readabilityCue, isNotEmpty);
    }
  });

  test('static player art is a 64px RGBA PNG', () {
    final bytes = File(
      'assets/images/player/exorcist_swordswoman_static_64.png',
    ).readAsBytesSync();
    int readUint32(int offset) =>
        (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];

    expect(readUint32(16), 64);
    expect(readUint32(20), 64);
    expect(bytes[25], 6, reason: 'PNG must use RGBA color type');
  });

  test('normal enemy sheets are 4x4 RGBA grids at approved frame sizes', () {
    final expectedCells = <String, int>{
      'assets/images/monsters/plague_rat_swarm_24.png': 24,
      'assets/images/monsters/bandit_32.png': 32,
      'assets/images/monsters/dokkaebi_32.png': 32,
      'assets/images/monsters/vengeful_spirit_32.png': 32,
      'assets/images/enemies/sakkat_specter_128.png': 128,
      'assets/images/enemies/plague_crow_128.png': 128,
      'assets/images/enemies/spear_bandit_128.png': 128,
      'assets/images/enemies/rotten_herbalist_128.png': 128,
      'assets/images/enemies/grave_ember_128.png': 128,
      'assets/images/enemies/black_hat_assassin_128.png': 128,
      'assets/images/enemies/broken_jangseung_spirit_128.png': 128,
      'assets/images/enemies/sorrowful_maiden_ghost_128.png': 128,
    };

    for (final entry in expectedCells.entries) {
      final bytes = File(entry.key).readAsBytesSync();
      int readUint32(int offset) =>
          (bytes[offset] << 24) |
          (bytes[offset + 1] << 16) |
          (bytes[offset + 2] << 8) |
          bytes[offset + 3];

      expect(readUint32(16), entry.value * 4, reason: entry.key);
      expect(readUint32(20), entry.value * 4, reason: entry.key);
      expect(bytes[25], 6, reason: '${entry.key} must use RGBA color type');
    }
  });

  test('boss sheet is a 4x4 RGBA grid of 64px frames', () {
    final bytes = File(
      'assets/images/monsters/fallen_general_64.png',
    ).readAsBytesSync();
    int readUint32(int offset) =>
        (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];

    expect(readUint32(16), 256);
    expect(readUint32(20), 256);
    expect(bytes[25], 6, reason: 'boss PNG must use RGBA color type');
  });

  test('weapon effect atlas is a 4x4 RGBA grid of 64px frames', () {
    final bytes = File(
      'assets/images/effects/weapon_effects_atlas_64.png',
    ).readAsBytesSync();
    int readUint32(int offset) =>
        (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];

    expect(readUint32(16), 256);
    expect(readUint32(20), 256);
    expect(bytes[25], 6, reason: 'effect atlas must use RGBA color type');
  });

  test('combat effect atlas is a 4x5 RGBA grid of 64px frames', () {
    final bytes = File(
      'assets/images/effects/combat_effects_atlas_64.png',
    ).readAsBytesSync();
    int readUint32(int offset) =>
        (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];

    expect(readUint32(16), 256);
    expect(readUint32(20), 320);
    expect(bytes[25], 6, reason: 'combat atlas must use RGBA color type');
  });
}
