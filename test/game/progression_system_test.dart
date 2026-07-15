import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/augment_definitions.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/systems/progression_system.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';

void main() {
  test('unlocks talisman throw after surviving 180 seconds', () {
    final save = SaveState.defaults().copyWith(bestSurvivalSeconds: 180);

    final evaluated = const ProgressionSystem().evaluate(save);

    expect(evaluated.unlockedWeaponIds, contains(talismanThrow));
    expect(evaluated.completedGoalIds, contains('survive_3_minutes'));
  });

  test('unlocks exorcist dosa after one boss defeat', () {
    final save = SaveState.defaults().copyWith(bossDefeats: 1);

    final evaluated = const ProgressionSystem().evaluate(save);

    expect(evaluated.unlockedCharacterIds, contains(exorcistDosa));
    expect(evaluated.completedGoalIds, contains('defeat_fallen_general'));
  });

  test('unlocks frost flask after two boss defeats', () {
    final evaluated = const ProgressionSystem().evaluate(
      SaveState.defaults().copyWith(bossDefeats: 2),
    );

    expect(evaluated.unlockedWeaponIds, contains(frostFlask));
    expect(evaluated.completedGoalIds, contains('defeat_two_bosses'));
  });

  test('unlocks wind thunder fan after six weapons are unlocked', () {
    final evaluated = const ProgressionSystem().evaluate(
      SaveState.defaults().copyWith(
        unlockedWeaponIds: {
          hwandoSlash,
          gakgungShot,
          talismanThrow,
          thunderCrashBomb,
          jangseungWard,
          singijeonVolley,
        },
        unlockedWeaponCount: 6,
      ),
    );

    expect(evaluated.unlockedWeaponIds, contains(windThunderFan));
    expect(evaluated.completedGoalIds, contains('unlock_six_weapons'));
  });

  test('repeated evaluation does not duplicate or remove unlocks', () {
    final save = SaveState.defaults().copyWith(
      bestSurvivalSeconds: 180,
      unlockedWeaponIds: {hwandoSlash, gakgungShot, thunderCrashBomb},
      unlockedAugmentIds: {martialTraining, quickStep, heavyStrike},
    );

    const system = ProgressionSystem();
    final once = system.evaluate(save);
    final twice = system.evaluate(once);

    expect(twice.unlockedWeaponIds, once.unlockedWeaponIds);
    expect(twice.unlockedAugmentIds, once.unlockedAugmentIds);
    expect(twice.unlockedCharacterIds, once.unlockedCharacterIds);
    expect(twice.completedGoalIds, once.completedGoalIds);
    expect(twice.unlockedWeaponIds, contains(thunderCrashBomb));
    expect(twice.unlockedAugmentIds, contains(heavyStrike));
  });
}
