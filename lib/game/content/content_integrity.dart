import '../audio/audio_asset_catalog.dart';
import '../audio/audio_cue.dart';
import 'art_style_guide.dart';
import 'asset_catalog.dart';
import 'augment_definitions.dart';
import 'boss_definitions.dart';
import 'character_definitions.dart';
import 'content_roster_contract.dart';
import 'enemy_definitions.dart';
import 'ids.dart';
import 'stage_definitions.dart';
import 'unlock_definitions.dart';
import 'wave_definitions.dart';
import 'weapon_definitions.dart';
import 'weapon_level_definitions.dart';
import '../systems/save_system.dart';

class ContentRosterCounts {
  const ContentRosterCounts({
    required this.characters,
    required this.weapons,
    required this.weaponLevels,
    required this.augments,
    required this.normalEnemies,
    required this.eliteEnemies,
    required this.stages,
    required this.bosses,
    required this.unlockGoals,
  });

  static const production = ContentRosterCounts(
    characters: 3,
    weapons: 8,
    weaponLevels: 40,
    augments: 16,
    normalEnemies: 8,
    eliteEnemies: 3,
    stages: 2,
    bosses: 3,
    unlockGoals: 15,
  );

  final int characters;
  final int weapons;
  final int weaponLevels;
  final int augments;
  final int normalEnemies;
  final int eliteEnemies;
  final int stages;
  final int bosses;
  final int unlockGoals;
}

class ContentIntegrityReport {
  ContentIntegrityReport({required this.counts, required List<String> issues})
    : issues = List.unmodifiable(issues);

  final ContentRosterCounts counts;
  final List<String> issues;

  bool get isValid => issues.isEmpty;
}

enum CombatBuildRole { frontlineControl, rangedFocus, areaAttrition }

class MinimumViableBuild {
  const MinimumViableBuild({
    required this.id,
    required this.role,
    required this.characterId,
    required this.stageId,
    required this.weaponLevels,
    required this.augmentLevels,
  });

  final String id;
  final CombatBuildRole role;
  final CharacterId characterId;
  final String stageId;
  final Map<WeaponId, int> weaponLevels;
  final Map<AugmentId, int> augmentLevels;
}

const minimumViableBuilds = <MinimumViableBuild>[
  MinimumViableBuild(
    id: 'frontline_control',
    role: CombatBuildRole.frontlineControl,
    characterId: rookieConstable,
    stageId: moonlitAbandonedOffice,
    weaponLevels: {hwandoSlash: 5, jangseungWard: 5},
    augmentLevels: {innerBreath: 3, ironArmorTraining: 3},
  ),
  MinimumViableBuild(
    id: 'ranged_focus',
    role: CombatBuildRole.rangedFocus,
    characterId: mountainHunter,
    stageId: plagueMarket,
    weaponLevels: {gakgungShot: 5, singijeonVolley: 5},
    augmentLevels: {hawkEye: 5, rapidReload: 5},
  ),
  MinimumViableBuild(
    id: 'area_attrition',
    role: CombatBuildRole.areaAttrition,
    characterId: exorcistDosa,
    stageId: plagueMarket,
    weaponLevels: {talismanThrow: 5, frostFlask: 5},
    augmentLevels: {powderMastery: 5, scholarInsight: 3},
  ),
];

