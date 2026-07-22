import 'character_definitions.dart';
import 'ids.dart';
import 'stage_definitions.dart';
import 'weapon_definitions.dart';

/// Permanent access policy for the complete, non-premium base roster.
abstract final class BaseContentPolicy {
  static Set<CharacterId> get characterIds =>
      Set.unmodifiable(characterDefinitions.map((definition) => definition.id));

  static Set<WeaponId> get weaponIds =>
      Set.unmodifiable(weaponDefinitions.map((definition) => definition.id));

  static Set<String> get stageIds =>
      Set.unmodifiable(stageDefinitions.map((definition) => definition.id));

  static Set<T> includeBase<T>(Iterable<T> saved, Iterable<T> base) =>
      Set.unmodifiable({...saved, ...base});
}
