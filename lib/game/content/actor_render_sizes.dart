import 'ids.dart';

abstract final class ActorRenderSizes {
  static const playerCollision = 24.0;
  static const playerVisual = 108.0;
  static const normalEnemyCollision = 18.0;
  static const normalEnemyVisual = 54.0;
  static const eliteEnemyCollision = 40.0;
  static const eliteEnemyVisual = 81.0;
  static const bossCollision = 42.0;
  static const bossVisual = 126.0;

  static double enemyCollisionSize(EnemyRank rank) => switch (rank) {
    EnemyRank.normal => normalEnemyCollision,
    EnemyRank.elite => eliteEnemyCollision,
    EnemyRank.boss => bossCollision,
  };

  static double enemyVisualSize(EnemyRank rank) => switch (rank) {
    EnemyRank.normal => normalEnemyVisual,
    EnemyRank.elite => eliteEnemyVisual,
    EnemyRank.boss => bossVisual,
  };

  static double enemyVisualScale(EnemyRank rank) =>
      enemyVisualSize(rank) / enemyCollisionSize(rank);
}
