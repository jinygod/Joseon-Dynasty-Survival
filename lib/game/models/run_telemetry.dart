import 'run_choice_record.dart';
import 'run_outcome.dart';
import 'run_result.dart';

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
    Map<String, double> weaponDamageTotals = const {},
    List<RunChoiceRecord> choices = const [],
    this.totalDamageTaken = 0,
    this.lastDamageSource,
    this.deathAtSeconds,
  }) : weaponKillCounts = Map.unmodifiable(weaponKillCounts),
       weaponDamageTotals = Map.unmodifiable(weaponDamageTotals),
       choices = List.unmodifiable(choices);

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
  final Map<String, double> weaponDamageTotals;
  final List<RunChoiceRecord> choices;
  final double totalDamageTaken;
  final String? lastDamageSource;
  final int? deathAtSeconds;

  factory RunTelemetry.fromRunResult({
    required RunResult result,
    required String runId,
    required String appVersion,
    required DateTime startedAtUtc,
    required DateTime endedAtUtc,
  }) {
    return RunTelemetry(
      runId: runId,
      appVersion: appVersion,
      startedAtUtc: startedAtUtc,
      endedAtUtc: endedAtUtc,
      outcome: result.outcome,
      survivalSeconds: result.survivalSeconds,
      level: result.level,
      kills: result.kills,
      bossDefeated: result.bossDefeated,
      weaponKillCounts: result.weaponKillCounts,
      weaponDamageTotals: result.weaponDamageTotals,
      choices: result.choices,
      totalDamageTaken: result.totalDamageTaken,
      lastDamageSource: result.lastDamageSource,
      deathAtSeconds: result.deathAtSeconds,
    );
  }

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
    'weaponDamageTotals': weaponDamageTotals,
    'choices': choices.map((choice) => choice.toJson()).toList(),
    'totalDamageTaken': totalDamageTaken,
    'lastDamageSource': lastDamageSource,
    'deathAtSeconds': deathAtSeconds,
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
        weaponDamageTotals: _doubleMap(json['weaponDamageTotals']),
        choices: _choiceList(json['choices']),
        totalDamageTaken: (json['totalDamageTaken'] as num?)?.toDouble() ?? 0,
        lastDamageSource: json['lastDamageSource'] as String?,
        deathAtSeconds: json['deathAtSeconds'] as int?,
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

  static Map<String, double> _doubleMap(Object? value) {
    if (value == null) return const {};
    if (value is! Map) {
      throw const FormatException('Invalid weapon damage totals');
    }

    return value.map((key, amount) {
      if (key is! String || amount is! num) {
        throw const FormatException('Invalid weapon damage entry');
      }
      return MapEntry(key, amount.toDouble());
    });
  }

  static List<RunChoiceRecord> _choiceList(Object? value) {
    if (value == null) return const [];
    if (value is! List) {
      throw const FormatException('Invalid run choice list');
    }

    return value.map((entry) {
      if (entry is! Map) {
        throw const FormatException('Invalid run choice entry');
      }
      return RunChoiceRecord.fromJson(Map<String, dynamic>.from(entry));
    }).toList();
  }
}
