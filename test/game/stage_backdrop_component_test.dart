import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/actor_shadow_component.dart';
import 'package:pixel_survivor/game/components/stage_backdrop_component.dart';

void main() {
  test('bright stage stays behind every combat actor', () {
    final backdrop = StageBackdropComponent();

    expect(backdrop.priority, -100);
    expect(backdrop.baseColor.computeLuminance(), greaterThan(.45));
    expect(backdrop.ownsCollision, isFalse);
  });

  test('stage decorations are capped and deterministic for a viewport', () {
    final first = StageBackdropComponent(viewportSize: Vector2(390, 844));
    final second = StageBackdropComponent(viewportSize: Vector2(390, 844));

    expect(first.decorations, hasLength(lessThanOrEqualTo(40)));
    expect(first.decorations, second.decorations);
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
    expect(shadow.size.y, closeTo(10.08, .0001));
    expect(shadow.position.x, 60);
    expect(shadow.position.y, 92);
  });
}
