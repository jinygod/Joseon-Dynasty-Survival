import 'run_choice_record.dart';
import 'combat_playtest_metrics.dart';
import 'run_feedback.dart';
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
    this.feedback,
    this.combatMetrics = CombatPlaytestMetrics.empty,
  }) : weaponKillCounts = Map.unmodifiable(weaponKillCounts),
       weaponDamageTotals = Map.unmodifiable(weaponDamageTotals),
       choices = List.unmodifiable(choices);

  static const currentSchemaVersion = 2;

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
  final RunFeedback? feedback;
  final CombatPlaytestMetrics combatMetrics;

  RunTelemetry copyWith({RunFeedback? feedback}) {
    return RunTelemetry(
      schemaVersion: schemaVersion,
      runId: runId,
      appVersion: appVersion,
      startedAtUtc: startedAtUtc,
      endedAtUtc: endedAtUtc,
      outcome: outcome,
      survivalSeconds: survivalSeconds,
      level: level,
      kills: kills,
      bossDefeated: bossDefeated,
      weaponKillCounts: weaponKillCounts,
      weaponDamageTotals: weaponDamageTotals,
      choices: choices,
      totalDamageTaken: totalDamageTaken,
      lastDamageSource: lastDamageSource,
      deathAtSeconds: deathAtSeconds,
      feedback: feedback ?? this.feedback,
      combatMetrics: combatMetrics,
    );
  }

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
      combatMetrics: result.combatMetrics,
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
    'weaponKillCounts': _sortedTelemetryMap(weaponKillCounts),
    'weaponDamageTotals': _sortedTelemetryMap(weaponDamageTotals),
    'choices': choices.map((choice) => choice.toJson()).toList(),
    'totalDamageTaken': totalDamageTaken,
    'lastDamageSource': lastDamageSource,
    'deathAtSeconds': deathAtSeconds,
    'feedback': feedback?.toJson(),
    'combatMetrics': combatMetrics.toJson(),
  };

  factory RunTelemetry.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'];
    if (schemaVersion != 1 && schemaVersion != currentSchemaVersion) {
      throw FormatException('Unsupported run telemetry schema: $schemaVersion');
    }

    final outcomeName = json['outcome'];
    final outcome = _parseOutcome(outcomeName);

    try {
      if (schemaVersion == currentSchemaVersion) {
        _requireSchemaTwoFields(json);
      }
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
        weaponDamageTotals: schemaVersion == currentSchemaVersion
            ? _requiredDoubleMap(json['weaponDamageTotals'])
            : _doubleMap(json['weaponDamageTotals']),
        choices: schemaVersion == currentSchemaVersion
            ? _requiredChoiceList(json['choices'])
            : _choiceList(json['choices']),
        totalDamageTaken: schemaVersion == currentSchemaVersion
            ? (json['totalDamageTaken'] as num).toDouble()
            : (json['totalDamageTaken'] as num?)?.toDouble() ?? 0,
        lastDamageSource: json['lastDamageSource'] as String?,
        deathAtSeconds: json['deathAtSeconds'] as int?,
        feedback: _feedback(json['feedback']),
        combatMetrics: schemaVersion == 1
            ? CombatPlaytestMetrics.empty
            : CombatPlaytestMetrics.fromJson(json['combatMetrics']),
      );
    } on Object catch (error) {
      throw FormatException(
        'Invalid run telemetry schema $schemaVersion payload',
        error,
      );
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

  static Map<String, double> _requiredDoubleMap(Object? value) {
    if (value == null) {
      throw const FormatException('Missing weapon damage totals');
    }
    return _doubleMap(value);
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

  static List<RunChoiceRecord> _requiredChoiceList(Object? value) {
    if (value == null) throw const FormatException('Missing run choice list');
    return _choiceList(value);
  }

  static void _requireSchemaTwoFields(Map<String, dynamic> json) {
    const requiredFields = <String>{
      'weaponDamageTotals',
      'choices',
      'totalDamageTaken',
      'lastDamageSource',
      'deathAtSeconds',
      'feedback',
      'combatMetrics',
    };
    for (final field in requiredFields) {
      if (!json.containsKey(field)) {
        throw FormatException('Missing schema 2 field: $field');
      }
    }
  }

  static RunFeedback? _feedback(Object? value) {
    if (value == null) return null;
    if (value is! Map) {
      throw const FormatException('Invalid run feedback entry');
    }
    return RunFeedback.fromJson(Map<String, dynamic>.from(value));
  }
}

Map<String, T> _sortedTelemetryMap<T>(Map<String, T> source) => {
  for (final key in source.keys.toList()..sort()) key: source[key] as T,
};
