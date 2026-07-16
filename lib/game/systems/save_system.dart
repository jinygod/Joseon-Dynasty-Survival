import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../content/augment_definitions.dart';
import '../content/character_definitions.dart';
import '../content/stage_definitions.dart';
import '../content/unlock_definitions.dart';
import '../content/weapon_definitions.dart';
import '../models/meta_progress.dart';

class SaveState {
  SaveState({
    this.schemaVersion = currentSchemaVersion,
    required Set<String> unlockedCharacterIds,
    required Set<String> unlockedWeaponIds,
    required Set<String> unlockedAugmentIds,
    Set<String> unlockedStageIds = const {moonlitAbandonedOffice},
    required Set<String> completedGoalIds,
    Set<String> claimedRewardIds = const {},
    required this.wallet,
    required this.trainingProgress,
    required this.shopProgress,
    required this.selectedCharacterId,
    required this.selectedStageId,
    required this.totalKills,
    required this.bestSurvivalSeconds,
    required this.levelReachedInRun,
    required this.bossDefeats,
    required this.unlockedWeaponCount,
    required this.lowHealthWinCount,
    this.totalEliteKills = 0,
    this.victoryCount = 0,
    Map<String, int> characterVictoryCounts = const {},
    Set<String> seenCompendiumEntryIds = const {},
  }) : unlockedCharacterIds = Set.unmodifiable(unlockedCharacterIds),
       unlockedWeaponIds = Set.unmodifiable(unlockedWeaponIds),
       unlockedAugmentIds = Set.unmodifiable(unlockedAugmentIds),
       unlockedStageIds = Set.unmodifiable(unlockedStageIds),
       completedGoalIds = Set.unmodifiable(completedGoalIds),
       claimedRewardIds = Set.unmodifiable(claimedRewardIds),
       characterVictoryCounts = Map.unmodifiable(characterVictoryCounts),
       seenCompendiumEntryIds = Set.unmodifiable(seenCompendiumEntryIds);

  static const currentSchemaVersion = 3;

  factory SaveState.defaults() {
    final startingWeaponIds = weaponDefinitions
        .where((weapon) => weapon.startsUnlocked)
        .map((weapon) => weapon.id)
        .toSet();

    return SaveState(
      unlockedCharacterIds: const {rookieConstable},
      unlockedWeaponIds: startingWeaponIds,
      unlockedAugmentIds: augmentDefinitions
          .where((augment) => augment.startsUnlocked)
          .map((augment) => augment.id)
          .toSet(),
      unlockedStageIds: const {moonlitAbandonedOffice},
      completedGoalIds: const {},
      claimedRewardIds: const {},
      wallet: Wallet.empty,
      trainingProgress: TrainingProgress.empty,
      shopProgress: ShopProgress.empty,
      selectedCharacterId: rookieConstable,
      selectedStageId: stageDefinitions.first.id,
      totalKills: 0,
      bestSurvivalSeconds: 0,
      levelReachedInRun: 0,
      bossDefeats: 0,
      unlockedWeaponCount: startingWeaponIds.length,
      lowHealthWinCount: 0,
      totalEliteKills: 0,
      victoryCount: 0,
      characterVictoryCounts: const {},
      seenCompendiumEntryIds: const {},
    );
  }

  factory SaveState.fromJson(Map<String, dynamic> json) {
    final rawSchemaVersion = json['schemaVersion'];
    final schemaVersion = rawSchemaVersion ?? 0;
    if (schemaVersion is! int ||
        schemaVersion < 0 ||
        schemaVersion > currentSchemaVersion) {
      return SaveState.defaults();
    }

    return _fromSupportedJson(json);
  }

