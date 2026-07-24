import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/world/experience_gem_coordinator.dart';

void main() {
  test('merge compress restore preserves exact experience total', () {
    final coordinator = ExperienceGemCoordinator.test(maxActiveGems: 3);
    coordinator.drop(5, Vector2(100, 100));
    coordinator.drop(7, Vector2(104, 102));
    coordinator.drop(11, Vector2(1800, 4800));
    final before = coordinator.totalOwnedExperience;

    coordinator.mergeNearby();
    coordinator.compressOutside(const Rect.fromLTWH(0, 0, 500, 500));
    coordinator.restoreNear(const Rect.fromLTWH(1500, 4500, 500, 500));

    expect(coordinator.totalOwnedExperience, before);
    expect(
      coordinator.activeRecords.fold<int>(
        coordinator.compressedExperience,
        (total, record) => total + record.value,
      ),
      before,
    );
  });

  test('active cap compresses overflow without changing total', () {
    final coordinator = ExperienceGemCoordinator.test(maxActiveGems: 2);
    coordinator.drop(2, Vector2(100, 100));
    coordinator.drop(3, Vector2(200, 100));
    coordinator.drop(5, Vector2(300, 100));

    expect(coordinator.activeRecords, hasLength(2));
    expect(coordinator.compressedExperience, 5);
    expect(coordinator.totalOwnedExperience, 10);
  });

  test('magnetized gems continue to occupy the active component cap', () {
    final coordinator = ExperienceGemCoordinator.test(maxActiveGems: 2);
    final first = coordinator.drop(2, Vector2(100, 100))!;
    coordinator.drop(3, Vector2(200, 100));
    coordinator.beginPickup(first.id);

    expect(coordinator.drop(5, Vector2(300, 100)), isNull);
    expect(coordinator.ownedComponentCount, 2);
    expect(coordinator.compressedExperience, 5);
  });

  test('consume token grants experience once', () {
    final token = ExperiencePickupToken(recordId: 9, value: 17);

    expect(token.consume(), 17);
    expect(token.consume(), 0);
  });

  test('pickup transfers ownership exactly once', () {
    final coordinator = ExperienceGemCoordinator.test(maxActiveGems: 3);
    final record = coordinator.drop(17, Vector2(100, 100))!;
    final token = coordinator.beginPickup(record.id)!;

    expect(coordinator.completePickup(token), 17);
    expect(coordinator.completePickup(token), 0);
    expect(coordinator.totalOwnedExperience, 17);
    expect(coordinator.grantedExperience, 17);
  });

  test('cancelled pickup returns ownership without granting', () {
    final coordinator = ExperienceGemCoordinator.test(maxActiveGems: 3);
    final record = coordinator.drop(17, Vector2(100, 100))!;
    final token = coordinator.beginPickup(record.id)!;

    final restored = coordinator.cancelPickup(token, Vector2(120, 100));

    expect(restored?.value, 17);
    expect(coordinator.activeRecords, hasLength(1));
    expect(coordinator.grantedExperience, 0);
    expect(coordinator.totalOwnedExperience, 17);
    expect(token.consume(), 0);
  });
}
