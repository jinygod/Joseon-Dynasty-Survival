import 'dart:math';

import '../game_performance_budget.dart';
import '../systems/wave_director.dart';

class WorstCaseFrameObservation {
  const WorstCaseFrameObservation({
    required this.snapshot,
    required this.memoryProxyComponents,
  });

  final GamePerformanceSnapshot snapshot;
  final int memoryProxyComponents;
}

class WorstCasePerformanceHarness {
  WorstCasePerformanceHarness({required int seed, required this.budget})
    : _waveDirector = WaveDirector(random: Random(seed)),
      _expirations = {
        for (final kind in GamePopulationKind.values) kind: <int>[],
      },
      _rejected = {for (final kind in GamePopulationKind.values) kind: 0};

  final GamePerformanceBudget budget;
  final WaveDirector _waveDirector;
  final Map<GamePopulationKind, List<int>> _expirations;
  final Map<GamePopulationKind, int> _rejected;
  var _frame = 0;
  var elapsedSeconds = 0.0;

  WorstCaseFrameObservation step(double dt) {
    _frame += 1;
    elapsedSeconds += max(0, dt);
    for (final expirations in _expirations.values) {
      expirations.removeWhere((expiryFrame) => expiryFrame <= _frame);
    }

    final enemyCount = _count(GamePopulationKind.enemy);
    final wave = _waveDirector.tick(
      elapsedSeconds: elapsedSeconds,
      dt: dt,
      activeEnemyCount: enemyCount,
    );
    _admit(
      GamePopulationKind.enemy,
      requested: wave.spawnRequests.length + (wave.spawnBoss ? 1 : 0),
      lifetimeFrames: 45 * 60,
      secondaryAvailable: wave.maxActiveEnemies - enemyCount,
    );

    if (_count(GamePopulationKind.enemy) > 0) {
      _admit(GamePopulationKind.projectile, requested: 12, lifetimeFrames: 90);
      _admit(GamePopulationKind.damageNumber, requested: 6, lifetimeFrames: 12);
      _admit(GamePopulationKind.combatEffect, requested: 4, lifetimeFrames: 30);
    }

    final counts = {
      for (final kind in GamePopulationKind.values) kind: _count(kind),
    };
    return WorstCaseFrameObservation(
      snapshot: GamePerformanceSnapshot(
        budget: budget,
        counts: counts,
        rejected: _rejected,
      ),
      memoryProxyComponents:
          _persistentOwnerCount + counts.values.fold(0, (a, b) => a + b),
    );
  }

  static const _persistentOwnerCount = 7;

  int _count(GamePopulationKind kind) => _expirations[kind]!.length;

  void _admit(
    GamePopulationKind kind, {
    required int requested,
    required int lifetimeFrames,
    int? secondaryAvailable,
  }) {
    final admitted = budget.admitCount(
      kind,
      current: _count(kind),
      requested: requested,
      secondaryAvailable: secondaryAvailable,
    );
    _rejected[kind] = _rejected[kind]! + requested - admitted;
    _expirations[kind]!.addAll(
      List<int>.filled(admitted, _frame + lifetimeFrames),
    );
  }
}