ContentIntegrityReport validateContentIntegrity({
  List<CharacterDefinition> characters = characterDefinitions,
  List<WeaponDefinition> weapons = weaponDefinitions,
  Map<WeaponId, List<WeaponLevelDefinition>> levels = weaponLevels,
  List<AugmentDefinition> augments = augmentDefinitions,
  List<EnemyDefinition> enemies = enemyDefinitions,
  List<StageDefinition> stages = stageDefinitions,
  List<BossDefinition> bosses = bossDefinitions,
  List<UnlockGoalDefinition> goals = unlockGoals,
  Map<String, List<WaveDefinition>> stageWaves = stageWaveDefinitions,
  Map<String, String> characterAssets = AssetCatalog.characters,
  Map<String, String> monsterAssets = AssetCatalog.monsters,
  Map<String, String> weaponAssets = AssetCatalog.weapons,
  Map<String, String> augmentAssets = AssetCatalog.augments,
  Map<String, String> stageAssets = AssetCatalog.stages,
  Map<AudioCue, AudioAssetDefinition> audioAssets = AudioAssetCatalog.assets,
  Set<String> bundledImagePaths = const {},
  ContentRosterCounts expectedCounts = ContentRosterCounts.production,
}) {
  final counts = ContentRosterCounts(
    characters: characters.length,
    weapons: weapons.length,
    weaponLevels: levels.values.fold(0, (sum, items) => sum + items.length),
    augments: augments.length,
    normalEnemies: enemies
        .where((item) => item.rank == EnemyRank.normal)
        .length,
    eliteEnemies: enemies.where((item) => item.rank == EnemyRank.elite).length,
    stages: stages.length,
    bosses: bosses.length,
    unlockGoals: goals.length,
  );
  final issues = <String>[];

  _expectCount(
    issues,
    'characters',
    counts.characters,
    expectedCounts.characters,
  );
  _expectCount(issues, 'weapons', counts.weapons, expectedCounts.weapons);
  _expectCount(
    issues,
    'weapon levels',
    counts.weaponLevels,
    expectedCounts.weaponLevels,
  );
  _expectCount(issues, 'augments', counts.augments, expectedCounts.augments);
  _expectCount(
    issues,
    'normal enemies',
    counts.normalEnemies,
    expectedCounts.normalEnemies,
  );
  _expectCount(
    issues,
    'elite enemies',
    counts.eliteEnemies,
    expectedCounts.eliteEnemies,
  );
  _expectCount(issues, 'stages', counts.stages, expectedCounts.stages);
  _expectCount(issues, 'bosses', counts.bosses, expectedCounts.bosses);
  _expectCount(
    issues,
    'unlock goals',
    counts.unlockGoals,
    expectedCounts.unlockGoals,
  );

  _validateCharacters(issues, characters, weapons);
  _validateWeapons(issues, weapons, levels);
  _validateAugments(issues, augments);
  _validateUniqueIds(issues, 'enemy', enemies.map((item) => item.id));
  _validateUniqueIds(issues, 'stage', stages.map((item) => item.id));
  _validateUniqueIds(issues, 'boss', bosses.map((item) => item.id));
  _validatePlannedIds(
    issues,
    'character',
    characters.map((item) => item.id),
    ContentRosterContract.characterIds,
  );
  _validatePlannedIds(
    issues,
    'weapon',
    weapons.map((item) => item.id),
    ContentRosterContract.weaponIds,
  );
  _validatePlannedIds(
    issues,
    'augment',
    augments.map((item) => item.id),
    ContentRosterContract.augmentIds,
  );
  _validatePlannedIds(
    issues,
    'enemy',
    enemies.map((item) => item.id),
    ContentRosterContract.enemyIds,
  );
  _validatePlannedIds(
    issues,
    'stage',
    stages.map((item) => item.id),
    ContentRosterContract.stageIds,
  );
  _validatePlannedIds(
    issues,
    'boss',
    bosses.map((item) => item.id),
    ContentRosterContract.bossIds,
  );
  _validatePlannedIds(
    issues,
    'unlock goal',
    goals.map((item) => item.id),
    ContentRosterContract.unlockGoalIds,
  );
  _validateStages(issues, stages, stageWaves, bosses);
  _validateUnlocks(issues, goals, characters, weapons, augments, stages);

  issues
    ..addAll(validateEnemyContent(enemies))
    ..addAll(validateWaveContent(stageWaves: stageWaves, enemies: enemies))
    ..addAll(validateBossDefinitions(bosses, enemies: enemies));

  _validateAssets(
    issues,
    expectedIds: characters.map((item) => item.id),
    assets: characterAssets,
    label: 'character',
    bundledPaths: bundledImagePaths,
  );
  _validateAssets(
    issues,
    expectedIds: [
      ...enemies.map((item) => item.id),
      ...bosses.map((item) => item.id),
    ],
    assets: monsterAssets,
    label: 'monster',
    bundledPaths: bundledImagePaths,
  );
  _validateAssets(
    issues,
    expectedIds: weapons.map((item) => item.id),
    assets: weaponAssets,
    label: 'weapon',
    bundledPaths: bundledImagePaths,
  );
  _validateAssets(
    issues,
    expectedIds: augments.map((item) => item.id),
    assets: augmentAssets,
    label: 'augment',
    bundledPaths: bundledImagePaths,
  );
  _validateAssets(
    issues,
    expectedIds: stages.map((item) => item.id),
    assets: stageAssets,
    label: 'stage',
    bundledPaths: bundledImagePaths,
  );
  _validateAudio(issues, audioAssets);

  return ContentIntegrityReport(counts: counts, issues: issues);
}

void _expectCount(List<String> issues, String label, int actual, int expected) {
  if (actual != expected) {
    issues.add('Expected $expected $label, found $actual');
  }
}

