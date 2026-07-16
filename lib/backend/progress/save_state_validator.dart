import '../../game/content/augment_definitions.dart';
import '../../game/content/character_definitions.dart';
import '../../game/content/meta_progress_definitions.dart';
import '../../game/content/stage_definitions.dart';
import '../../game/content/unlock_definitions.dart';
import '../../game/content/weapon_definitions.dart';
import '../../game/systems/save_system.dart';

class SaveStateValidator {
  static const maxCounter = 1000000000;
  static const maxRank = 100;
  static const maxDynamicIdLength = 128;
  static const maxClaimedRewardIds = 10000;
  static final _dynamicIdPattern = RegExp(r'^[A-Za-z0-9._:-]+$');

  static const _allowedTopLevelKeys = {
    'schemaVersion',
    'unlockedCharacterIds',
    'unlockedWeaponIds',
    'unlockedAugmentIds',
    'unlockedStageIds',
    'completedGoalIds',
    'claimedRewardIds',
    'wallet',
    'trainingProgress',
    'shopProgress',
    'selectedCharacterId',
    'selectedStageId',
    'totalKills',
    'bestSurvivalSeconds',
    'levelReachedInRun',
    'bossDefeats',
    'unlockedWeaponCount',
    'lowHealthWinCount',
    'totalEliteKills',
    'victoryCount',
    'characterVictoryCounts',
    'seenCompendiumEntryIds',
  };

  void validate(SaveState save) => validateJson(save.toJson());

  void validateJson(Map<String, dynamic> json) {
    final unknownKeys = json.keys.toSet().difference(_allowedTopLevelKeys);
    if (unknownKeys.isNotEmpty) {
      throw FormatException(
        'Unsupported save fields: ${unknownKeys.join(', ')}',
      );
    }
    if (json['schemaVersion'] != SaveState.currentSchemaVersion) {
      throw const FormatException('Unsupported save schema version');
    }

    _knownIds(
      json['unlockedCharacterIds'],
      characterDefinitions.map((item) => item.id).toSet(),
      'character',
    );
    _knownIds(
      json['unlockedWeaponIds'],
      weaponDefinitions.map((item) => item.id).toSet(),
      'weapon',
    );
    _knownIds(
      json['unlockedAugmentIds'],
      augmentDefinitions.map((item) => item.id).toSet(),
      'augment',
    );
    _knownIds(
      json['unlockedStageIds'],
      stageDefinitions.map((item) => item.id).toSet(),
      'stage',
    );
    _knownIds(
      json['completedGoalIds'],
      unlockGoals.map((item) => item.id).toSet(),
      'goal',
    );
    _knownValue(
      json['selectedCharacterId'],
      characterDefinitions.map((item) => item.id).toSet(),
      'selected character',
    );
    _knownValue(
      json['selectedStageId'],
      stageDefinitions.map((item) => item.id).toSet(),
      'selected stage',
    );
    _validateWallet(json['wallet']);
    _validateTraining(json['trainingProgress']);
    _validateShop(json['shopProgress']);
    _validateClaimedRewards(json['claimedRewardIds']);
    _validateCharacterCounts(json['characterVictoryCounts']);
    _validateCompendium(json['seenCompendiumEntryIds']);
    for (final key in const [
      'totalKills',
      'bestSurvivalSeconds',
      'levelReachedInRun',
      'bossDefeats',
      'unlockedWeaponCount',
      'lowHealthWinCount',
      'totalEliteKills',
      'victoryCount',
    ]) {
      final value = json[key];
      _boundedInt(value, key, maxCounter);
    }
  }

  void _validateWallet(Object? value) {
    if (value is! Map || !_hasExactKeys(value, const {'coin', 'spiritJade'})) {
      throw const FormatException(
        'Save wallet contains paid or unknown fields',
      );
    }
    for (final key in const ['coin', 'spiritJade']) {
      _boundedInt(value[key], key, maxCounter);
    }
  }

