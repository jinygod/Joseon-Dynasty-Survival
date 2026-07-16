import 'dart:convert';

import '../game_performance_budget.dart';
import 'performance_development_log.dart';

class PerformanceDevelopmentReporter {
  const PerformanceDevelopmentReporter._();

  static Map<String, String> toArtifactBundle(PerformanceDevelopmentLog log) =>
      {
        'five-minute-performance-log.json': toJson(log),
        'five-minute-performance-log.md': toMarkdown(log),
      };

  static String toJson(PerformanceDevelopmentLog log) {
    return const JsonEncoder.withIndent('  ').convert({
      'scenario': log.scenario,
      'seed': log.seed,
      'simulatedDurationSeconds': log.simulatedDurationSeconds,
      'totalFrameCount': log.totalFrameCount,
      'sampleCount': log.sampleCount,
      'peakFrameStepMicros': log.peakFrameStepMicros,
      'peakUpdateCostMicros': log.peakUpdateCostMicros,
      'memoryMetric': 'mounted-component-count-proxy',
      'peakMemoryProxyComponents': log.peakMemoryProxyComponents,
      'peakCounts': _namedValues(log.peakCounts),
      'limits': {
        for (final kind in GamePopulationKind.values)
          kind.name: log.budget.limitFor(kind),
      },
      'budgetViolationSamples': log.budgetViolationSamples,
      'isWithinPopulationBudget': log.isWithinPopulationBudget,
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
    return '''# Five-minute Performance Development Log

- Scenario: `${log.scenario}`
- Seed: `${log.seed}`
- Window: ${log.simulatedDurationSeconds.toStringAsFixed(3)} simulated seconds
- Frames: ${_withThousands(log.totalFrameCount)} at a peak simulation step of ${log.peakFrameStepMicros} microseconds
- Samples: ${_withThousands(log.sampleCount)}
- Peak measured update cost: ${log.peakUpdateCostMicros} microseconds on the generating host
- Peak memory proxy: ${log.peakMemoryProxyComponents} mounted Flame components
- Population budget result: ${log.isWithinPopulationBudget ? 'PASS' : 'FAIL'}

| Population | Peak | Limit |
| --- | ---: | ---: |
$rows

Physical memory is not measured by this deterministic test. The mounted-component count is a stable leak/pressure proxy; profile-mode RSS and heap measurements require the documented manual device procedure.
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
