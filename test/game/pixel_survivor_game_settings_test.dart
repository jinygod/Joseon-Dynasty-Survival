import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/damage_number_component.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';
import 'package:pixel_survivor/game/models/damage_event.dart';
import 'package:pixel_survivor/game/models/player_slot.dart';
import 'package:pixel_survivor/game/pixel_survivor_game.dart';

void main() {
  test('disabled feedback suppresses numbers and shake', () async {
    final game = PixelSurvivorGame(
      playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
      onRunEnded: null,
      damageNumbersEnabled: false,
      screenShakeEnabled: false,
    );
    game.onGameResize(Vector2(960, 540));
    await game.onLoad();
    final enemy = game.debugSpawnEnemy(
      plagueRatSwarm,
      position: Vector2(500, 270),
    );

      game.debugApplyDamageEvent(
        DamageEvent(
          target: enemy,
          damage: 5,
          knockback: 0,
          direction: Vector2.zero(),
        ),
      );
    game.debugStartScreenShake(4);
    game.update(0.02);
    await Future<void>.delayed(Duration.zero);

    expect(game.children.whereType<DamageNumberComponent>(), isEmpty);
    expect(game.screenShakeOffset, Vector2.zero());
  });
}
