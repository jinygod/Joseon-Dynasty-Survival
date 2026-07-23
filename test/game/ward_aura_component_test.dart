import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/ward_aura_component.dart';
import 'package:pixel_survivor/game/content/combat_visual_factory.dart';

void main() {
  test('ward registry visual remains centered as its radius changes', () {
    var radius = 30.0;
    final ward = WardAuraComponent(
      positionProvider: Vector2.zero,
      radiusProvider: () => radius,
      visualFactory: const CombatVisualFactory(images: {}),
    );

    ward.update(0);
    expect(ward.registryVisualLocalPosition, Vector2(30, 30));
    expect(ward.registryVisualScale, Vector2.all(60 / 128));

    radius = 45;
    ward.update(0);
    expect(ward.registryVisualLocalPosition, Vector2(45, 45));
    expect(ward.registryVisualScale, Vector2.all(90 / 128));
  });
}
