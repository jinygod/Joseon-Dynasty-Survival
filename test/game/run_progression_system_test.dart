import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/systems/run_progression_system.dart';

void main() {
  group('RunProgressionSystem', () {
    test('starts at level 1 with a short first level target', () {
      final progression = RunProgressionSystem();

      expect(progression.level, 1);
      expect(progression.currentExperience, 0);
      expect(progression.experienceToNextLevel, 11);
    });

    test('adds experience without leveling when below the threshold', () {
      final progression = RunProgressionSystem();

      final result = progression.addExperience(10);

      expect(result.leveledUp, isFalse);
      expect(result.levelsGained, 0);
      expect(progression.level, 1);
      expect(progression.currentExperience, 10);
      expect(progression.experienceToNextLevel, 11);
    });

    test('levels up and carries overflow experience', () {
      final progression = RunProgressionSystem();

      final result = progression.addExperience(14);

      expect(result.leveledUp, isTrue);
      expect(result.levelsGained, 1);
      expect(progression.level, 2);
      expect(progression.currentExperience, 3);
      expect(progression.experienceToNextLevel, 13);
    });

    test('ignores zero and negative experience', () {
      final progression = RunProgressionSystem();

      expect(progression.addExperience(0).leveledUp, isFalse);
      expect(progression.addExperience(-1).leveledUp, isFalse);
      expect(progression.currentExperience, 0);
    });

    test('fractional gain bonuses accumulate without rounding each pickup', () {
      final progression = RunProgressionSystem();

      progression.addExperience(5, gainMultiplier: 1.1);
      progression.addExperience(5, gainMultiplier: 1.1);

      expect(progression.level, 2);
      expect(progression.currentExperience, 0);
    });

    test('floating-point threshold leaves zero public experience', () {
      final progression = RunProgressionSystem();

      for (var pickup = 0; pickup < 10; pickup += 1) {
        progression.addExperience(1, gainMultiplier: 1.1);
      }

      expect(progression.level, 2);
      expect(progression.currentExperience, 0);
    });

    test(
      'requirement multiplier applies only when positive experience arrives',
      () {
        final progression = RunProgressionSystem()..addExperience(9);

        expect(progression.level, 1);
        expect(progression.experienceRequiredForLevel(1, multiplier: 0.85), 10);
        expect(
          progression.addExperience(0, requirementMultiplier: 0.85).leveledUp,
          isFalse,
        );
        expect(
          progression.addExperience(1, requirementMultiplier: 0.85).leveledUp,
          isTrue,
        );
      },
    );

    test('representative five-minute experience reaches nine upgrades', () {
      final system = RunProgressionSystem();
      var upgrades = 0;

      for (var index = 0; index < 177; index += 1) {
        upgrades += system.addExperience(1).levelsGained;
      }

      expect(system.experienceRequiredForLevel(1), 11);
      expect(system.experienceRequiredForLevel(10), 29);
      expect(upgrades, 9);
    });

    test('reports every level crossed by one experience collection', () {
      final progression = RunProgressionSystem();

      final result = progression.addExperience(24);

      expect(result.levelsGained, 2);
      expect(result.leveledUp, isTrue);
      expect(progression.level, 3);
      expect(progression.currentExperience, 0);
      expect(progression.experienceToNextLevel, 15);
    });
  });
}
