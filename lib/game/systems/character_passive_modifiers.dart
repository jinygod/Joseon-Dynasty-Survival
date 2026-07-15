import '../content/ids.dart';

class CharacterPassiveModifiers {
  const CharacterPassiveModifiers({
    this.incomingContactDamageMultiplier = 1,
    this.magicDamageMultiplier = 1,
    this.bonusCriticalChance = 0,
  });

  final double incomingContactDamageMultiplier;
  final double magicDamageMultiplier;
  final double bonusCriticalChance;

  static CharacterPassiveModifiers forPassive(CharacterPassive passive) {
    return switch (passive) {
      CharacterPassive.patrolGrit => const CharacterPassiveModifiers(
        incomingContactDamageMultiplier: 0.88,
      ),
      CharacterPassive.exorcismScript => const CharacterPassiveModifiers(
        magicDamageMultiplier: 1.15,
      ),
      CharacterPassive.hawkEye => const CharacterPassiveModifiers(
        bonusCriticalChance: 0.10,
      ),
      CharacterPassive.none => const CharacterPassiveModifiers(),
    };
  }
}
