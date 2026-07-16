import 'dart:collection';

import '../game_performance_budget.dart';

class PerformanceDevelopmentSample {
  const PerformanceDevelopmentSample({
    required this.simulatedSeconds,
    required this.frameStepMicros,
    required this.hostUpdateLifecycleWallMicros,
    required this.mountedComponentCount,
    required this.retainedOwnerCount,
    required this.snapshot,
  });

  final double simulatedSeconds;
  final int frameStepMicros;
  final int hostUpdateLifecycleWallMicros;
  final int mountedComponentCount;
  final int retainedOwnerCount;
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
    required this.peakHostUpdateLifecycleWallMicros,
    required this.peakMountedComponentCount,
    required this.peakRetainedOwnerCount,
    required this.peakMemoryProxyComponents,
    required this.maxMemoryProxyComponents,
    required this.maxRetainedOwners,
    required this.budgetViolationSamples,
    required this.memoryProxyViolationSamples,
  }) : peakCounts = UnmodifiableMapView(peakCounts);

  final String scenario;
  final int seed;
  final double simulatedDurationSeconds;
  final int totalFrameCount;
  final int sampleCount;
  final GamePerformanceBudget budget;
  final Map<GamePopulationKind, int> peakCounts;
  final int peakFrameStepMicros;
  final int peakHostUpdateLifecycleWallMicros;
  final int peakMountedComponentCount;
  final int peakRetainedOwnerCount;
  final int peakMemoryProxyComponents;
  final int maxMemoryProxyComponents;
  final int maxRetainedOwners;
  final int budgetViolationSamples;
  final int memoryProxyViolationSamples;

  bool get isWithinPopulationBudget => budgetViolationSamples == 0;
  bool get isWithinMemoryProxyBudget => memoryProxyViolationSamples == 0;
}

class PerformanceDevelopmentCollector {
  PerformanceDevelopmentCollector({
    required this.budget,
    required this.maxMemoryProxyComponents,
    required this.maxRetainedOwners,
  });

  final GamePerformanceBudget budget;
  final int maxMemoryProxyComponents;
  final int maxRetainedOwners;
  final Map<GamePopulationKind, int> _peakCounts = {
    for (final kind in GamePopulationKind.values) kind: 0,
  };
  var _sampleCount = 0;
  var _peakFrameStepMicros = 0;
  var _peakHostUpdateLifecycleWallMicros = 0;
  var _peakMountedComponentCount = 0;
  var _peakRetainedOwnerCount = 0;
  var _peakMemoryProxyComponents = 0;
  var _budgetViolationSamples = 0;
  var _memoryProxyViolationSamples = 0;

  void record(PerformanceDevelopmentSample sample) {
    _sampleCount += 1;
    _peakFrameStepMicros = _max(_peakFrameStepMicros, sample.frameStepMicros);
    _peakHostUpdateLifecycleWallMicros = _max(
      _peakHostUpdateLifecycleWallMicros,
      sample.hostUpdateLifecycleWallMicros,
    );
    _peakMountedComponentCount = _max(
      _peakMountedComponentCount,
      sample.mountedComponentCount,
    );
    _peakRetainedOwnerCount = _max(
      _peakRetainedOwnerCount,
      sample.retainedOwnerCount,
    );
    final memoryProxy =
        sample.mountedComponentCount + sample.retainedOwnerCount;
    _peakMemoryProxyComponents = _max(_peakMemoryProxyComponents, memoryProxy);
    if (memoryProxy > maxMemoryProxyComponents ||
        sample.retainedOwnerCount > maxRetainedOwners) {
      _memoryProxyViolationSamples += 1;
    }
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
      peakHostUpdateLifecycleWallMicros: _peakHostUpdateLifecycleWallMicros,
      peakMountedComponentCount: _peakMountedComponentCount,
      peakRetainedOwnerCount: _peakRetainedOwnerCount,
      peakMemoryProxyComponents: _peakMemoryProxyComponents,
      maxMemoryProxyComponents: maxMemoryProxyComponents,
      maxRetainedOwners: maxRetainedOwners,
      budgetViolationSamples: _budgetViolationSamples,
      memoryProxyViolationSamples: _memoryProxyViolationSamples,
    );
  }
}

int _max(int left, int right) => left >= right ? left : right;
