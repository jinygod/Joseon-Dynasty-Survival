import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/systems/run_progression_system.dart';

void main() {
  group('RunProgressionSystem', () {
    test('starts at level 1 with a short first level target', () {
      final progression = RunProgressionSystem();

      expect(progression.level, 1);
      expect(progression.currentExperience, 0);
      expect(progression.experienceToNextLevel, 3);
    });

    test('adds experience without leveling when below the threshold', () {
      final progression = RunProgressionSystem();

      final leveledUp = progression.addExperience(2);

      expect(leveledUp, isFalse);
      expect(progression.level, 1);
      expect(progression.currentExperience, 2);
      expect(progression.experienceToNextLevel, 3);
    });

    test('levels up and carries overflow experience', () {
      final progression = RunProgressionSystem();

      final leveledUp = progression.addExperience(5);

      expect(leveledUp, isTrue);
      expect(progression.level, 2);
      expect(progression.currentExperience, 2);
      expect(progression.experienceToNextLevel, 5);
    });

    test('ignores zero and negative experience', () {
      final progression = RunProgressionSystem();

      expect(progression.addExperience(0), isFalse);
      expect(progression.addExperience(-1), isFalse);
      expect(progression.currentExperience, 0);
    });
  });
}
