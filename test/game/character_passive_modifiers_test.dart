import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/ids.dart';
import 'package:pixel_survivor/game/systems/character_passive_modifiers.dart';

void main() {
  test('passives resolve to exact neutral-safe modifiers', () {
    final neutral = CharacterPassiveModifiers.forPassive(CharacterPassive.none);
    final constable = CharacterPassiveModifiers.forPassive(
      CharacterPassive.patrolGrit,
    );
    final dosa = CharacterPassiveModifiers.forPassive(
      CharacterPassive.exorcismScript,
    );
    final hunter = CharacterPassiveModifiers.forPassive(
      CharacterPassive.hawkEye,
    );

    expect(neutral.incomingContactDamageMultiplier, 1);
    expect(neutral.magicDamageMultiplier, 1);
    expect(neutral.bonusCriticalChance, 0);
    expect(constable.incomingContactDamageMultiplier, 0.88);
    expect(dosa.magicDamageMultiplier, 1.15);
    expect(hunter.bonusCriticalChance, 0.10);
  });
}
