import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/enemy_behavior_definitions.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';
import 'package:pixel_survivor/game/content/ids.dart';

void main() {
  test(
    'roster contains nine normal enemies three unique elites and a boss',
    () {
      expect(
        enemyDefinitions.where((enemy) => enemy.rank == EnemyRank.normal),
        hasLength(9),
      );
      expect(
        enemyDefinitions.where((enemy) => enemy.rank == EnemyRank.elite),
        hasLength(3),
      );
      expect(
        enemyDefinitions.where((enemy) => enemy.rank == EnemyRank.boss),
        isNotEmpty,
      );
      expect(
        enemyDefinitions.map((enemy) => enemy.id).toSet(),
        hasLength(enemyDefinitions.length),
      );
      expect(
        enemyDefinitions.map((enemy) => enemy.name).toSet(),
        hasLength(enemyDefinitions.length),
      );
      expect(validateEnemyContent(), isEmpty);
    },
  );

  test('every enemy behavior profile has safe finite values', () {
    for (final profile in enemyBehaviorProfiles.values) {
      expect(profile.warningSeconds.isFinite, isTrue, reason: profile.id);
      expect(profile.warningSeconds, greaterThanOrEqualTo(0));
      expect(profile.activeSeconds.isFinite, isTrue, reason: profile.id);
      expect(profile.activeSeconds, greaterThanOrEqualTo(0));
      expect(profile.recoverySeconds.isFinite, isTrue, reason: profile.id);
      expect(profile.recoverySeconds, greaterThanOrEqualTo(0));
      expect(profile.cooldownSeconds.isFinite, isTrue, reason: profile.id);
      expect(profile.cooldownSeconds, greaterThanOrEqualTo(0));
      expect(profile.range.isFinite, isTrue, reason: profile.id);
      expect(profile.range, greaterThanOrEqualTo(0));
      expect(profile.movementMultiplier.isFinite, isTrue, reason: profile.id);
      expect(profile.movementMultiplier, greaterThanOrEqualTo(0));
      expect(profile.effectMultiplier.isFinite, isTrue, reason: profile.id);
      expect(profile.effectMultiplier, greaterThanOrEqualTo(0));
      expect(profile.maxOwnedEffects, greaterThanOrEqualTo(0));
    }
  });

  test('unknown behavior profile safely falls back to chase', () {
    expect(enemyBehaviorProfileFor('missing').kind, EnemyBehaviorKind.chase);
  });
}
