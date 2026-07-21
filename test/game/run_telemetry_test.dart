// ignore_for_file: prefer_const_literals_to_create_immutables

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/models/run_choice_record.dart';
import 'package:pixel_survivor/game/models/combat_playtest_metrics.dart';
import 'package:pixel_survivor/game/models/run_feedback.dart';
import 'package:pixel_survivor/game/models/run_outcome.dart';
import 'package:pixel_survivor/game/models/run_result.dart';
import 'package:pixel_survivor/game/models/run_telemetry.dart';

void main() {
  test('run telemetry JSON round trip preserves schema two fields', () {
    final telemetry = RunTelemetry(
      runId: 'run-20260714-001',
      appVersion: '0.1.0+1',
      startedAtUtc: DateTime.utc(2026, 7, 14, 1),
      endedAtUtc: DateTime.utc(2026, 7, 14, 1, 5),
      outcome: RunOutcome.victory,
      survivalSeconds: 300,
      level: 10,
      kills: 427,
      bossDefeated: true,
      weaponKillCounts: const {'basic_slash': 300, 'talisman_throw': 127},
    );

    final decoded = RunTelemetry.fromJson(telemetry.toJson());

    expect(decoded.schemaVersion, RunTelemetry.currentSchemaVersion);
    expect(decoded.runId, telemetry.runId);
    expect(decoded.appVersion, telemetry.appVersion);
    expect(decoded.startedAtUtc, telemetry.startedAtUtc);
    expect(decoded.endedAtUtc, telemetry.endedAtUtc);
    expect(decoded.outcome, telemetry.outcome);
    expect(decoded.survivalSeconds, telemetry.survivalSeconds);
    expect(decoded.level, telemetry.level);
    expect(decoded.kills, telemetry.kills);
    expect(decoded.bossDefeated, telemetry.bossDefeated);
    expect(decoded.weaponKillCounts, telemetry.weaponKillCounts);
  });

  test('run telemetry rejects a future schema version', () {
    expect(
      () => RunTelemetry.fromJson(const {'schemaVersion': 999}),
      throwsFormatException,
    );
  });

  test('run telemetry round trip preserves extended playtest metrics', () {
    final telemetry = RunTelemetry(
      runId: 'extended-run',
      appVersion: '0.1.0+1',
      startedAtUtc: DateTime.utc(2026, 7, 14, 2),
      endedAtUtc: DateTime.utc(2026, 7, 14, 2, 4),
      outcome: RunOutcome.defeat,
      survivalSeconds: 240,
      level: 8,
      kills: 200,
      bossDefeated: false,
      weaponKillCounts: const {'basic_slash': 200},
      weaponDamageTotals: const {'basic_slash': 1234.5},
      choices: const [
        RunChoiceRecord(
          type: RunChoiceType.weapon,
          contentId: 'basic_slash',
          selectedAtSeconds: 20,
          selectedLevel: 2,
        ),
        RunChoiceRecord(
          type: RunChoiceType.augment,
          contentId: 'inner_breath',
          selectedAtSeconds: 45,
          selectedLevel: 1,
        ),
      ],
      totalDamageTaken: 105.5,
      lastDamageSource: 'vengeful_spirit',
      deathAtSeconds: 240,
    );

    final decoded = RunTelemetry.fromJson(telemetry.toJson());

    expect(decoded.weaponDamageTotals, telemetry.weaponDamageTotals);
    expect(decoded.choices, telemetry.choices);
    expect(decoded.totalDamageTaken, 105.5);
    expect(decoded.lastDamageSource, 'vengeful_spirit');
    expect(decoded.deathAtSeconds, 240);
  });

  test('run telemetry maps every run result metric', () {
    const result = RunResult(
      outcome: RunOutcome.victory,
      survivalSeconds: 300,
      kills: 400,
      level: 10,
      bossDefeated: true,
      wonWithLowHealth: false,
      weaponKillCounts: {'basic_slash': 400},
      weaponLevels: {'basic_slash': 5},
      weaponDamageTotals: {'basic_slash': 5000},
      choices: [
        RunChoiceRecord(
          type: RunChoiceType.weapon,
          contentId: 'basic_slash',
          selectedAtSeconds: 12,
          selectedLevel: 2,
        ),
      ],
      totalDamageTaken: 20,
      lastDamageSource: 'plague_rat',
    );

    final telemetry = RunTelemetry.fromRunResult(
      result: result,
      runId: 'mapped-run',
      appVersion: '0.1.0+1',
      startedAtUtc: DateTime.utc(2026, 7, 14),
      endedAtUtc: DateTime.utc(2026, 7, 14, 0, 5),
    );

    expect(telemetry.runId, 'mapped-run');
    expect(telemetry.outcome, RunOutcome.victory);
    expect(telemetry.weaponDamageTotals, {'basic_slash': 5000});
    expect(telemetry.choices, result.choices);
    expect(telemetry.totalDamageTaken, 20);
    expect(telemetry.lastDamageSource, 'plague_rat');
    expect(telemetry.deathAtSeconds, isNull);
  });

  test('schema one payload without extended fields remains readable', () {
    final decoded = RunTelemetry.fromJson({
      'schemaVersion': 1,
      'runId': 'legacy-run',
      'appVersion': '0.1.0+1',
      'startedAtUtc': '2026-07-14T00:00:00.000Z',
      'endedAtUtc': '2026-07-14T00:05:00.000Z',
      'outcome': 'victory',
      'survivalSeconds': 300,
      'level': 10,
      'kills': 400,
      'bossDefeated': true,
      'weaponKillCounts': <String, int>{},
    });

    expect(decoded.weaponDamageTotals, isEmpty);
    expect(decoded.choices, isEmpty);
    expect(decoded.totalDamageTaken, 0);
    expect(decoded.lastDamageSource, isNull);
    expect(decoded.deathAtSeconds, isNull);
    expect(decoded.feedback, isNull);
    expect(decoded.combatMetrics, CombatPlaytestMetrics.empty);
  });

  test('schema two telemetry round trips combat playtest metrics', () {
    final metrics = CombatPlaytestMetrics(
      weaponOfferCounts: {'hwando_slash': 2},
      weaponSelectionCounts: {'hwando_slash': 1},
      weaponLevelTimes: {
        'hwando_slash': {2: 20},
      },
      firstMasterAtSeconds: {'hwando_slash': 190},
      masterKillsInTenSeconds: {'hwando_slash': 8},
      firstSynergyAtSeconds: {'sealing_slash': 60},
      synergyDamageTotals: {'sealing_slash': 120},
      enemyRoleDamageToPlayer: {'swarm': 20},
      enemyRoleDeathCauses: {'tank': 1},
      averageEnemyCount: 23.5,
      maxEnemyCount: 42,
      lateAverageFps: 58.5,
      lateMinFps: 41,
      masteredWeaponIds: {'hwando_slash'},
      isRepeatRun: true,
    );
    final telemetry = RunTelemetry(
      runId: 'combat-run',
      appVersion: '0.1.0+1',
      startedAtUtc: DateTime.utc(2026, 7, 14),
      endedAtUtc: DateTime.utc(2026, 7, 14, 0, 5),
      outcome: RunOutcome.victory,
      survivalSeconds: 300,
      level: 10,
      kills: 400,
      bossDefeated: true,
      weaponKillCounts: const {},
      combatMetrics: metrics,
    );

    final decoded = RunTelemetry.fromJson(telemetry.toJson());

    expect(decoded.schemaVersion, 2);
    expect(decoded.combatMetrics, metrics);
    expect(decoded.combatMetrics.hashCode, metrics.hashCode);
  });

  test('schema two writes combat metric maps in stable key order', () {
    final metrics = CombatPlaytestMetrics(
      weaponOfferCounts: {'z': 1, 'a': 2},
      weaponSelectionCounts: {},
      weaponLevelTimes: {
        'z': {3: 30, 1: 10},
        'a': {2: 20},
      },
      firstMasterAtSeconds: {},
      masterKillsInTenSeconds: {},
      firstSynergyAtSeconds: {},
      synergyDamageTotals: {},
      enemyRoleDamageToPlayer: {},
      enemyRoleDeathCauses: {},
      averageEnemyCount: 0,
      maxEnemyCount: 0,
      lateAverageFps: 0,
      lateMinFps: 0,
      masteredWeaponIds: {'z', 'a'},
      isRepeatRun: false,
    );
    final json = metrics.toJson();

    expect((json['weaponOfferCounts'] as Map).keys, ['a', 'z']);
    expect((json['weaponLevelTimes'] as Map).keys, ['a', 'z']);
    expect(((json['weaponLevelTimes'] as Map)['z'] as Map).keys, ['1', '3']);
    expect(json['masteredWeaponIds'], ['a', 'z']);
  });

  test('semantically equal schema two payloads serialize identically', () {
    RunTelemetry telemetry({required bool reverse}) => RunTelemetry(
      runId: 'deterministic-run',
      appVersion: '0.1.0+1',
      startedAtUtc: DateTime.utc(2026, 7, 14),
      endedAtUtc: DateTime.utc(2026, 7, 14, 0, 5),
      outcome: RunOutcome.victory,
      survivalSeconds: 300,
      level: 10,
      kills: 3,
      bossDefeated: true,
      weaponKillCounts: reverse ? {'z': 1, 'a': 2} : {'a': 2, 'z': 1},
      weaponDamageTotals: reverse ? {'z': 10, 'a': 20} : {'a': 20, 'z': 10},
      combatMetrics: CombatPlaytestMetrics(
        weaponOfferCounts: reverse ? {'z': 1, 'a': 2} : {'a': 2, 'z': 1},
        weaponSelectionCounts: const {},
        weaponLevelTimes: const {},
        firstMasterAtSeconds: const {},
        masterKillsInTenSeconds: const {},
        firstSynergyAtSeconds: const {},
        synergyDamageTotals: const {},
        enemyRoleDamageToPlayer: const {},
        enemyRoleDeathCauses: const {},
        averageEnemyCount: 0,
        maxEnemyCount: 0,
        lateAverageFps: 0,
        lateMinFps: 0,
        masteredWeaponIds: reverse ? {'z', 'a'} : {'a', 'z'},
        isRepeatRun: false,
      ),
    );

    expect(
      jsonEncode(telemetry(reverse: false).toJson()),
      jsonEncode(telemetry(reverse: true).toJson()),
    );
  });

  test('schema two requires complete combat playtest metrics', () {
    final json = RunTelemetry(
      runId: 'invalid-combat-run',
      appVersion: '0.1.0+1',
      startedAtUtc: DateTime.utc(2026, 7, 14),
      endedAtUtc: DateTime.utc(2026, 7, 14, 0, 5),
      outcome: RunOutcome.victory,
      survivalSeconds: 300,
      level: 10,
      kills: 400,
      bossDefeated: true,
      weaponKillCounts: const {},
    ).toJson()..remove('combatMetrics');

    expect(() => RunTelemetry.fromJson(json), throwsFormatException);
  });

  test('schema two requires every top-level field including nullable ones', () {
    final json = RunTelemetry(
      runId: 'incomplete-run',
      appVersion: '0.1.0+1',
      startedAtUtc: DateTime.utc(2026, 7, 14),
      endedAtUtc: DateTime.utc(2026, 7, 14, 0, 5),
      outcome: RunOutcome.defeat,
      survivalSeconds: 100,
      level: 4,
      kills: 50,
      bossDefeated: false,
      weaponKillCounts: const {},
    ).toJson()..remove('feedback');

    expect(() => RunTelemetry.fromJson(json), throwsFormatException);
  });

  test('schema two requires every schema two field', () {
    final json = RunTelemetry(
      runId: 'invalid-schema-two-run',
      appVersion: '0.1.0+1',
      startedAtUtc: DateTime.utc(2026, 7, 14),
      endedAtUtc: DateTime.utc(2026, 7, 14, 0, 5),
      outcome: RunOutcome.victory,
      survivalSeconds: 300,
      level: 10,
      kills: 400,
      bossDefeated: true,
      weaponKillCounts: const {},
    ).toJson()..remove('choices');

    expect(() => RunTelemetry.fromJson(json), throwsFormatException);
  });

  test('run feedback validates trims and round trips', () {
    final feedback = RunFeedback(
      funRating: 4,
      difficultyRating: 3,
      retryIntent: true,
      comment: '  보스전이 재미있음  ',
    );
    final telemetry = RunTelemetry(
      runId: 'feedback-run',
      appVersion: '0.1.0+1',
      startedAtUtc: DateTime.utc(2026, 7, 14),
      endedAtUtc: DateTime.utc(2026, 7, 14, 0, 5),
      outcome: RunOutcome.victory,
      survivalSeconds: 300,
      level: 10,
      kills: 400,
      bossDefeated: true,
      weaponKillCounts: const {},
      feedback: feedback,
    );

    final decoded = RunTelemetry.fromJson(telemetry.toJson());

    expect(feedback.comment, '보스전이 재미있음');
    expect(decoded.feedback, feedback);
  });

  test('run feedback rejects invalid ratings and long comments', () {
    expect(
      () => RunFeedback(
        funRating: 0,
        difficultyRating: 3,
        retryIntent: true,
        comment: '',
      ),
      throwsArgumentError,
    );
    expect(
      () => RunFeedback(
        funRating: 5,
        difficultyRating: 6,
        retryIntent: false,
        comment: '',
      ),
      throwsArgumentError,
    );
    expect(
      () => RunFeedback(
        funRating: 5,
        difficultyRating: 3,
        retryIntent: true,
        comment: List.filled(201, 'a').join(),
      ),
      throwsArgumentError,
    );
  });
}
