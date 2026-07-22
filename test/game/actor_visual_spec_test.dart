import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/actor_render_sizes.dart';
import 'package:pixel_survivor/game/content/actor_visual_spec.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';

void main() {
  test('representative actor sizes preserve compact casual proportions', () {
    expect(playerVisualSpecFor(exorcistDosa).visualSize, 56);
    expect(enemyVisualSpecFor(plagueRatSwarm).visualSize, 32);
    expect(enemyVisualSpecFor(vengefulSpirit).visualSize, 40);
    expect(enemyVisualSpecFor(sakkatSpecter).visualSize, 40);
    expect(enemyVisualSpecFor(dokkaebi).visualSize, 44);
    expect(ActorRenderSizes.playerCollision, 24);
    expect(ActorRenderSizes.normalEnemyCollision, 18);
  });

  test('non-representative actors keep the established rank-based sizes', () {
    final player = playerVisualSpecFor(rookieConstable);
    final enemy = enemyVisualSpecFor(bandit);

    expect(player.visualSize, ActorRenderSizes.playerVisual);
    expect(enemy.visualSize, ActorRenderSizes.normalEnemyVisual);
    expect(player.groundOffsetY, greaterThan(0));
    expect(enemy.shadowWidth, greaterThan(0));
  });

  test('unrepresented and unknown actors use documented safe fallbacks', () {
    expect(
      playerVisualSpecFor(mountainHunter).visualSize,
      ActorRenderSizes.playerVisual,
    );
    expect(
      playerVisualSpecFor('unknown_character').visualSize,
      ActorRenderSizes.playerVisual,
    );
    expect(
      enemyVisualSpecFor(blackHatAssassin).visualSize,
      ActorRenderSizes.eliteEnemyVisual,
    );
    expect(
      enemyVisualSpecFor(fallenGeneral).visualSize,
      ActorRenderSizes.bossVisual,
    );
    expect(
      enemyVisualSpecFor('unknown_enemy').visualSize,
      ActorRenderSizes.normalEnemyVisual,
    );
  });
}
