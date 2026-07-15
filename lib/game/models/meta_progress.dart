import 'package:flutter/foundation.dart';

import '../content/meta_progress_definitions.dart';

@immutable
class Wallet {
  const Wallet({required this.coin, required this.spiritJade});

  static const empty = Wallet(coin: 0, spiritJade: 0);

  final int coin;
  final int spiritJade;

  factory Wallet.fromJson(Object? value) {
    if (value is! Map) return empty;
    return Wallet(
      coin: _nonNegativeInt(value['coin']),
      spiritJade: _nonNegativeInt(value['spiritJade']),
    );
  }

  Map<String, dynamic> toJson() => {'coin': coin, 'spiritJade': spiritJade};

  @override
  bool operator ==(Object other) =>
      other is Wallet && other.coin == coin && other.spiritJade == spiritJade;

  @override
  int get hashCode => Object.hash(coin, spiritJade);
}

@immutable
class TrainingProgress {
  const TrainingProgress({
    required this.commonRanks,
    required this.characterRanks,
    required this.activeCoreTraitIds,
  });

  static const empty = TrainingProgress(
    commonRanks: {},
    characterRanks: {},
    activeCoreTraitIds: {},
  );

  final Map<String, int> commonRanks;
  final Map<String, Map<String, int>> characterRanks;
  final Map<String, String> activeCoreTraitIds;

  factory TrainingProgress.fromJson(Object? value) {
    if (value is! Map) return empty;

    final commonRanks = _rankMap(
      value['commonRanks'],
      allowedIds: commonTrainingNodeIds,
    );
    final characterRanks = <String, Map<String, int>>{};
    final rawCharacterRanks = value['characterRanks'];
    if (rawCharacterRanks is Map) {
      for (final entry in rawCharacterRanks.entries) {
        final characterId = entry.key;
        if (characterId is! String ||
            !coreTraitIdsByCharacter.containsKey(characterId)) {
          continue;
        }
        characterRanks[characterId] = _rankMap(
          entry.value,
          allowedIds: characterTrainingNodeIds,
        );
      }
    }

    final activeTraits = <String, String>{};
    final rawActiveTraits = value['activeCoreTraitIds'];
    if (rawActiveTraits is Map) {
      for (final entry in rawActiveTraits.entries) {
        final characterId = entry.key;
        final traitId = entry.value;
        if (characterId is String &&
            traitId is String &&
            coreTraitIdsByCharacter[characterId]?.contains(traitId) == true) {
          activeTraits[characterId] = traitId;
        }
      }
    }

    if (commonRanks.isEmpty && characterRanks.isEmpty && activeTraits.isEmpty) {
      return empty;
    }
    return TrainingProgress(
      commonRanks: Map.unmodifiable(commonRanks),
      characterRanks: Map.unmodifiable(characterRanks),
      activeCoreTraitIds: Map.unmodifiable(activeTraits),
    );
  }

  Map<String, dynamic> toJson() => {
    'commonRanks': commonRanks,
    'characterRanks': characterRanks,
    'activeCoreTraitIds': activeCoreTraitIds,
  };

  @override
  bool operator ==(Object other) =>
      other is TrainingProgress &&
      mapEquals(other.commonRanks, commonRanks) &&
      _nestedMapEquals(other.characterRanks, characterRanks) &&
      mapEquals(other.activeCoreTraitIds, activeCoreTraitIds);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(commonRanks.entries),
    Object.hashAllUnordered(
      characterRanks.entries.map(
        (entry) => Object.hash(
          entry.key,
          Object.hashAllUnordered(entry.value.entries),
        ),
      ),
    ),
    Object.hashAllUnordered(activeCoreTraitIds.entries),
  );
}

@immutable
class ShopProgress {
  const ShopProgress({required this.purchasedItemIds});

  static const empty = ShopProgress(purchasedItemIds: {});

  final Set<String> purchasedItemIds;

  factory ShopProgress.fromJson(Object? value) {
    if (value is! Map || value['purchasedItemIds'] is! Iterable) return empty;
    final ids = (value['purchasedItemIds'] as Iterable)
        .whereType<String>()
        .toSet();
    return ids.isEmpty
        ? empty
        : ShopProgress(purchasedItemIds: Set.unmodifiable(ids));
  }

  Map<String, dynamic> toJson() => {
    'purchasedItemIds': purchasedItemIds.toList()..sort(),
  };

  @override
  bool operator ==(Object other) =>
      other is ShopProgress &&
      setEquals(other.purchasedItemIds, purchasedItemIds);

  @override
  int get hashCode => Object.hashAllUnordered(purchasedItemIds);
}

Map<String, int> _rankMap(Object? value, {required Set<String> allowedIds}) {
  if (value is! Map) return const {};
  final ranks = <String, int>{};
  for (final entry in value.entries) {
    final id = entry.key;
    final rank = entry.value;
    if (id is String && rank is int && rank >= 0 && allowedIds.contains(id)) {
      ranks[id] = rank;
    }
  }
  return ranks;
}

bool _nestedMapEquals(
  Map<String, Map<String, int>> left,
  Map<String, Map<String, int>> right,
) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (!mapEquals(entry.value, right[entry.key])) return false;
  }
  return true;
}

int _nonNegativeInt(Object? value) => value is int && value >= 0 ? value : 0;