  void _validateTraining(Object? value) {
    if (value is! Map ||
        !_hasExactKeys(value, const {
          'commonRanks',
          'characterRanks',
          'activeCoreTraitIds',
        })) {
      throw const FormatException('Invalid training progress');
    }
    final common = value['commonRanks'];
    if (common is! Map ||
        common.keys.any((key) => !commonTrainingNodeIds.contains(key))) {
      throw const FormatException('Unknown common training node');
    }
    _validateRanks(common);
    final characters = value['characterRanks'];
    if (characters is! Map ||
        characters.keys.any(
          (key) => !coreTraitIdsByCharacter.containsKey(key),
        )) {
      throw const FormatException('Unknown character training entry');
    }
    for (final ranks in characters.values) {
      if (ranks is! Map ||
          ranks.keys.any((key) => !characterTrainingNodeIds.contains(key))) {
        throw const FormatException('Unknown character training node');
      }
      _validateRanks(ranks);
    }
    final traits = value['activeCoreTraitIds'];
    if (traits is! Map) throw const FormatException('Invalid active traits');
    for (final entry in traits.entries) {
      if (entry.key is! String ||
          entry.value is! String ||
          coreTraitIdsByCharacter[entry.key]?.contains(entry.value) != true) {
        throw const FormatException('Unknown active core trait');
      }
    }
  }

  void _validateShop(Object? value) {
    if (value is! Map || !_hasExactKeys(value, const {'purchasedItemIds'})) {
      throw const FormatException('Invalid shop progress');
    }
    _knownIds(value['purchasedItemIds'], oneTimeShopItemIds, 'shop item');
  }

  void _validateCharacterCounts(Object? value) {
    if (value is! Map) throw const FormatException('Invalid victory counts');
    final known = characterDefinitions.map((item) => item.id).toSet();
    for (final entry in value.entries) {
      if (!known.contains(entry.key) ||
          entry.value is! int ||
          (entry.value as int) < 0 ||
          (entry.value as int) > maxCounter) {
        throw const FormatException('Invalid character victory count');
      }
    }
  }

  void _validateClaimedRewards(Object? value) {
    if (value is! Iterable) {
      throw const FormatException('Invalid claimed reward IDs');
    }
    final ids = value.toList();
    if (ids.length > maxClaimedRewardIds || ids.toSet().length != ids.length) {
      throw const FormatException('Invalid claimed reward ID count');
    }
    for (final id in ids) {
      if (id is! String ||
          id.isEmpty ||
          id.length > maxDynamicIdLength ||
          !_dynamicIdPattern.hasMatch(id)) {
        throw const FormatException('Invalid claimed reward ID');
      }
    }
  }

  void _validateRanks(Map ranks) {
    for (final value in ranks.values) {
      _boundedInt(value, 'training rank', maxRank);
    }
  }

  void _boundedInt(Object? value, String label, int maximum) {
    if (value is! int || value < 0 || value > maximum) {
      throw FormatException('$label must be between 0 and $maximum');
    }
  }

  bool _hasExactKeys(Map value, Set<String> expected) {
    final keys = value.keys.toSet();
    return keys.length == expected.length && keys.containsAll(expected);
  }

  void _validateCompendium(Object? value) {
    final known = <String>{
      ...characterDefinitions.map((item) => 'character:${item.id}'),
      ...weaponDefinitions.map((item) => 'weapon:${item.id}'),
      ...augmentDefinitions.map((item) => 'augment:${item.id}'),
    };
    _knownIds(value, known, 'compendium entry');
  }

  void _knownIds(Object? value, Set<String> known, String label) {
    if (value is! Iterable ||
        value.any((id) => id is! String || !known.contains(id))) {
      throw FormatException('Unknown $label ID');
    }
  }

  void _knownValue(Object? value, Set<String> known, String label) {
    if (value is! String || !known.contains(value)) {
      throw FormatException('Unknown $label ID');
    }
  }
}
