import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/models/combat_playtest_metrics.dart';
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
      expect(metrics.firstMasterAtSeconds, {hwandoSlash: 190.0});
      expect(metrics.masteredWeaponIds, {hwandoSlash});
    });

    test('master achievement time does not start the post-use kill window', () {
      final tracker = CombatPlaytestTracker()
        ..recordLevel(weaponId: hwandoSlash, level: 6, atSeconds: 190)
        ..recordKill(
          atSeconds: 195,
          sourceId: hwandoSlash,
          enemyBehaviorId: 'swarm',
        )
        ..recordMasterActivation(weaponId: hwandoSlash, atSeconds: 200)
        ..recordKill(
          atSeconds: 209,
          sourceId: hwandoSlash,
          enemyBehaviorId: 'swarm',
        );

      final metrics = tracker.snapshot();
      expect(metrics.firstMasterAtSeconds, {hwandoSlash: 190.0});
      expect(metrics.masteredWeaponIds, {hwandoSlash});
      expect(metrics.masterKillsInTenSeconds, {hwandoSlash: 1});
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
        ..recordFrame(dt: 0.05, enemyCount: 10, atSeconds: 179)
        ..recordFrame(dt: 0.02, enemyCount: 20, atSeconds: 180)
        ..recordFrame(dt: 0.04, enemyCount: 30, atSeconds: 190);

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

    test('metrics defensively copy every caller-owned collection', () {
      final offers = <String, int>{hwandoSlash: 1};
      final selections = <String, int>{hwandoSlash: 1};
      final levelTwo = <int, double>{2: 10};
      final levelTimes = <String, Map<int, double>>{hwandoSlash: levelTwo};
      final firstMaster = <String, double>{hwandoSlash: 20};
      final masterKills = <String, int>{hwandoSlash: 3};
      final firstSynergy = <String, double>{sealingSlash: 30};
      final synergyDamage = <String, double>{sealingSlash: 40};
      final roleDamage = <String, double>{'swarm': 5};
      final deathCauses = <String, int>{'tank': 1};
      final mastered = <String>{hwandoSlash};
      final metrics = CombatPlaytestMetrics(
        weaponOfferCounts: offers,
        weaponSelectionCounts: selections,
        weaponLevelTimes: levelTimes,
        firstMasterAtSeconds: firstMaster,
        masterKillsInTenSeconds: masterKills,
        firstSynergyAtSeconds: firstSynergy,
        synergyDamageTotals: synergyDamage,
        enemyRoleDamageToPlayer: roleDamage,
        enemyRoleDeathCauses: deathCauses,
        averageEnemyCount: 1,
        maxEnemyCount: 2,
        lateAverageFps: 60,
        lateMinFps: 30,
        masteredWeaponIds: mastered,
        isRepeatRun: false,
      );

      offers.clear();
      selections.clear();
      levelTwo.clear();
      levelTimes.clear();
      firstMaster.clear();
      masterKills.clear();
      firstSynergy.clear();
      synergyDamage.clear();
      roleDamage.clear();
      deathCauses.clear();
      mastered.clear();

      expect(metrics.weaponOfferCounts, {hwandoSlash: 1});
      expect(metrics.weaponSelectionCounts, {hwandoSlash: 1});
      expect(metrics.weaponLevelTimes, {
        hwandoSlash: {2: 10},
      });
      expect(metrics.firstMasterAtSeconds, {hwandoSlash: 20});
      expect(metrics.masterKillsInTenSeconds, {hwandoSlash: 3});
      expect(metrics.firstSynergyAtSeconds, {sealingSlash: 30});
      expect(metrics.synergyDamageTotals, {sealingSlash: 40});
      expect(metrics.enemyRoleDamageToPlayer, {'swarm': 5});
      expect(metrics.enemyRoleDeathCauses, {'tank': 1});
      expect(metrics.masteredWeaponIds, {hwandoSlash});
    });

    test('records repeat-run state in every snapshot', () {
      final metrics = CombatPlaytestTracker(isRepeatRun: true).snapshot();

      expect(metrics.isRepeatRun, isTrue);
    });
  });
}
