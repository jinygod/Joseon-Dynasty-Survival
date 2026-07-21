import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/components/boss_component.dart';
import 'package:pixel_survivor/game/components/experience_gem_component.dart';
import 'package:pixel_survivor/game/game_performance_budget.dart';
import 'package:pixel_survivor/game/models/player_slot.dart';
import 'package:pixel_survivor/game/performance/performance_development_log.dart';
import 'package:pixel_survivor/game/performance/performance_development_reporter.dart';
import 'package:pixel_survivor/game/pixel_survivor_game.dart';
import 'package:pixel_survivor/game/systems/wave_director.dart';

void main() {
  test('late FPS uses raw frame duration instead of clamped combat step', () {
    const budget = GamePerformanceBudget.standard;
    final collector = PerformanceDevelopmentCollector(
      budget: budget,
      maxMemoryProxyComponents: 10,
      maxRetainedOwners: 5,
    );
    for (final rawFrameDurationMicros in [100000, 20000]) {
      collector.record(
        PerformanceDevelopmentSample(
          simulatedSeconds: 200,
          frameStepMicros: 50000,
          rawFrameDurationMicros: rawFrameDurationMicros,
          hostUpdateLifecycleWallMicros: 1,
          mountedComponentCount: 1,
          retainedOwnerCount: 1,
          snapshot: GamePerformanceSnapshot(
            budget: budget,
            counts: const {GamePopulationKind.enemy: 1},
          ),
        ),
      );
    }

    final log = collector.finish(
      scenario: 'raw-frame-duration',
      seed: 1,
      simulatedDurationSeconds: 200,
      totalFrameCount: 2,
    );

    expect(log.lateAverageSimulatedFps, 30);
    expect(log.lateMinimumSimulatedFps, 10);
  });

  test('production wave admission covers 18000 logical frames', () {
    const frameCount = 18000;
    const dt = 1 / 60;
    final director = WaveDirector(random: Random(3107));
    var activeEnemies = 0;
    var requestedEnemies = 0;
    var rejectedEnemies = 0;
    for (var frame = 1; frame <= frameCount; frame += 1) {
      final pressure = director.tick(
        elapsedSeconds: frame * dt,
        dt: dt,
        activeEnemyCount: activeEnemies,
      );
      requestedEnemies += pressure.spawnRequests.length;
      final admitted = GamePerformanceBudget.standard.admitCount(
        GamePopulationKind.enemy,
        current: activeEnemies,
        requested: pressure.spawnRequests.length,
        secondaryAvailable: pressure.maxActiveEnemies - activeEnemies,
      );
      activeEnemies += admitted;
      rejectedEnemies += pressure.spawnRequests.length - admitted;
    }

    expect(requestedEnemies, greaterThan(0));
    expect(activeEnemies, greaterThan(0));
    expect(activeEnemies, lessThanOrEqualTo(96));
    expect(rejectedEnemies, 0);
  });

  testWidgets(
    'production game logs an actual five-minute lifecycle window',
    (tester) async {
      const seed = 3107;
      const frameCount = 18000;
      const frameStepSeconds = 1 / 60;
      const frameStepMicros = 16667;
      const observationIntervalFrames = 1;
      final game = PixelSurvivorGame(
        playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
        onRunEnded: null,
        random: Random(seed),
        rewardRoll: () => .99,
        bossRoll: () => .5,
        loadVisualAssets: false,
      );
      await tester.pumpWidget(
        SizedBox(
          width: 1280,
          height: 720,
          child: GameWidget(
            game: game,
            overlayBuilderMap: {
              PixelSurvivorGame.levelUpOverlayId: (_, _) =>
                  const SizedBox.shrink(),
            },
          ),
        ),
      );
      await tester.pump();
      game.processLifecycleEvents();
      final player = game.activePlayers.single;
      expect(player.isMounted, isTrue);
      player
        ..maxHealth = 1000000000
        ..currentHealth = 1000000000;
      game.unlockedWeaponIds.addAll({hwandoSlash, gakgungShot});
      for (var level = 0; level < 5; level += 1) {
        game.weaponSystem
          ..upgrade(hwandoSlash, game.unlockedWeaponIds)
          ..upgrade(gakgungShot, game.unlockedWeaponIds);
      }

      final collector = PerformanceDevelopmentCollector(
        budget: GamePerformanceBudget.standard,
        maxMemoryProxyComponents: 512,
        maxRetainedOwners: 128,
      );

      for (var frame = 1; frame <= frameCount; frame += 1) {
        if (game.isLevelUpPending) {
          game.applyLevelUpChoice(game.pendingLevelUpChoices.first);
        }
        final stopwatch = Stopwatch()..start();
        game.update(frameStepSeconds);
        game.processLifecycleEvents();
        for (final boss in game.children.whereType<BossComponent>()) {
          boss.currentHealth = 1000000000;
        }
        stopwatch.stop();
        if (frame % observationIntervalFrames != 0) continue;
        final mountedComponentCount = game
            .descendants(includeSelf: true)
            .where((component) => component.isMounted)
            .length;
        collector.record(
          PerformanceDevelopmentSample(
            simulatedSeconds: frame * frameStepSeconds,
            frameStepMicros: frameStepMicros,
            rawFrameDurationMicros: frameStepMicros,
            hostUpdateLifecycleWallMicros: stopwatch.elapsedMicroseconds,
            mountedComponentCount: mountedComponentCount,
            retainedOwnerCount: game.performanceRetainedOwnerCount,
            snapshot: game.performanceSnapshot,
          ),
        );
      }

      final log = collector.finish(
        scenario: 'pixel-survivor-production-update-five-minute-window',
        seed: seed,
        simulatedDurationSeconds: 300,
        totalFrameCount: frameCount,
      );
      final artifacts = PerformanceDevelopmentReporter.toArtifactBundle(log);
      final output = Directory('build/qa')..createSync(recursive: true);
      for (final entry in artifacts.entries) {
        File('${output.path}/${entry.key}').writeAsStringSync(entry.value);
      }

      expect(game.elapsedSeconds, closeTo(300, 0.001));
      expect(log.sampleCount, frameCount ~/ observationIntervalFrames);
      expect(log.peakFrameStepMicros, frameStepMicros);
      expect(log.averageActiveEnemies, closeTo(15.68288888888889, 1e-12));
      expect(log.maximumActiveEnemies, 51);
      expect(log.lateFrameSampleCount, 7200);
      expect(log.lateAverageActiveEnemies, inInclusiveRange(27, 28));
      expect(log.lateMaximumActiveEnemies, 51);
      expect(
        log.lateAverageSimulatedFps,
        closeTo(1000000 / frameStepMicros, 1e-9),
      );
      expect(
        log.lateMinimumSimulatedFps,
        closeTo(1000000 / frameStepMicros, 1e-12),
      );
      expect(log.peakMountedComponentCount, 262);
      expect(log.peakRetainedOwnerCount, 13);
      expect(log.peakMemoryProxyComponents, 272);
      for (final kind in GamePopulationKind.values) {
        expect(log.peakCounts[kind], greaterThan(0), reason: kind.name);
        expect(
          log.peakCounts[kind],
          lessThanOrEqualTo(GamePerformanceBudget.standard.limitFor(kind)),
          reason: kind.name,
        );
      }
      expect(log.peakCounts, {
        GamePopulationKind.enemy: 51,
        GamePopulationKind.projectile: 14,
        GamePopulationKind.damageNumber: 24,
        GamePopulationKind.combatEffect: 23,
      });
      expect(log.isWithinPopulationBudget, isTrue);
      expect(log.isWithinMemoryProxyBudget, isTrue);
      expect(log.isWithinLateFrameBudget, isTrue);
      expect(
        game.children.whereType<ExperienceGemComponent>().length,
        lessThanOrEqualTo(PixelSurvivorGame.maxExperienceGemComponents),
      );
      expect(artifacts.keys, {
        'production-high-risk-performance-log.json',
        'production-high-risk-performance-log.md',
      });
      final json =
          jsonDecode(artifacts['production-high-risk-performance-log.json']!)
              as Map<String, dynamic>;
      expect(json['averageActiveEnemies'], 15.68288888888889);
      expect(json['maximumActiveEnemies'], 51);
      expect(json['lateAverageActiveEnemies'], 27.236944444444443);
      expect(json['lateMaximumActiveEnemies'], 51);
      expect(
        json['lateAverageSimulatedFps'],
        closeTo(1000000 / frameStepMicros, 1e-9),
      );
      expect(
        json['lateMinimumSimulatedFps'],
        closeTo(1000000 / frameStepMicros, 1e-9),
      );
      expect(json['isWithinLateFrameBudget'], isTrue);

      final markdown = artifacts['production-high-risk-performance-log.md']!;
      expect(
        markdown,
        contains('- Average / maximum active enemies: 15.68 / 51'),
      );
      expect(
        markdown,
        contains('- Late average / minimum simulated FPS: 60.00 / 60.00'),
      );
      expect(markdown, contains('- Late raw-frame budget result: PASS'));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
