import 'run_outcome.dart';

class RunTelemetry {
  RunTelemetry({
    this.schemaVersion = currentSchemaVersion,
    required this.runId,
    required this.appVersion,
    required this.startedAtUtc,
    required this.endedAtUtc,
    required this.outcome,
    required this.survivalSeconds,
    required this.level,
    required this.kills,
    required this.bossDefeated,
    required Map<String, int> weaponKillCounts,
  }) : weaponKillCounts = Map.unmodifiable(weaponKillCounts);

  static const currentSchemaVersion = 1;

  final int schemaVersion;
  final String runId;
  final String appVersion;
  final DateTime startedAtUtc;
  final DateTime endedAtUtc;
  final RunOutcome outcome;
  final int survivalSeconds;
  final int level;
  final int kills;
  final bool bossDefeated;
  final Map<String, int> weaponKillCounts;

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'runId': runId,
    'appVersion': appVersion,
    'startedAtUtc': startedAtUtc.toUtc().toIso8601String(),
    'endedAtUtc': endedAtUtc.toUtc().toIso8601String(),
    'outcome': outcome.name,
    'survivalSeconds': survivalSeconds,
    'level': level,
    'kills': kills,
    'bossDefeated': bossDefeated,
    'weaponKillCounts': weaponKillCounts,
  };

  factory RunTelemetry.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'];
    if (schemaVersion != currentSchemaVersion) {
      throw FormatException('Unsupported run telemetry schema: $schemaVersion');
    }

    final outcomeName = json['outcome'];
    final outcome = _parseOutcome(outcomeName);

    try {
      return RunTelemetry(
        schemaVersion: schemaVersion as int,
        runId: json['runId'] as String,
        appVersion: json['appVersion'] as String,
        startedAtUtc: DateTime.parse(json['startedAtUtc'] as String).toUtc(),
        endedAtUtc: DateTime.parse(json['endedAtUtc'] as String).toUtc(),
        outcome: outcome,
        survivalSeconds: json['survivalSeconds'] as int,
        level: json['level'] as int,
        kills: json['kills'] as int,
        bossDefeated: json['bossDefeated'] as bool,
        weaponKillCounts: Map<String, int>.from(
          json['weaponKillCounts'] as Map,
        ),
      );
    } on Object catch (error) {
      throw FormatException('Invalid run telemetry schema 1 payload', error);
    }
  }

  static RunOutcome _parseOutcome(Object? value) {
    for (final outcome in RunOutcome.values) {
      if (outcome.name == value) {
        return outcome;
      }
    }
    throw FormatException('Unknown run outcome: $value');
  }
}
