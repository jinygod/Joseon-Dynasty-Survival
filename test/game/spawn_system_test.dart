import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';
import 'package:pixel_survivor/game/systems/spawn_system.dart';

void main() {
  group('SpawnSystem.enemiesForSecond', () {
    test('returns only plague rat swarm at 0 seconds', () {
      expect(SpawnSystem.enemiesForSecond(0), [plagueRatSwarm]);
    });

    test('includes bandit at 60 seconds', () {
      expect(SpawnSystem.enemiesForSecond(60), [plagueRatSwarm, bandit]);
    });

    test('includes dokkaebi and vengeful spirit at 120 seconds', () {
      expect(SpawnSystem.enemiesForSecond(120), [
        plagueRatSwarm,
        bandit,
        dokkaebi,
        vengefulSpirit,
      ]);
    });

    test('returns only fallen general at 300 seconds', () {
      expect(SpawnSystem.enemiesForSecond(300), [fallenGeneral]);
    });

    test('treats negative seconds as 0 seconds', () {
      expect(SpawnSystem.enemiesForSecond(-1), [plagueRatSwarm]);
    });
  });
}
