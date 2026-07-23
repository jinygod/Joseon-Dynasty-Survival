import 'dart:convert';

import '../game_performance_budget.dart';
import 'performance_development_log.dart';

class PerformanceDevelopmentReporter {
  const PerformanceDevelopmentReporter._();

  static Map<String, String> toArtifactBundle(PerformanceDevelopmentLog log) =>
      {
        'production-high-risk-performance-log.json': toJson(log),
        'production-high-risk-performance-log.md': toMarkdown(log),
      };

  static String toJson(PerformanceDevelopmentLog log) {
    return const JsonEncoder.withIndent('  ').convert({
      'scenario': log.scenario,
      'seed': log.seed,
      'simulatedDurationSeconds': log.simulatedDurationSeconds,
      'totalFrameCount': log.totalFrameCount,
      'sampleCount': log.sampleCount,
      'averageActiveEnemies': log.averageActiveEnemies,
      'maximumActiveEnemies': log.maximumActiveEnemies,
      'lateFrameSampleCount': log.lateFrameSampleCount,
      'lateAverageActiveEnemies': log.lateAverageActiveEnemies,
      'lateMaximumActiveEnemies': log.lateMaximumActiveEnemies,
      'lateAverageLogicalFps': log.lateAverageSimulatedFps,
      'lateMinimumLogicalFps': log.lateMinimumSimulatedFps,
      'peakFrameStepMicros': log.peakFrameStepMicros,
      'peakHostUpdateLifecycleWallMicros':
          log.peakHostUpdateLifecycleWallMicros,
      'memoryMetric': 'mounted-components-plus-retained-production-owners',
      'peakMountedComponentCount': log.peakMountedComponentCount,
      'peakRetainedOwnerCount': log.peakRetainedOwnerCount,
      'peakMemoryProxyComponents': log.peakMemoryProxyComponents,
      'maxMemoryProxyComponents': log.maxMemoryProxyComponents,
      'maxRetainedOwners': log.maxRetainedOwners,
      'peakCounts': _namedValues(log.peakCounts),
      'limits': {
        for (final kind in GamePopulationKind.values)
          kind.name: log.budget.limitFor(kind),
      },
      'budgetViolationSamples': log.budgetViolationSamples,
      'memoryProxyViolationSamples': log.memoryProxyViolationSamples,
      'isWithinPopulationBudget': log.isWithinPopulationBudget,
      'isWithinMemoryProxyBudget': log.isWithinMemoryProxyBudget,
      'isWithinLateFrameBudget': log.isWithinLateFrameBudget,
    });
  }

  static String toMarkdown(PerformanceDevelopmentLog log) {
    final rows = GamePopulationKind.values
        .map(
          (kind) =>
              '| ${kind.name} | ${log.peakCounts[kind]} | '
              '${log.budget.limitFor(kind)} |',
        )
        .join('\n');
    return '''# Production High-risk Performance Development Log

- Scenario: `${log.scenario}`
- Seed: `${log.seed}`
- Window: ${log.simulatedDurationSeconds.toStringAsFixed(3)} simulated seconds
- Frames: ${_withThousands(log.totalFrameCount)} at a peak simulation step of ${log.peakFrameStepMicros} microseconds
- Samples: ${_withThousands(log.sampleCount)}
- Average / maximum active enemies: ${log.averageActiveEnemies.toStringAsFixed(2)} / ${log.maximumActiveEnemies}
- Late raw-frame samples: ${_withThousands(log.lateFrameSampleCount)} after ${GamePerformanceBudget.latePerformanceWindowStartSeconds.toStringAsFixed(0)} simulated seconds
- Late average / maximum active enemies: ${log.lateAverageActiveEnemies.toStringAsFixed(2)} / ${log.lateMaximumActiveEnemies}
- Late average / minimum logical FPS (fixed-dt): ${log.lateAverageSimulatedFps.toStringAsFixed(2)} / ${log.lateMinimumSimulatedFps.toStringAsFixed(2)} (minimum ${GamePerformanceBudget.minimumLateSimulatedFps.toStringAsFixed(0)})
- Peak host test-loop wall time for `game.update` plus lifecycle processing: ${log.peakHostUpdateLifecycleWallMicros} microseconds (not frame or render time)
- Peak mounted Flame components: ${log.peakMountedComponentCount}
- Peak retained production owners: ${log.peakRetainedOwnerCount} (limit ${log.maxRetainedOwners})
- Peak memory proxy (mounted components + retained owners): ${log.peakMemoryProxyComponents} (limit ${log.maxMemoryProxyComponents})
- Population budget result: ${log.isWithinPopulationBudget ? 'PASS' : 'FAIL'}
- Memory-proxy budget result: ${log.isWithinMemoryProxyBudget ? 'PASS' : 'FAIL'}
- Late raw-frame budget result: ${log.isWithinLateFrameBudget ? 'PASS' : 'FAIL'}

| Population | Peak | Limit |
| --- | ---: | ---: |
$rows

This deterministic fixed-dt host result reports logical FPS only. Host wall time is test-loop update+lifecycle time, not frame or render time, and is not a mobile result. Physical memory and render timing are not measured here. Mounted components plus owners retained by production game collections form a bounded leak/pressure proxy; Chrome profile-mode frame, build, and raster timing require the documented procedure.
''';
  }
}

Map<String, int> _namedValues(Map<GamePopulationKind, int> values) => {
  for (final kind in GamePopulationKind.values) kind.name: values[kind] ?? 0,
};

String _withThousands(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index += 1) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}