  static SaveState _fromSupportedJson(Map<String, dynamic> json) {
    final defaults = SaveState.defaults();
    final unlockedCharacterIds = _knownStringSet(
      json['unlockedCharacterIds'],
      characterDefinitions.map((definition) => definition.id),
      fallback: defaults.unlockedCharacterIds,
    );
    final unlockedStageIds = _knownStringSet(
      json['unlockedStageIds'],
      stageDefinitions.map((definition) => definition.id),
      fallback: defaults.unlockedStageIds,
    );
    final selectedCharacterId = _validSelectedCharacter(
      json['selectedCharacterId'],
      unlockedCharacterIds,
      defaults.selectedCharacterId,
    );
    final selectedStageId = _validSelectedStage(
      json['selectedStageId'],
      unlockedStageIds,
      defaults.selectedStageId,
    );
    return SaveState(
      schemaVersion: currentSchemaVersion,
      unlockedCharacterIds: unlockedCharacterIds,
      unlockedWeaponIds: _knownStringSet(
        json['unlockedWeaponIds'],
        weaponDefinitions.map((definition) => definition.id),
        fallback: defaults.unlockedWeaponIds,
      ),
      unlockedAugmentIds: _knownStringSet(
        json['unlockedAugmentIds'],
        augmentDefinitions.map((definition) => definition.id),
        fallback: defaults.unlockedAugmentIds,
      ),
      unlockedStageIds: unlockedStageIds,
      completedGoalIds: _knownStringSet(
        json['completedGoalIds'],
        unlockGoals.map((goal) => goal.id),
      ),
      claimedRewardIds: _stringSet(json['claimedRewardIds']),
      wallet: Wallet.fromJson(json['wallet']),
      trainingProgress: TrainingProgress.fromJson(json['trainingProgress']),
      shopProgress: ShopProgress.fromJson(json['shopProgress']),
      selectedCharacterId: selectedCharacterId,
      selectedStageId: selectedStageId,
      totalKills: _intValue(json['totalKills']),
      bestSurvivalSeconds: _intValue(json['bestSurvivalSeconds']),
      levelReachedInRun: _intValue(json['levelReachedInRun']),
      bossDefeats: _intValue(json['bossDefeats']),
      unlockedWeaponCount: _intValue(
        json['unlockedWeaponCount'],
        fallback: defaults.unlockedWeaponCount,
      ),
      lowHealthWinCount: _intValue(json['lowHealthWinCount']),
      totalEliteKills: _intValue(json['totalEliteKills']),
      victoryCount: _intValue(json['victoryCount']),
      characterVictoryCounts: _knownCountMap(
        json['characterVictoryCounts'],
        characterDefinitions.map((definition) => definition.id),
      ),
      seenCompendiumEntryIds: _knownCompendiumEntrySet(
        json['seenCompendiumEntryIds'],
      ),
    );
  }

  final int schemaVersion;
  final Set<String> unlockedCharacterIds;
  final Set<String> unlockedWeaponIds;
  final Set<String> unlockedAugmentIds;
  final Set<String> unlockedStageIds;
  final Set<String> completedGoalIds;
  final Set<String> claimedRewardIds;
  final Wallet wallet;
  final TrainingProgress trainingProgress;
  final ShopProgress shopProgress;
  final String selectedCharacterId;
  final String selectedStageId;
  final int totalKills;
  final int bestSurvivalSeconds;
  final int levelReachedInRun;
  final int bossDefeats;
  final int unlockedWeaponCount;
  final int lowHealthWinCount;
  final int totalEliteKills;
  final int victoryCount;
  final Map<String, int> characterVictoryCounts;
  final Set<String> seenCompendiumEntryIds;

  SaveState copyWith({
    int? schemaVersion,
    Set<String>? unlockedCharacterIds,
    Set<String>? unlockedWeaponIds,
    Set<String>? unlockedAugmentIds,
    Set<String>? unlockedStageIds,
    Set<String>? completedGoalIds,
    Set<String>? claimedRewardIds,
    Wallet? wallet,
    TrainingProgress? trainingProgress,
    ShopProgress? shopProgress,
    String? selectedCharacterId,
    String? selectedStageId,
    int? totalKills,
    int? bestSurvivalSeconds,
    int? levelReachedInRun,
    int? bossDefeats,
    int? unlockedWeaponCount,
    int? lowHealthWinCount,
    int? totalEliteKills,
    int? victoryCount,
    Map<String, int>? characterVictoryCounts,
    Set<String>? seenCompendiumEntryIds,
  }) {
    return SaveState(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      unlockedCharacterIds:
          unlockedCharacterIds ?? Set<String>.of(this.unlockedCharacterIds),
      unlockedWeaponIds:
          unlockedWeaponIds ?? Set<String>.of(this.unlockedWeaponIds),
      unlockedAugmentIds:
          unlockedAugmentIds ?? Set<String>.of(this.unlockedAugmentIds),
      unlockedStageIds:
          unlockedStageIds ?? Set<String>.of(this.unlockedStageIds),
      completedGoalIds:
          completedGoalIds ?? Set<String>.of(this.completedGoalIds),
      claimedRewardIds:
          claimedRewardIds ?? Set<String>.of(this.claimedRewardIds),
      wallet: wallet ?? this.wallet,
      trainingProgress: trainingProgress ?? this.trainingProgress,
      shopProgress: shopProgress ?? this.shopProgress,
      selectedCharacterId: selectedCharacterId ?? this.selectedCharacterId,
      selectedStageId: selectedStageId ?? this.selectedStageId,
      totalKills: totalKills ?? this.totalKills,
      bestSurvivalSeconds: bestSurvivalSeconds ?? this.bestSurvivalSeconds,
      levelReachedInRun: levelReachedInRun ?? this.levelReachedInRun,
      bossDefeats: bossDefeats ?? this.bossDefeats,
      unlockedWeaponCount: unlockedWeaponCount ?? this.unlockedWeaponCount,
      lowHealthWinCount: lowHealthWinCount ?? this.lowHealthWinCount,
      totalEliteKills: totalEliteKills ?? this.totalEliteKills,
      victoryCount: victoryCount ?? this.victoryCount,
      characterVictoryCounts:
          characterVictoryCounts ??
          Map<String, int>.of(this.characterVictoryCounts),
      seenCompendiumEntryIds:
          seenCompendiumEntryIds ?? Set<String>.of(this.seenCompendiumEntryIds),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'unlockedCharacterIds': _sorted(unlockedCharacterIds),
      'unlockedWeaponIds': _sorted(unlockedWeaponIds),
      'unlockedAugmentIds': _sorted(unlockedAugmentIds),
      'unlockedStageIds': _sorted(unlockedStageIds),
      'completedGoalIds': _sorted(completedGoalIds),
      'claimedRewardIds': _sorted(claimedRewardIds),
      'wallet': wallet.toJson(),
      'trainingProgress': trainingProgress.toJson(),
      'shopProgress': shopProgress.toJson(),
      'selectedCharacterId': selectedCharacterId,
      'selectedStageId': selectedStageId,
      'totalKills': totalKills,
      'bestSurvivalSeconds': bestSurvivalSeconds,
      'levelReachedInRun': levelReachedInRun,
      'bossDefeats': bossDefeats,
      'unlockedWeaponCount': unlockedWeaponCount,
      'lowHealthWinCount': lowHealthWinCount,
      'totalEliteKills': totalEliteKills,
      'victoryCount': victoryCount,
      'characterVictoryCounts': characterVictoryCounts,
      'seenCompendiumEntryIds': _sorted(seenCompendiumEntryIds),
    };
  }

