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

      final leveledUp = progression.addExperience(10);

      expect(leveledUp, isFalse);
      expect(progression.level, 1);
      expect(progression.currentExperience, 10);
      expect(progression.experienceToNextLevel, 11);
    });

    test('levels up and carries overflow experience', () {
      final progression = RunProgressionSystem();

      final leveledUp = progression.addExperience(14);

      expect(leveledUp, isTrue);
      expect(progression.level, 2);
      expect(progression.currentExperience, 3);
      expect(progression.experienceToNextLevel, 13);
    });

    test('ignores zero and negative experience', () {
      final progression = RunProgressionSystem();

      expect(progression.addExperience(0), isFalse);
      expect(progression.addExperience(-1), isFalse);
      expect(progression.currentExperience, 0);
    });

    test('representative five-minute experience reaches nine upgrades', () {
      final system = RunProgressionSystem();
      var upgrades = 0;

      for (var index = 0; index < 177; index += 1) {
        if (system.addExperience(1)) upgrades += 1;
      }

      expect(system.experienceRequiredForLevel(1), 11);
      expect(system.experienceRequiredForLevel(10), 29);
      expect(upgrades, 9);
    });
  });
}
