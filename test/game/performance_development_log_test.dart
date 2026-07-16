import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/game_performance_budget.dart';
import 'package:pixel_survivor/game/performance/performance_development_log.dart';
import 'package:pixel_survivor/game/performance/performance_development_reporter.dart';

void main() {
  const budget = GamePerformanceBudget(
    maxEnemies: 10,
    maxProjectiles: 20,
    maxDamageNumbers: 5,
    maxCombatEffects: 6,
  );

  test('collector retains deterministic peaks and budget violations', () {
    expect(
      budget.admitCount(
        GamePopulationKind.enemy,
        current: 8,
        requested: 5,
        secondaryAvailable: 1,
      ),
      1,
    );
    final collector =
        PerformanceDevelopmentCollector(
            budget: budget,
            maxMemoryProxyComponents: 25,
            maxRetainedOwners: 6,
          )
          ..record(
            PerformanceDevelopmentSample(
              simulatedSeconds: 1,
              frameStepMicros: 16667,
              hostUpdateLifecycleWallMicros: 120,
              mountedComponentCount: 12,
              retainedOwnerCount: 2,
              snapshot: GamePerformanceSnapshot(
                budget: budget,
                counts: const {
                  GamePopulationKind.enemy: 4,
                  GamePopulationKind.projectile: 2,
                  GamePopulationKind.damageNumber: 1,
                  GamePopulationKind.combatEffect: 3,
                },
              ),
            ),
          )
          ..record(
            PerformanceDevelopmentSample(
              simulatedSeconds: 2,
              frameStepMicros: 16667,
              hostUpdateLifecycleWallMicros: 240,
              mountedComponentCount: 18,
              retainedOwnerCount: 8,
              snapshot: GamePerformanceSnapshot(
                budget: budget,
                counts: const {
                  GamePopulationKind.enemy: 11,
                  GamePopulationKind.projectile: 8,
                  GamePopulationKind.damageNumber: 2,
                  GamePopulationKind.combatEffect: 1,
                },
              ),
            ),
          );

    final log = collector.finish(
      scenario: 'fixed-seed-worst-window',
      seed: 7,
      simulatedDurationSeconds: 2,
      totalFrameCount: 120,
    );

    expect(log.sampleCount, 2);
    expect(log.peakCounts[GamePopulationKind.enemy], 11);
    expect(log.peakFrameStepMicros, 16667);
    expect(log.peakHostUpdateLifecycleWallMicros, 240);
    expect(log.peakMountedComponentCount, 18);
    expect(log.peakRetainedOwnerCount, 8);
    expect(log.peakMemoryProxyComponents, 26);
    expect(log.budgetViolationSamples, 1);
    expect(log.memoryProxyViolationSamples, 1);
    expect(log.isWithinPopulationBudget, isFalse);
    expect(log.isWithinMemoryProxyBudget, isFalse);
  });

  test('reporter emits stable machine and human readable evidence', () {
    final collector =
        PerformanceDevelopmentCollector(
          budget: budget,
          maxMemoryProxyComponents: 64,
          maxRetainedOwners: 16,
        )..record(
          PerformanceDevelopmentSample(
            simulatedSeconds: 300,
            frameStepMicros: 16667,
            hostUpdateLifecycleWallMicros: 90,
            mountedComponentCount: 42,
            retainedOwnerCount: 3,
            snapshot: GamePerformanceSnapshot(
              budget: budget,
              counts: const {GamePopulationKind.enemy: 9},
            ),
          ),
        );
    final log = collector.finish(
      scenario: 'seed-11',
      seed: 11,
      simulatedDurationSeconds: 300,
      totalFrameCount: 18000,
    );

    final json = jsonDecode(PerformanceDevelopmentReporter.toJson(log));
    expect(json['scenario'], 'seed-11');
    expect(json['totalFrameCount'], 18000);
    expect(json['peakCounts']['enemy'], 9);
    expect(
      json['memoryMetric'],
      'mounted-components-plus-retained-production-owners',
    );
    expect(json['peakMemoryProxyComponents'], 45);
    expect(json['maxMemoryProxyComponents'], 64);

    final markdown = PerformanceDevelopmentReporter.toMarkdown(log);
    expect(markdown, contains('300.000 simulated seconds'));
    expect(markdown, contains('18,000'));
    expect(markdown, contains('Physical memory and device frame time'));
    expect(markdown, contains('game.update` plus lifecycle processing'));
  });
}
