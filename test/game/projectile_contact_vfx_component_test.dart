import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/projectile_contact_vfx_component.dart';

void main() {
  test('projectile contact effect owns six frames and expires once', () {
    var expirations = 0;
    final effect = ProjectileContactVfxComponent.withoutImageForTesting(
      position: Vector2(30, 40),
      direction: Vector2(0, 1),
      onExpired: () => expirations += 1,
    );

    expect(effect.position, Vector2(30, 40));
    expect(effect.frameCount, 6);
    expect(effect.facingAngle, closeTo(1.57079632679, .000001));

    effect.update(ProjectileContactVfxComponent.lifetime);
    effect.update(1);

    expect(effect.isExpired, isTrue);
    expect(expirations, 1);
  });
}
