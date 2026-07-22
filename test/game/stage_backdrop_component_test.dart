import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/actor_shadow_component.dart';
import 'package:pixel_survivor/game/components/stage_backdrop_component.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/models/player_slot.dart';
import 'package:pixel_survivor/game/pixel_survivor_game.dart';

void main() {
  test('bright stage stays behind every combat actor', () {
    final backdrop = StageBackdropComponent();

    expect(backdrop.priority, -100);
    expect(backdrop.baseColor.computeLuminance(), greaterThan(.45));
    expect(backdrop.baseColor.r, greaterThan(backdrop.baseColor.g));
    expect(backdrop.baseColor.g, greaterThan(backdrop.baseColor.b));
    expect(backdrop.jadePatchColor.g, greaterThan(backdrop.jadePatchColor.r));
    expect(backdrop.jadePatchColor.g, greaterThan(backdrop.jadePatchColor.b));
    expect(backdrop.baseColor.r - backdrop.baseColor.g, greaterThan(.05));
    expect(
      (backdrop.baseColor.r - backdrop.jadePatchColor.r).abs() +
          (backdrop.baseColor.g - backdrop.jadePatchColor.g).abs() +
          (backdrop.baseColor.b - backdrop.jadePatchColor.b).abs(),
      greaterThan(.20),
    );
    expect(backdrop.ownsCollision, isFalse);
    expect(backdrop.cachedPaintCount, 4);
  });

  test('stage decorations are capped and deterministic for a viewport', () {
    final first = StageBackdropComponent(viewportSize: Vector2(390, 844));
    final second = StageBackdropComponent(viewportSize: Vector2(390, 844));

    expect(first.decorations, hasLength(lessThanOrEqualTo(40)));
    expect(first.decorations, second.decorations);
  });

  test('decorative stone lines remain quieter than combat warning lanes', () {
    final backdrop = StageBackdropComponent();

    expect(_stoneLineOpacity(backdrop), lessThanOrEqualTo(.2));
  });

  test('game fallback and stage share the warm hanji palette color', () {
    final backdrop = StageBackdropComponent();
    final game = PixelSurvivorGame(
      playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
      onRunEnded: null,
    );

    expect(backdrop.baseColor, warmHanjiBeige);
    expect(game.backgroundColor(), warmHanjiBeige);
  });

  test('actor shadow uses the supplied width at an actor ground anchor', () {
    final actor = PositionComponent(
      position: Vector2(60, 80),
      size: Vector2.all(24),
      anchor: Anchor.center,
    );
    final shadow = ActorShadowComponent(target: actor, width: 36);

    shadow.syncToTarget();

    expect(shadow.opacity, .18);
    expect(shadow.width, 36);
    expect(shadow.cachedPaintCount, 1);
    expect(shadow.size.y, closeTo(10.08, .0001));
    expect(shadow.position.x, 60);
    expect(shadow.position.y, 92);
  });
}

double _stoneLineOpacity(Object backdrop) {
  try {
    return (backdrop as dynamic).stoneLineOpacity as double;
  } on NoSuchMethodError {
    return 1;
  }
}
