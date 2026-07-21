import 'ids.dart';
import 'weapon_definitions.dart';

class PlaytestContentPolicy {
  const PlaytestContentPolicy({required this.unlockAllBaseWeapons});

  final bool unlockAllBaseWeapons;

  Set<WeaponId> resolveWeaponIds(Iterable<WeaponId> normalIds) => {
    ...normalIds,
    if (unlockAllBaseWeapons)
      ...weaponDefinitions.map((definition) => definition.id),
  };
}
