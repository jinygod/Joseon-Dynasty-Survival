import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/actor_render_sizes.dart';
import 'package:pixel_survivor/game/content/ids.dart';

void main() {
  test(
    'approved actor visual sizes preserve collision sizes and hierarchy',
    () {
      expect(ActorRenderSizes.playerCollision, 24);
      expect(ActorRenderSizes.playerVisual, 108);
      expect(ActorRenderSizes.enemyCollisionSize(EnemyRank.normal), 18);
      expect(ActorRenderSizes.enemyVisualSize(EnemyRank.normal), 54);
      expect(ActorRenderSizes.enemyCollisionSize(EnemyRank.elite), 40);
      expect(ActorRenderSizes.enemyVisualSize(EnemyRank.elite), 81);
      expect(ActorRenderSizes.enemyCollisionSize(EnemyRank.boss), 42);
      expect(ActorRenderSizes.enemyVisualSize(EnemyRank.boss), 126);
      expect(
        ActorRenderSizes.eliteEnemyVisual / ActorRenderSizes.normalEnemyVisual,
        1.5,
      );
      expect(
        ActorRenderSizes.bossVisual / ActorRenderSizes.normalEnemyVisual,
        closeTo(2.333333, 0.00001),
      );
    },
  );
}
