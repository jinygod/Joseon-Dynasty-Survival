import 'character_definitions.dart';
import 'ids.dart';

abstract final class PlaytestRoster {
  static Set<CharacterId> get selectableCharacterIds =>
      characterDefinitions.map((definition) => definition.id).toSet();

  static Set<CharacterId> resolveUnlocked(
    Iterable<CharacterId> savedCharacterIds,
  ) => {...savedCharacterIds, ...selectableCharacterIds};
}
