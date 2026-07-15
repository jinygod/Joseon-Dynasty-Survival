import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../content/augment_definitions.dart';
import '../content/character_definitions.dart';
import '../content/playtest_roster.dart';
import '../content/stage_definitions.dart';
import '../content/weapon_definitions.dart';
import '../models/meta_progress.dart';

class SaveState {
  SaveState({
    this.schemaVersion = currentSchemaVersion,
    required Set<String> unlockedCharacterIds,
    required Set<String> unlockedWeaponIds,
    required Set<String> unlockedAugmentIds,
    required Set<String> completedGoalIds,
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
  }) : unlockedCharacterIds = Set.unmodifiable(unlockedCharacterIds),
       unlockedWeaponIds = Set.unmodifiable(unlockedWeaponIds),
       unlockedAugmentIds = Set.unmodifiable(unlockedAugmentIds),
       completedGoalIds = Set.unmodifiable(completedGoalIds);

  static const currentSchemaVersion = 2;

  factory SaveState.defaults() {
    final startingWeaponIds = weaponDefinitions
        .where((weapon) => weapon.startsUnlocked)
        .map((weapon) => weapon.id)
        .toSet();

    return SaveState(
      unlockedCharacterIds: PlaytestRoster.resolveUnlocked({rookieConstable}),
      unlockedWeaponIds: startingWeaponIds,
      unlockedAugmentIds: augmentDefinitions
          .where((augment) => augment.startsUnlocked)
          .map((augment) => augment.id)
          .toSet(),
      completedGoalIds: const {},
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
    final unlockedCharacterIds = _stringSet(
      json['unlockedCharacterIds'],
      fallback: defaults.unlockedCharacterIds,
    );
    final selectedCharacterId = _validSelectedCharacter(
      json['selectedCharacterId'],
      unlockedCharacterIds,
      defaults.selectedCharacterId,
    );
    final selectedStageId = _validSelectedStage(
      json['selectedStageId'],
      defaults.selectedStageId,
    );
    return SaveState(
      schemaVersion: currentSchemaVersion,
      unlockedCharacterIds: unlockedCharacterIds,
      unlockedWeaponIds: _stringSet(
        json['unlockedWeaponIds'],
        fallback: defaults.unlockedWeaponIds,
      ),
      unlockedAugmentIds: _stringSet(
        json['unlockedAugmentIds'],
        fallback: defaults.unlockedAugmentIds,
      ),
      completedGoalIds: _stringSet(json['completedGoalIds']),
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
    );
  }

  final int schemaVersion;
  final Set<String> unlockedCharacterIds;
  final Set<String> unlockedWeaponIds;
  final Set<String> unlockedAugmentIds;
  final Set<String> completedGoalIds;
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

  SaveState copyWith({
    int? schemaVersion,
    Set<String>? unlockedCharacterIds,
    Set<String>? unlockedWeaponIds,
    Set<String>? unlockedAugmentIds,
    Set<String>? completedGoalIds,
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
  }) {
    return SaveState(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      unlockedCharacterIds:
          unlockedCharacterIds ?? Set<String>.of(this.unlockedCharacterIds),
      unlockedWeaponIds:
          unlockedWeaponIds ?? Set<String>.of(this.unlockedWeaponIds),
      unlockedAugmentIds:
          unlockedAugmentIds ?? Set<String>.of(this.unlockedAugmentIds),
      completedGoalIds:
          completedGoalIds ?? Set<String>.of(this.completedGoalIds),
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'unlockedCharacterIds': _sorted(unlockedCharacterIds),
      'unlockedWeaponIds': _sorted(unlockedWeaponIds),
      'unlockedAugmentIds': _sorted(unlockedAugmentIds),
      'completedGoalIds': _sorted(completedGoalIds),
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

  static int _intValue(Object? value, {int fallback = 0}) {
    if (value is int && value >= 0) {
      return value;
    }

    return fallback;
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

  static String _validSelectedStage(Object? value, String fallback) {
    if (value is String && stageDefinitions.any((stage) => stage.id == value)) {
      return value;
    }
    return fallback;
  }
}

class SaveSystem {
  SaveSystem({this.preferences});

  static const _saveStateKey = 'save_state';

  final SharedPreferences? preferences;

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

  Future<void> save(SaveState state) async {
    final activePreferences =
        preferences ?? await SharedPreferences.getInstance();
    await activePreferences.setString(
      _saveStateKey,
      jsonEncode(state.toJson()),
    );
  }
}
