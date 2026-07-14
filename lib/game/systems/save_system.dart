import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../content/augment_definitions.dart';
import '../content/character_definitions.dart';
import '../content/weapon_definitions.dart';

class SaveState {
  SaveState({
    this.schemaVersion = currentSchemaVersion,
    required Set<String> unlockedCharacterIds,
    required Set<String> unlockedWeaponIds,
    required Set<String> unlockedAugmentIds,
    required Set<String> completedGoalIds,
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

  static const currentSchemaVersion = 1;

  factory SaveState.defaults() {
    final startingWeaponIds = weaponDefinitions
        .where((weapon) => weapon.startsUnlocked)
        .map((weapon) => weapon.id)
        .toSet();

    return SaveState(
      unlockedCharacterIds: {rookieConstable},
      unlockedWeaponIds: startingWeaponIds,
      unlockedAugmentIds: augmentDefinitions
          .where((augment) => augment.startsUnlocked)
          .map((augment) => augment.id)
          .toSet(),
      completedGoalIds: const {},
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
    return SaveState(
      schemaVersion: currentSchemaVersion,
      unlockedCharacterIds: _stringSet(
        json['unlockedCharacterIds'],
        fallback: defaults.unlockedCharacterIds,
      ),
      unlockedWeaponIds: _stringSet(
        json['unlockedWeaponIds'],
        fallback: defaults.unlockedWeaponIds,
      ),
      unlockedAugmentIds: _stringSet(
        json['unlockedAugmentIds'],
        fallback: defaults.unlockedAugmentIds,
      ),
      completedGoalIds: _stringSet(json['completedGoalIds']),
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
    if (value is int) {
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