void _validateUniqueIds(
  List<String> issues,
  String label,
  Iterable<String> ids,
) {
  final seen = <String>{};
  for (final id in ids) {
    if (!seen.add(id)) issues.add('Duplicate $label id: $id');
  }
}

void _validatePlannedIds(
  List<String> issues,
  String label,
  Iterable<String> actualIds,
  Set<String> plannedIds,
) {
  final actual = actualIds.toSet();
  for (final id in plannedIds.where((id) => !actual.contains(id))) {
    issues.add('Missing planned $label id: $id');
  }
  for (final id in actual.where((id) => !plannedIds.contains(id))) {
    issues.add('Unexpected $label id: $id');
  }
}

void _validateCharacters(
  List<String> issues,
  List<CharacterDefinition> characters,
  List<WeaponDefinition> weapons,
) {
  _validateUniqueIds(issues, 'character', characters.map((item) => item.id));
  final weaponIds = weapons.map((item) => item.id).toSet();
  for (final character in characters) {
    if (!character.maxHealth.isFinite ||
        character.maxHealth <= 0 ||
        !character.moveSpeed.isFinite ||
        character.moveSpeed <= 0 ||
        !character.damageMultiplier.isFinite ||
        character.damageMultiplier <= 0) {
      issues.add('Invalid character tuning: ${character.id}');
    }
    if (!weaponIds.contains(character.startingWeaponId)) {
      issues.add(
        'Unknown starting weapon: ${character.id}/${character.startingWeaponId}',
      );
    }
  }
}

void _validateWeapons(
  List<String> issues,
  List<WeaponDefinition> weapons,
  Map<WeaponId, List<WeaponLevelDefinition>> levels,
) {
  _validateUniqueIds(issues, 'weapon', weapons.map((item) => item.id));
  final weaponIds = weapons.map((item) => item.id).toSet();
  for (final weapon in weapons) {
    final entries = levels[weapon.id];
    if (weapon.maxLevel != 5 || entries?.length != weapon.maxLevel) {
      issues.add('Invalid weapon level coverage: ${weapon.id}');
      continue;
    }
    for (var index = 0; index < entries!.length; index += 1) {
      final level = entries[index];
      if (!level.damage.isFinite ||
          level.damage <= 0 ||
          !level.cooldownSeconds.isFinite ||
          level.cooldownSeconds <= 0 ||
          !level.range.isFinite ||
          level.range <= 0 ||
          level.projectileCount < 1 ||
          level.pierce < 0 ||
          level.chainCount < 0 ||
          !level.knockback.isFinite ||
          level.knockback < 0 ||
          !level.durationSeconds.isFinite ||
          level.durationSeconds < 0 ||
          !level.slowFraction.isFinite ||
          level.slowFraction < 0 ||
          level.slowFraction > 1) {
        issues.add('Invalid weapon tuning: ${weapon.id}/${index + 1}');
      }
    }
  }
  for (final id in levels.keys.where((id) => !weaponIds.contains(id))) {
    issues.add('Orphan weapon levels: $id');
  }
}

void _validateAugments(List<String> issues, List<AugmentDefinition> augments) {
  _validateUniqueIds(issues, 'augment', augments.map((item) => item.id));
  for (final augment in augments) {
    if (augment.maxLevel < 1 ||
        augment.effects.isEmpty ||
        augment.effects.any(
          (effect) =>
              !effect.valuePerLevel.isFinite || effect.valuePerLevel == 0,
        )) {
      issues.add('Invalid augment tuning: ${augment.id}');
    }
  }
}

void _validateStages(
  List<String> issues,
  List<StageDefinition> stages,
  Map<String, List<WaveDefinition>> stageWaves,
  List<BossDefinition> bosses,
) {
  final bossIds = bosses.map((item) => item.id).toSet();
  for (final stage in stages) {
    if (stage.targetSeconds <= 0 ||
        stage.bossArrivalSeconds <= 0 ||
        stage.bossArrivalSeconds >= stage.targetSeconds) {
      issues.add('Invalid stage timing: ${stage.id}');
    }
    final waves = stageWaves[stage.id];
    if (waves == null || waves.isEmpty) {
      issues.add('Missing stage waves: ${stage.id}');
    } else {
      final coverageEnd = waves.last.endSecond;
      if (coverageEnd < stage.bossArrivalSeconds) {
        issues.add('Wave coverage ends before boss arrival: ${stage.id}');
      }
      if (coverageEnd < stage.targetSeconds) {
        issues.add('Wave coverage ends before target: ${stage.id}');
      }
    }
    final plannedBossIds = ContentRosterContract.stageBossIds[stage.id];
    if (plannedBossIds == null || plannedBossIds.isEmpty) {
      issues.add('Missing stage boss contract: ${stage.id}');
    } else {
      for (final bossId in plannedBossIds) {
        if (!bossIds.contains(bossId)) {
          issues.add('Unknown stage boss: ${stage.id}/$bossId');
        }
      }
    }
  }
  for (final id in stageWaves.keys.where(
    (id) => !stages.any((stage) => stage.id == id),
  )) {
    issues.add('Orphan stage waves: $id');
  }
}

