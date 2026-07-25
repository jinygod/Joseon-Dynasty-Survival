import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/projectile_contact.dart';
import 'package:pixel_survivor/game/combat/projectile_sweep_geometry.dart';

void main() {
  ProjectileContact contactAt(Vector2 hurtCenter) {
    return ProjectileSweepGeometry.firstContact(
      previousCenter: Vector2.zero(),
      currentCenter: Vector2(100, 0),
      direction: Vector2(1, 0),
      hitBodySize: Vector2(18, 6),
      hurtCenter: hurtCenter,
      hurtRadius: 8,
    )!;
  }

  test('finds the first contact when a fast frame crosses a target', () {
    final contact = contactAt(Vector2(50, 0));

    // The 9-unit front half of the visible body reaches the expanded
    // 11-unit hurt boundary after 30 units of a 100-unit frame.
    expect(contact.travelFraction, closeTo(.30, .0001));
    expect(contact.point.x, closeTo(42, .0001));
    expect(contact.point.y, closeTo(0, .0001));
    expect(contact.normal.x, closeTo(1, .0001));
    expect(contact.normal.y, closeTo(0, .0001));
  });

  test('does not hit a near target outside the swept thickness', () {
    final contact = ProjectileSweepGeometry.firstContact(
      previousCenter: Vector2.zero(),
      currentCenter: Vector2(100, 0),
      direction: Vector2(1, 0),
      hitBodySize: Vector2(18, 6),
      hurtCenter: Vector2(50, 12),
      hurtRadius: 8,
    );

    expect(contact, isNull);
  });

  test('stationary projectile checks its oriented body', () {
    final contact = ProjectileSweepGeometry.firstContact(
      previousCenter: Vector2.zero(),
      currentCenter: Vector2.zero(),
      direction: Vector2(1, 0),
      hitBodySize: Vector2(18, 6),
      hurtCenter: Vector2(14, 0),
      hurtRadius: 8,
    );

    expect(contact, isNotNull);
    expect(contact!.travelFraction, 0);
  });

  test('initial overlap normal points from projectile center to target', () {
    final contact = ProjectileSweepGeometry.firstContact(
      previousCenter: Vector2(5, 0),
      currentCenter: Vector2(5, 0),
      direction: Vector2.zero(),
      hitBodySize: Vector2(18, 6),
      hurtCenter: Vector2.zero(),
      hurtRadius: 8,
    );

    expect(contact, isNotNull);
    expect(contact!.normal.x, closeTo(-1, .0001));
    expect(contact.normal.y, closeTo(0, .0001));
  });

  test('contacts farther along the same sweep sort after nearer contacts', () {
    final near = contactAt(Vector2(30, 0));
    final far = contactAt(Vector2(70, 0));

    expect(near.travelFraction, lessThan(far.travelFraction));
  });

  test('returned contact vectors never alias caller-owned vectors', () {
    final hurtCenter = Vector2(50, 0);
    final contact = contactAt(hurtCenter);

    hurtCenter.setValues(999, 999);
    final point = contact.point;
    final normal = contact.normal;
    point.setValues(777, 777);
    normal.setValues(555, 555);

    expect(contact.point.x, closeTo(42, .0001));
    expect(contact.normal.x, closeTo(1, .0001));
  });

  test('non-finite geometry fails closed', () {
    expect(
      () => ProjectileSweepGeometry.firstContact(
        previousCenter: Vector2(double.nan, 0),
        currentCenter: Vector2(100, 0),
        direction: Vector2(1, 0),
        hitBodySize: Vector2(18, 6),
        hurtCenter: Vector2(50, 0),
        hurtRadius: 8,
      ),
      throwsArgumentError,
    );
  });
}
