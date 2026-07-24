import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/audio/audio_asset_catalog.dart';
import 'package:pixel_survivor/game/audio/audio_cue.dart';
import 'package:pixel_survivor/game/content/asset_catalog.dart';
import 'package:pixel_survivor/game/content/augment_definitions.dart';
import 'package:pixel_survivor/game/content/boss_definitions.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/content_integrity.dart';
import 'package:pixel_survivor/game/content/content_roster_contract.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';
import 'package:pixel_survivor/game/content/ids.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
import 'package:pixel_survivor/game/content/unlock_definitions.dart';
import 'package:pixel_survivor/game/content/wave_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';

void main() {
  test('bandit atlas is a transparent 512px RGBA 4 by 4 sheet', () async {
    final bytes = File(
      'assets/images/monsters/bandit_128.png',
    ).readAsBytesSync();

    expect(
      AssetCatalog.monsters[bandit],
      'assets/images/monsters/bandit_128.png',
    );
    expect(_pngUint32(bytes, 16), 512);
    expect(_pngUint32(bytes, 20), 512);
    expect(bytes[25], 6, reason: 'PNG IHDR color type must be RGBA');

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    final rgba = data!.buffer.asUint8List();
    int alphaAt(int x, int y) => rgba[(y * 512 + x) * 4 + 3];

    for (final corner in const [(0, 0), (511, 0), (0, 511), (511, 511)]) {
      expect(alphaAt(corner.$1, corner.$2), 0, reason: 'corner $corner');
    }
    for (final boundary in const [0, 127, 128, 255, 256, 383, 384, 511]) {
      expect(
        List.generate(512, (offset) => alphaAt(boundary, offset)),
        everyElement(0),
        reason: 'vertical cell gutter $boundary must be transparent',
      );
      expect(
        List.generate(512, (offset) => alphaAt(offset, boundary)),
        everyElement(0),
        reason: 'horizontal cell gutter $boundary must be transparent',
      );
    }
    for (var row = 0; row < 4; row += 1) {
      for (var column = 0; column < 4; column += 1) {
        final occupied = <int>[];
        for (var y = row * 128 + 1; y < (row + 1) * 128 - 1; y += 1) {
          for (var x = column * 128 + 1; x < (column + 1) * 128 - 1; x += 1) {
            occupied.add(alphaAt(x, y));
          }
        }
        expect(
          occupied.any((alpha) => alpha > 0),
          isTrue,
          reason: 'frame ${row * 4 + column} must contain bandit art',
        );
      }
    }

    frame.image.dispose();
    codec.dispose();
  });

  test('exorcist atlas is a transparent 512px RGBA 4 by 4 sheet', () async {
    final bytes = File(
      'assets/images/player/exorcist_dosa_128.png',
    ).readAsBytesSync();

    expect(_pngUint32(bytes, 16), 512);
    expect(_pngUint32(bytes, 20), 512);
    expect(bytes[25], 6, reason: 'PNG IHDR color type must be RGBA');

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    final rgba = data!.buffer.asUint8List();
    int alphaAt(int x, int y) => rgba[(y * 512 + x) * 4 + 3];

    for (final corner in const [(0, 0), (511, 0), (0, 511), (511, 511)]) {
      expect(alphaAt(corner.$1, corner.$2), 0, reason: 'corner $corner');
    }
    for (final boundary in const [0, 127, 128, 255, 256, 383, 384, 511]) {
      expect(
        List.generate(512, (offset) => alphaAt(boundary, offset)),
        everyElement(0),
        reason: 'vertical cell gutter $boundary must be transparent',
      );
      expect(
        List.generate(512, (offset) => alphaAt(offset, boundary)),
        everyElement(0),
        reason: 'horizontal cell gutter $boundary must be transparent',
      );
    }

    frame.image.dispose();
    codec.dispose();
  });

  test(
    'representative enemy atlases are transparent 512px RGBA sheets',
    () async {
      for (final path in const [
        'assets/images/monsters/plague_rat_swarm_128.png',
        'assets/images/monsters/vengeful_spirit_128.png',
        'assets/images/monsters/sakkat_specter_128.png',
        'assets/images/monsters/dokkaebi_128.png',
      ]) {
        final bytes = File(path).readAsBytesSync();

        expect(_pngUint32(bytes, 16), 512, reason: path);
        expect(_pngUint32(bytes, 20), 512, reason: path);
        expect(bytes[25], 6, reason: '$path must be RGBA');

        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final data = await frame.image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        final rgba = data!.buffer.asUint8List();
        int alphaAt(int x, int y) => rgba[(y * 512 + x) * 4 + 3];

        for (final corner in const [(0, 0), (511, 0), (0, 511), (511, 511)]) {
          expect(alphaAt(corner.$1, corner.$2), 0, reason: '$path $corner');
        }
        for (final boundary in const [0, 127, 128, 255, 256, 383, 384, 511]) {
          expect(
            List.generate(512, (offset) => alphaAt(boundary, offset)),
            everyElement(0),
            reason: '$path vertical gutter $boundary',
          );
          expect(
            List.generate(512, (offset) => alphaAt(offset, boundary)),
            everyElement(0),
            reason: '$path horizontal gutter $boundary',
          );
        }

        frame.image.dispose();
        codec.dispose();
      }
    },
  );

  test('aggregate report is deterministic and covers bundled contracts', () {
    final images = bundledImagePathsFromDisk();
    final first = validateContentIntegrity(bundledImagePaths: images);
    final second = validateContentIntegrity(bundledImagePaths: images);

    expect(first.issues, second.issues);
    expect(first.isValid, isTrue, reason: first.issues.join('\n'));
    expect(
      AssetCatalog.characters.keys,
      containsAll(characterDefinitions.map((item) => item.id)),
    );
    expect(
      AssetCatalog.weapons.keys,
      containsAll(weaponDefinitions.map((item) => item.id)),
    );
    expect(AudioAssetCatalog.assets.keys.toSet(), AudioCue.values.toSet());
  });

  test('asset catalog excludes missing superseded effect paths', () {
    expect(
      AssetCatalog.allPaths,
      isNot(contains('assets/images/effects/healing_item_16.png')),
    );
    expect(
      AssetCatalog.allPaths,
      isNot(contains('assets/images/effects/hwando_slash_effect_64.png')),
    );
  });

  test('malformed injected catalog reports duplicates and bad references', () {
    const duplicateCharacter = CharacterDefinition(
      id: rookieConstable,
      name: 'Duplicate',
      maxHealth: 1,
      moveSpeed: 1,
      damageMultiplier: 1,
      startingWeaponId: 'missing_weapon',
    );

    final report = validateContentIntegrity(
      characters: const [duplicateCharacter, duplicateCharacter],
      expectedCounts: const ContentRosterCounts(
        characters: 2,
        weapons: 8,
        weaponLevels: 42,
        augments: 16,
        normalEnemies: 8,
        eliteEnemies: 3,
        stages: 2,
        bosses: 3,
        unlockGoals: 15,
      ),
      bundledImagePaths: bundledImagePathsFromDisk(),
    );

    expect(report.issues, contains('Duplicate character id: $rookieConstable'));
    expect(
      report.issues,
      contains('Unknown starting weapon: $rookieConstable/missing_weapon'),
    );
  });

  test('injected enemy wave and boss catalogs are validated in isolation', () {
    const badEnemy = EnemyDefinition(
      id: plagueRatSwarm,
      name: 'Bad rat',
      maxHealth: -1,
      moveSpeed: 1,
      damage: 1,
      experience: 1,
      faction: EnemyFaction.plague,
      rank: EnemyRank.normal,
      behaviorProfileId: 'swarm',
    );
    const badWave = WaveDefinition(
      startSecond: 0,
      endSecond: 120,
      enemyWeights: {'missing_enemy': 1},
      eliteWeights: {},
      startSpawnsPerSecond: 1,
      endSpawnsPerSecond: 1,
      groupSize: 1,
      startEliteChance: 0,
      endEliteChance: 0,
      startMaxActiveEnemies: 1,
      endMaxActiveEnemies: 1,
    );
    final badBoss = BossDefinition(
      enemy: const EnemyDefinition(
        id: plagueMagistrate,
        name: 'Bad boss',
        maxHealth: -1,
        moveSpeed: 1,
        damage: 1,
        experience: 1,
        faction: EnemyFaction.plague,
        rank: EnemyRank.boss,
        behaviorProfileId: 'tank',
      ),
      patterns: plagueMagistrateBossDefinition.patterns,
      enrage: plagueMagistrateBossDefinition.enrage,
    );

    final report = validateContentIntegrity(
      enemies: [badEnemy],
      stages: const [
        StageDefinition(
          id: plagueMarket,
          name: 'Injected',
          description: 'Injected',
          targetSeconds: 300,
          bossArrivalSeconds: 270,
          presentationImageKey: 'plague_market_presentation',
          visualTheme: StageVisualTheme.plague,
          backgroundColorValue: 0,
          riskLabel: 'Injected',
        ),
      ],
      bosses: [badBoss],
      stageWaves: {
        plagueMarket: [badWave],
      },
    );

    expect(report.issues, contains('Invalid health: $plagueRatSwarm'));
    expect(report.issues, contains('Unknown wave enemy: missing_enemy'));
    expect(report.issues, contains('Invalid boss health: $plagueMagistrate'));
    expect(
      report.issues,
      contains('Wave coverage ends before boss arrival: $plagueMarket'),
    );
    expect(
      report.issues,
      contains('Wave coverage ends before target: $plagueMarket'),
    );
  });

  test('exact roster contract rejects count-preserving id substitutions', () {
    const substituted = CharacterDefinition(
      id: 'substitute_character',
      name: 'Substitute',
      maxHealth: 100,
      moveSpeed: 100,
      damageMultiplier: 1,
      startingWeaponId: hwandoSlash,
    );
    final report = validateContentIntegrity(
      characters: [substituted, ...characterDefinitions.skip(1)],
    );

    expect(
      report.issues,
      contains('Missing planned character id: $rookieConstable'),
    );
    expect(
      report.issues,
      contains('Unexpected character id: substitute_character'),
    );
  });

  test('planned ids are an independent literal authority', () {
    expect(ContentRosterContract.characterIds, {
      'rookie_constable',
      'exorcist_dosa',
      'mountain_hunter',
    });
    expect(ContentRosterContract.stageBossIds, {
      'moonlit_abandoned_office': {'fallen_general', 'masked_executioner'},
      'plague_market': {'plague_magistrate'},
    });

    final source = File(
      'lib/game/content/content_roster_contract.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('_definitions.dart')));
  });

  test(
    'unlock validation accumulates raw reward cardinality without throwing',
    () {
      const noReward = UnlockGoalDefinition.raw(
        id: 'no_reward',
        description: 'No reward',
        metric: UnlockMetric.totalKills,
        threshold: 1,
      );
      const twoRewards = UnlockGoalDefinition.raw(
        id: 'two_rewards',
        description: 'Two rewards',
        metric: UnlockMetric.totalKills,
        threshold: 1,
        unlocksWeaponId: talismanThrow,
        unlocksAugmentId: rapidReload,
      );

      final report = validateContentIntegrity(
        goals: [...unlockGoals, noReward, twoRewards],
      );

      expect(
        report.issues,
        contains('Unlock goal reward count must be one: no_reward/0'),
      );
      expect(
        report.issues,
        contains('Unlock goal reward count must be one: two_rewards/2'),
      );
    },
  );

  test('asset validation reports keys outside the injected roster', () {
    final report = validateContentIntegrity(
      characterAssets: {
        ...AssetCatalog.characters,
        'orphan_character': AssetCatalog.characters[rookieConstable]!,
      },
    );

    expect(report.issues, contains('Orphan character asset: orphan_character'));
  });

  test('audio paths agree with their declared channels', () {
    final report = validateContentIntegrity(
      bundledImagePaths: bundledImagePathsFromDisk(),
    );
    expect(
      report.issues.where((issue) => issue.startsWith('Invalid audio')),
      isEmpty,
    );

    for (final entry in AudioAssetCatalog.assets.entries) {
      final prefix = switch (AudioCueCatalog.channelFor(entry.key)) {
        AudioChannel.music => 'audio/music/',
        AudioChannel.sfx => 'audio/sfx/',
        AudioChannel.ui => 'audio/ui/',
      };
      expect(entry.value.path, startsWith(prefix), reason: entry.key.name);
      expect(File('assets/${entry.value.path}').existsSync(), isTrue);
    }
  });
}

Set<String> bundledImagePathsFromDisk() => Directory('assets/images')
    .listSync(recursive: true)
    .whereType<File>()
    .map((file) => file.path.replaceAll('\\', '/'))
    .toSet();

int _pngUint32(List<int> bytes, int offset) =>
    (bytes[offset] << 24) |
    (bytes[offset + 1] << 16) |
    (bytes[offset + 2] << 8) |
    bytes[offset + 3];
