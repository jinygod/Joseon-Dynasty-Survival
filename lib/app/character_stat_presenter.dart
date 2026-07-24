import '../game/content/character_definitions.dart';
import '../game/content/ids.dart';
import '../game/content/weapon_level_definitions.dart';

class CharacterDisplayStats {
  const CharacterDisplayStats({
    required this.health,
    required this.attack,
    required this.moveSpeed,
  });

  final int health;
  final int attack;
  final int moveSpeed;
}

CharacterDisplayStats characterDisplayStats(CharacterDefinition character) {
  return CharacterDisplayStats(
    health: character.maxHealth.round(),
    attack:
        (weaponLevels[character.startingWeaponId]!.first.damage *
                character.damageMultiplier)
            .round(),
    moveSpeed: character.moveSpeed.round(),
  );
}
