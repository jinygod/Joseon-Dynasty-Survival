import 'dart:collection';

import 'package:flutter/foundation.dart';

enum GamePopulationKind { enemy, projectile, damageNumber, combatEffect }

@immutable
class GamePerformanceBudget {
  const GamePerformanceBudget({
    required this.maxEnemies,
    required this.maxProjectiles,
    required this.maxDamageNumbers,
    required this.maxCombatEffects,
  }) : assert(maxEnemies > 0),
       assert(maxProjectiles > 0),
       assert(maxDamageNumbers > 0),
       assert(maxCombatEffects > 0);

  static const standard = GamePerformanceBudget(
    maxEnemies: 96,
    maxProjectiles: 128,
    maxDamageNumbers: 24,
    maxCombatEffects: 32,
  );

  final int maxEnemies;
  final int maxProjectiles;
  final int maxDamageNumbers;
  final int maxCombatEffects;

  int limitFor(GamePopulationKind kind) => switch (kind) {
    GamePopulationKind.enemy => maxEnemies,
    GamePopulationKind.projectile => maxProjectiles,
    GamePopulationKind.damageNumber => maxDamageNumbers,
    GamePopulationKind.combatEffect => maxCombatEffects,
  };

  bool canAdd(GamePopulationKind kind, {required int current}) =>
      current < limitFor(kind);
}

@immutable
class GamePerformanceSnapshot {
  GamePerformanceSnapshot({
    required this.budget,
    required Map<GamePopulationKind, int> counts,
    Map<GamePopulationKind, int> rejected = const {},
  }) : counts = UnmodifiableMapView({
         for (final kind in GamePopulationKind.values) kind: counts[kind] ?? 0,
       }),
       rejected = UnmodifiableMapView({
         for (final kind in GamePopulationKind.values)
           kind: rejected[kind] ?? 0,
       });

  final GamePerformanceBudget budget;
  final Map<GamePopulationKind, int> counts;
  final Map<GamePopulationKind, int> rejected;

  Map<GamePopulationKind, int> get overages => UnmodifiableMapView({
    for (final kind in GamePopulationKind.values)
      if ((counts[kind] ?? 0) > budget.limitFor(kind))
        kind: counts[kind]! - budget.limitFor(kind),
  });

  bool get isWithinBudget => overages.isEmpty;
}

@immutable
class GamePerformanceDiagnostic {
  const GamePerformanceDiagnostic({
    required this.kind,
    required this.rejectedCount,
    required this.rejectedTotal,
    required this.limit,
  });

  final GamePopulationKind kind;
  final int rejectedCount;
  final int rejectedTotal;
  final int limit;
}

typedef GamePerformanceDiagnosticReporter =
    void Function(GamePerformanceDiagnostic diagnostic);
