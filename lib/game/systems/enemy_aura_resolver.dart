import 'dart:math' as math;

class EnemyAuraResult {
  const EnemyAuraResult({
    required this.hasteFraction,
    required this.slowFraction,
  });

  final double hasteFraction;
  final double slowFraction;
}

class EnemyAuraResolver {
  const EnemyAuraResolver();

  EnemyAuraResult resolve({
    required Iterable<double> hasteFractions,
    required Iterable<double> slowFractions,
  }) => EnemyAuraResult(
    hasteFraction: hasteFractions
        .fold<double>(0, (strongest, value) => math.max(strongest, value))
        .clamp(0, .6)
        .toDouble(),
    slowFraction: slowFractions
        .fold<double>(0, (strongest, value) => math.max(strongest, value))
        .clamp(0, .8)
        .toDouble(),
  );
}
