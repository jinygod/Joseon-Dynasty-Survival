import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/experience_gem_component.dart';
import 'package:pixel_survivor/game/world/experience_gem_coordinator.dart';

void main() {
  test(
    'pickup completes inside the authored duration and returns one token',
    () {
      final completed = <ExperiencePickupToken>[];
      final gem = ExperienceGemComponent(
        experienceValue: 7,
        position: Vector2.zero(),
        ledgerRecordId: 3,
      );
      final token = ExperiencePickupToken(recordId: 3, value: 7);

      expect(
        gem.beginPickup(
          targetPosition: () => Vector2(100, 0),
          token: token,
          onComplete: completed.add,
        ),
        isTrue,
      );
      expect(
        ExperienceGemComponent.pickupDurationSeconds,
        inInclusiveRange(.18, .30),
      );

      for (var index = 0; index < 5; index++) {
        gem.update(.05);
      }

      expect(gem.state, ExperienceGemState.released);
      expect(completed, [token]);
    },
  );

  test('magnet travel accelerates before the orbit phase', () {
    final gem = ExperienceGemComponent(
      experienceValue: 3,
      position: Vector2.zero(),
      ledgerRecordId: 4,
    );
    gem.beginPickup(
      targetPosition: () => Vector2(100, 0),
      token: ExperiencePickupToken(recordId: 4, value: 3),
      onComplete: (_) {},
    );

    final distances = <double>[];
    var previous = gem.position.clone();
    for (var index = 0; index < 4; index++) {
      gem.update(.02);
      distances.add(gem.position.distanceTo(previous));
      previous = gem.position.clone();
    }

    expect(distances[1], greaterThan(distances[0]));
    expect(distances[2], greaterThan(distances[1]));
    expect(
      ExperienceGemComponent.orbitSweepRadians,
      inInclusiveRange(1.57, 3.15),
    );
  });

  test('reset clears pickup state for safe reuse', () {
    final gem = ExperienceGemComponent(experienceValue: 3, ledgerRecordId: 4);
    gem.beginPickup(
      targetPosition: () => Vector2(20, 0),
      token: ExperiencePickupToken(recordId: 4, value: 3),
      onComplete: (_) {},
    );
    gem.update(.12);

    gem.resetForReuse(
      experienceValue: 9,
      position: Vector2(30, 40),
      ledgerRecordId: 8,
    );

    expect(gem.state, ExperienceGemState.idle);
    expect(gem.experienceValue, 9);
    expect(gem.position, Vector2(30, 40));
    expect(gem.presentationOpacity, 1);
    expect(gem.presentationScale, 1);
  });
}
