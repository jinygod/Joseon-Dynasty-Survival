import 'dart:collection';

import '../game_performance_budget.dart';

class PerformanceDevelopmentSample {
  const PerformanceDevelopmentSample({
    required this.simulatedSeconds,
    required this.frameStepMicros,
    required this.updateCostMicros,
    required this.mountedComponentCount,
    required this.snapshot,
  });

  final double simulatedSeconds;
  final int frameStepMicros;
  final int updateCostMicros;
  final int mountedComponentCount;
  final GamePerformanceSnapshot snapshot;
}

class PerformanceDevelopmentLog {
  PerformanceDevelopmentLog({
    required this.scenario,
    required this.seed,
    required this.simulatedDurationSeconds,
    required this.totalFrameCount,
    required this.sampleCount,
    required this.budget,
    required Map<GamePopulationKind, int> peakCounts,
    required this.peakFrameStepMicros,
    required this.peakUpdateCostMicros,
    required this.peakMemoryProxyComponents,
    required this.budgetViolationSamples,
  }) : peakCounts = UnmodifiableMapView(peakCounts);

  final String scenario;
  final int seed;
  final double simulatedDurationSeconds;
  final int totalFrameCount;
  final int sampleCount;
  final GamePerformanceBudget budget;
  final Map<GamePopulationKind, int> peakCounts;
  final int peakFrameStepMicros;
  final int peakUpdateCostMicros;
  final int peakMemoryProxyComponents;
  final int budgetViolationSamples;

  bool get isWithinPopulationBudget => budgetViolationSamples == 0;
}

class PerformanceDevelopmentCollector {
  PerformanceDevelopmentCollector({required this.budget});

  final GamePerformanceBudget budget;
  final Map<GamePopulationKind, int> _peakCounts = {
    for (final kind in GamePopulationKind.values) kind: 0,
  };
  var _sampleCount = 0;
  var _peakFrameStepMicros = 0;
  var _peakUpdateCostMicros = 0;
  var _peakMemoryProxyComponents = 0;
  var _budgetViolationSamples = 0;

  void record(PerformanceDevelopmentSample sample) {
    _sampleCount += 1;
    _peakFrameStepMicros = _max(_peakFrameStepMicros, sample.frameStepMicros);
    _peakUpdateCostMicros = _max(
      _peakUpdateCostMicros,
      sample.updateCostMicros,
    );
    _peakMemoryProxyComponents = _max(
      _peakMemoryProxyComponents,
      sample.mountedComponentCount,
    );
    var violatesBudget = false;
    for (final kind in GamePopulationKind.values) {
      final count = sample.snapshot.counts[kind] ?? 0;
      _peakCounts[kind] = _max(_peakCounts[kind]!, count);
      if (count > budget.limitFor(kind)) violatesBudget = true;
    }
    if (violatesBudget) _budgetViolationSamples += 1;
  }

  PerformanceDevelopmentLog finish({
    required String scenario,
    required int seed,
    required double simulatedDurationSeconds,
    required int totalFrameCount,
  }) {
    if (_sampleCount == 0) {
      throw StateError('At least one performance sample is required.');
    }
    return PerformanceDevelopmentLog(
      scenario: scenario,
      seed: seed,
      simulatedDurationSeconds: simulatedDurationSeconds,
      totalFrameCount: totalFrameCount,
      sampleCount: _sampleCount,
      budget: budget,
      peakCounts: Map.of(_peakCounts),
      peakFrameStepMicros: _peakFrameStepMicros,
      peakUpdateCostMicros: _peakUpdateCostMicros,
      peakMemoryProxyComponents: _peakMemoryProxyComponents,
      budgetViolationSamples: _budgetViolationSamples,
    );
  }
}

int _max(int left, int right) => left >= right ? left : right;
