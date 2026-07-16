import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/game_performance_budget.dart';
import 'package:pixel_survivor/game/performance/performance_development_log.dart';
import 'package:pixel_survivor/game/performance/performance_development_reporter.dart';
import 'package:pixel_survivor/game/performance/worst_case_performance_harness.dart';

void main() {
  test(
    'production admissions log a deterministic five-minute worst window',
    () {
      const seed = 3107;
      const frameCount = 18000;
      const frameStepSeconds = 1 / 60;
      const frameStepMicros = 16667;
      final harness = WorstCasePerformanceHarness(
        seed: seed,
        budget: GamePerformanceBudget.standard,
      );
      final collector = PerformanceDevelopmentCollector(
        budget: GamePerformanceBudget.standard,
      );

      for (var frame = 1; frame <= frameCount; frame += 1) {
        final stopwatch = Stopwatch()..start();
        final observation = harness.step(frameStepSeconds);
        stopwatch.stop();
        collector.record(
          PerformanceDevelopmentSample(
            simulatedSeconds: frame * frameStepSeconds,
            frameStepMicros: frameStepMicros,
            updateCostMicros: stopwatch.elapsedMicroseconds,
            mountedComponentCount: observation.memoryProxyComponents,
            snapshot: observation.snapshot,
          ),
        );
      }

      final log = collector.finish(
        scenario: 'production-admission-fixed-seed-worst-window',
        seed: seed,
        simulatedDurationSeconds: 300,
        totalFrameCount: frameCount,
      );
      final artifacts = PerformanceDevelopmentReporter.toArtifactBundle(log);
      final output = Directory('build/qa')..createSync(recursive: true);
      for (final entry in artifacts.entries) {
        File('${output.path}/${entry.key}').writeAsStringSync(entry.value);
      }

      expect(harness.elapsedSeconds, closeTo(300, 0.001));
      expect(log.sampleCount, frameCount);
      expect(log.peakFrameStepMicros, frameStepMicros);
      expect(log.peakMemoryProxyComponents, greaterThan(0));
      for (final kind in GamePopulationKind.values) {
        expect(log.peakCounts[kind], greaterThan(0), reason: kind.name);
        expect(
          log.peakCounts[kind],
          lessThanOrEqualTo(GamePerformanceBudget.standard.limitFor(kind)),
          reason: kind.name,
        );
      }
      expect(log.isWithinPopulationBudget, isTrue);
      expect(artifacts.keys, {
        'five-minute-performance-log.json',
        'five-minute-performance-log.md',
      });
    },
  );
}
