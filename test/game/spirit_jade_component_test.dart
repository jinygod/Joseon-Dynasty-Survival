import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/spirit_jade_component.dart';

void main() {
  test('pickup remains available after persistence fails', () async {
    var attempts = 0;
    var collected = 0;
    final jade = SpiritJadeComponent(
      pickup: const SpiritJadePickup(
        pickupId: 'jade-1',
        claimsFirstBossReward: false,
      ),
      persistPickup: (_) async => ++attempts > 1,
      onCollected: () => collected += 1,
      isBossDrop: false,
      position: Vector2.zero(),
    );

    expect(await jade.tryCollect(), isFalse);
    expect(collected, 0);
    jade.update(1);
    expect(await jade.tryCollect(), isTrue);
    expect(attempts, 2);
    expect(collected, 1);
  });

  test('concurrent collision attempts make one persistence request', () async {
    var attempts = 0;
    final jade = SpiritJadeComponent(
      pickup: const SpiritJadePickup(
        pickupId: 'jade-2',
        claimsFirstBossReward: true,
      ),
      persistPickup: (_) async {
        attempts += 1;
        await Future<void>.delayed(Duration.zero);
        return true;
      },
      onCollected: () {},
      isBossDrop: true,
    );

    await Future.wait([jade.tryCollect(), jade.tryCollect()]);

    expect(attempts, 1);
  });
}
