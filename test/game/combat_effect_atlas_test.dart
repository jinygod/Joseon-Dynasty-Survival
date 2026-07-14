import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/combat_effect_component.dart';
import 'package:pixel_survivor/game/content/combat_effect_atlas.dart';

void main() {
  test('atlas assigns five feedback meanings to distinct rows', () {
    expect(CombatEffectAtlas.rowFor(CombatEffectKind.experience), 0);
    expect(CombatEffectAtlas.rowFor(CombatEffectKind.hit), 1);
    expect(CombatEffectAtlas.rowFor(CombatEffectKind.critical), 2);
    expect(CombatEffectAtlas.rowFor(CombatEffectKind.death), 3);
    expect(CombatEffectAtlas.rowFor(CombatEffectKind.warning), 4);
  });

  test('combat effect expires exactly once after its lifetime', () {
    var expirations = 0;
    final effect = CombatEffectComponent(
      kind: CombatEffectKind.hit,
      position: Vector2.zero(),
      onExpired: () => expirations += 1,
    );

    effect.update(0.31);
    expect(effect.isExpired, isFalse);
    effect.update(0.01);
    effect.update(1);

    expect(effect.isExpired, isTrue);
    expect(expirations, 1);
  });
}
