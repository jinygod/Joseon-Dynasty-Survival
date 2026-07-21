import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/systems/combat_playtest_tracker.dart';
import 'package:pixel_survivor/game/systems/weapon_synergy_resolver.dart';

void main() {
  group('CombatPlaytestTracker', () {
    test(
      'master activation counts kills only inside following ten seconds',
      () {
        final tracker = CombatPlaytestTracker();

        tracker.recordMasterActivation(weaponId: hwandoSlash, atSeconds: 200);
        tracker.recordKill(
          atSeconds: 209,
          sourceId: hwandoSlash,
          enemyBehaviorId: 'swarm',
        );
        tracker.recordKill(
          atSeconds: 211,
          sourceId: hwandoSlash,
          enemyBehaviorId: 'tank',
        );

        expect(tracker.snapshot().masterKillsInTenSeconds[hwandoSlash], 1);
      },
    );

    test('records offers selections level times and mastery once', () {
      final tracker = CombatPlaytestTracker();

      tracker
        ..recordOffer(weaponId: hwandoSlash)
        ..recordOffer(weaponId: hwandoSlash)
        ..recordLevel(weaponId: hwandoSlash, level: 2, atSeconds: 20)
        ..recordLevel(weaponId: hwandoSlash, level: 6, atSeconds: 190)
        ..recordMasterActivation(weaponId: hwandoSlash, atSeconds: 191)
        ..recordMasterActivation(weaponId: hwandoSlash, atSeconds: 195);

      final metrics = tracker.snapshot();
      expect(metrics.weaponOfferCounts, {hwandoSlash: 2});
      expect(metrics.weaponSelectionCounts, {hwandoSlash: 2});
      expect(metrics.weaponLevelTimes, {
        hwandoSlash: {2: 20.0, 6: 190.0},
      });
      expect(metrics.firstMasterAtSeconds, {hwandoSlash: 191.0});
      expect(metrics.masteredWeaponIds, {hwandoSlash});
    });

    test('records synergy timing and effective damage totals', () {
      final tracker = CombatPlaytestTracker()
        ..recordSynergyDamage(
          synergyId: sealingSlash,
          amount: 12,
          atSeconds: 50,
        )
        ..recordSynergyDamage(
          synergyId: sealingSlash,
          amount: 8,
          atSeconds: 60,
        );

      final metrics = tracker.snapshot();
      expect(metrics.firstSynergyAtSeconds, {sealingSlash: 50.0});
      expect(metrics.synergyDamageTotals, {sealingSlash: 20.0});
    });

    test('records enemy role damage and lethal role cause', () {
      final tracker = CombatPlaytestTracker()
        ..recordEnemyDamage(enemyBehaviorId: 'swarm', amount: 4)
        ..recordEnemyDamage(enemyBehaviorId: 'swarm', amount: 6)
        ..recordEnemyDeath(enemyBehaviorId: 'tank');

      final metrics = tracker.snapshot();
      expect(metrics.enemyRoleDamageToPlayer, {'swarm': 10.0});
      expect(metrics.enemyRoleDeathCauses, {'tank': 1});
    });

    test('records density and raw late frame FPS', () {
      final tracker = CombatPlaytestTracker()
        ..recordFrame(dt: 0.05, enemyCount: 10, atSeconds: 239)
        ..recordFrame(dt: 0.02, enemyCount: 20, atSeconds: 240)
        ..recordFrame(dt: 0.04, enemyCount: 30, atSeconds: 250);

      final metrics = tracker.snapshot();
      expect(metrics.averageEnemyCount, 20);
      expect(metrics.maxEnemyCount, 30);
      expect(metrics.lateAverageFps, 37.5);
      expect(metrics.lateMinFps, 25);
    });

    test('snapshot collections cannot be mutated', () {
      final metrics =
          (CombatPlaytestTracker()
                ..recordLevel(weaponId: hwandoSlash, level: 2, atSeconds: 10))
              .snapshot();

      expect(
        () => metrics.weaponSelectionCounts[hwandoSlash] = 99,
        throwsUnsupportedError,
      );
      expect(
        () => metrics.weaponLevelTimes[hwandoSlash]![2] = 99,
        throwsUnsupportedError,
      );
      expect(
        () => metrics.masteredWeaponIds.add(talismanThrow),
        throwsUnsupportedError,
      );
    });

    test('records repeat-run state in every snapshot', () {
      final metrics = CombatPlaytestTracker(isRepeatRun: true).snapshot();

      expect(metrics.isRepeatRun, isTrue);
    });
  });
}
