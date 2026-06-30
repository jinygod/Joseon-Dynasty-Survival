import '../content/enemy_definitions.dart';
import '../content/ids.dart';

class SpawnSystem {
  const SpawnSystem();

  static List<EnemyId> enemiesForSecond(int second) {
    final elapsedSecond = second < 0 ? 0 : second;

    if (elapsedSecond >= 300) {
      return const [fallenGeneral];
    }

    if (elapsedSecond >= 120) {
      return const [plagueRatSwarm, bandit, dokkaebi, vengefulSpirit];
    }

    if (elapsedSecond >= 60) {
      return const [plagueRatSwarm, bandit];
    }

    return const [plagueRatSwarm];
  }
}