  static List<String> _sorted(Set<String> values) {
    return values.toList()..sort();
  }

  static Set<String> _stringSet(
    Object? value, {
    Set<String> fallback = const {},
  }) {
    if (value is Iterable) {
      return {...fallback, ...value.whereType<String>()};
    }

    return fallback;
  }

  static Set<String> _knownStringSet(
    Object? value,
    Iterable<String> knownIds, {
    Set<String> fallback = const {},
  }) {
    final known = knownIds.toSet();
    if (value is! Iterable) return fallback;
    return {...fallback, ...value.whereType<String>().where(known.contains)};
  }

  static int _intValue(Object? value, {int fallback = 0}) {
    if (value is int && value >= 0) {
      return value;
    }

    return fallback;
  }

  static Map<String, int> _knownCountMap(
    Object? value,
    Iterable<String> knownIds,
  ) {
    if (value is! Map) return const {};
    final known = knownIds.toSet();
    final result = <String, int>{};
    for (final entry in value.entries) {
      if (entry.key is String &&
          known.contains(entry.key) &&
          entry.value is int &&
          (entry.value as int) >= 0) {
        result[entry.key as String] = entry.value as int;
      }
    }
    return result;
  }

  static Set<String> _knownCompendiumEntrySet(Object? value) {
    if (value is! Iterable) return const {};
    final known = <String>{
      ...characterDefinitions.map((item) => 'character:${item.id}'),
      ...weaponDefinitions.map((item) => 'weapon:${item.id}'),
      ...augmentDefinitions.map((item) => 'augment:${item.id}'),
    };
    return value.whereType<String>().where(known.contains).toSet();
  }

  static String _validSelectedCharacter(
    Object? value,
    Set<String> unlockedCharacterIds,
    String fallback,
  ) {
    if (value is String &&
        unlockedCharacterIds.contains(value) &&
        characterDefinitions.any((character) => character.id == value)) {
      return value;
    }
    return fallback;
  }

  static String _validSelectedStage(
    Object? value,
    Set<String> unlockedStageIds,
    String fallback,
  ) {
    if (value is String &&
        unlockedStageIds.contains(value) &&
        stageDefinitions.any((stage) => stage.id == value)) {
      return value;
    }
    return fallback;
  }
}

abstract interface class SaveStore {
  Future<SaveState> load();

  Future<void> save(SaveState state);
}

class SaveSystem implements SaveStore {
  SaveSystem({this.preferences});

  static const _saveStateKey = 'save_state';

  final SharedPreferences? preferences;

  @override
  Future<SaveState> load() async {
    final activePreferences =
        preferences ?? await SharedPreferences.getInstance();
    final rawSave = activePreferences.getString(_saveStateKey);

    if (rawSave == null) {
      return SaveState.defaults();
    }

    try {
      final decoded = jsonDecode(rawSave);
      if (decoded is Map<String, dynamic>) {
        return SaveState.fromJson(decoded);
      }
    } on FormatException {
      return SaveState.defaults();
    }

    return SaveState.defaults();
  }

  @override
  Future<void> save(SaveState state) async {
    final activePreferences =
        preferences ?? await SharedPreferences.getInstance();
    final saved = await activePreferences.setString(
      _saveStateKey,
      jsonEncode(state.toJson()),
    );
    if (!saved) {
      throw StateError('Failed to persist save state');
    }
  }
}
