import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/projectile_contact.dart';
import 'package:pixel_survivor/game/components/projectile_geometry_debug_component.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';

void main() {
  test('debug snapshot keeps exact projectile contact geometry', () {
    final debug = ProjectileGeometryDebugComponent(
      weaponId: singijeonVolley,
      previousCenter: Vector2.zero(),
      currentCenter: Vector2(100, 0),
      direction: Vector2(1, 0),
      visualBodySize: Vector2(25, 9),
      hitBodySize: Vector2(22.5, 8.1),
      hurtCenter: Vector2(50, 0),
      hurtRadius: 8.1,
      contact: ProjectileContact(
        travelFraction: .4,
        point: Vector2(41.9, 0),
        normal: Vector2(1, 0),
      ),
    );

    expect(debug.weaponId, singijeonVolley);
    expect(debug.hitBodySize.x, closeTo(debug.visualBodySize.x * .9, .0001));
    expect(debug.previousCenter, Vector2.zero());
    expect(debug.currentCenter, Vector2(100, 0));

    final callerCopy = debug.contact.point;
    callerCopy.setValues(999, 999);
    expect(debug.contact.point, Vector2(41.9, 0));
  });
}