void _validateUnlocks(
  List<String> issues,
  List<UnlockGoalDefinition> goals,
  List<CharacterDefinition> characters,
  List<WeaponDefinition> weapons,
  List<AugmentDefinition> augments,
  List<StageDefinition> stages,
) {
  _validateUniqueIds(issues, 'unlock goal', goals.map((item) => item.id));
  final defaults = SaveState.defaults();
  final expected = <String>{
    ...characters
        .where((item) => !defaults.unlockedCharacterIds.contains(item.id))
        .map((item) => 'character:${item.id}'),
    ...weapons
        .where((item) => !defaults.unlockedWeaponIds.contains(item.id))
        .map((item) => 'weapon:${item.id}'),
    ...augments
        .where((item) => !defaults.unlockedAugmentIds.contains(item.id))
        .map((item) => 'augment:${item.id}'),
    ...stages
        .where((item) => !defaults.unlockedStageIds.contains(item.id))
        .map((item) => 'stage:${item.id}'),
  };
  final rewards = <String>[];
  for (final goal in goals) {
    if (goal.threshold <= 0 || goal.description.trim().isEmpty) {
      issues.add('Invalid unlock goal: ${goal.id}');
    }
    final rawRewards = <String>[
      if (goal.unlocksCharacterId case final id?) 'character:$id',
      if (goal.unlocksWeaponId case final id?) 'weapon:$id',
      if (goal.unlocksAugmentId case final id?) 'augment:$id',
      if (goal.unlocksStageId case final id?) 'stage:$id',
    ];
    if (rawRewards.length != 1) {
      issues.add(
        'Unlock goal reward count must be one: ${goal.id}/${rawRewards.length}',
      );
    }
    rewards.addAll(rawRewards);
  }
  final rewardSet = rewards.toSet();
  for (final reward in expected.where((item) => !rewardSet.contains(item))) {
    issues.add('Missing unlock reward: $reward');
  }
  for (final reward in rewardSet.where((item) => !expected.contains(item))) {
    issues.add('Unknown unlock reward: $reward');
  }
  final seen = <String>{};
  for (final reward in rewards) {
    if (!seen.add(reward)) issues.add('Duplicate unlock reward: $reward');
  }
}

void _validateAssets(
  List<String> issues, {
  required Iterable<String> expectedIds,
  required Map<String, String> assets,
  required String label,
  required Set<String> bundledPaths,
}) {
  for (final id in expectedIds) {
    final path = assets[id];
    if (path == null) {
      issues.add('Missing $label asset: $id');
      continue;
    }
    final normalized = path.replaceAll('\\', '/');
    if (!normalized.startsWith('assets/images/') ||
        normalized.contains('..') ||
        !JoseonArtStyle.hasApprovedSizeSuffix(normalized)) {
      issues.add('Invalid $label asset path: $id/$path');
    }
    if (bundledPaths.isNotEmpty && !bundledPaths.contains(normalized)) {
      issues.add('Unbundled $label asset: $id/$path');
    }
  }
  final expected = expectedIds.toSet();
  for (final id in assets.keys.where((id) => !expected.contains(id))) {
    issues.add('Orphan $label asset: $id');
  }
}

void _validateAudio(
  List<String> issues,
  Map<AudioCue, AudioAssetDefinition> assets,
) {
  for (final cue in AudioCue.values) {
    final asset = assets[cue];
    if (asset == null) {
      issues.add('Missing audio asset: ${cue.name}');
      continue;
    }
    final prefix = switch (AudioCueCatalog.channelFor(cue)) {
      AudioChannel.music => 'audio/music/',
      AudioChannel.sfx => 'audio/sfx/',
      AudioChannel.ui => 'audio/ui/',
    };
    if (!asset.path.startsWith(prefix) ||
        asset.path.contains('..') ||
        !asset.path.endsWith('.ogg')) {
      issues.add('Invalid audio path: ${cue.name}/${asset.path}');
    }
  }
}
