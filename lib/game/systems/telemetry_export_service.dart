import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/run_telemetry.dart';
import '../models/run_outcome.dart';
import 'telemetry_repository.dart';

typedef TelemetryLoader = Future<List<RunTelemetry>> Function();
typedef ClipboardWriter = Future<void> Function(String value);
typedef JsonFileSharer =
    Future<void> Function(String fileName, String mimeType, List<int> bytes);

class TelemetryExportService {
  TelemetryExportService({
    TelemetryLoader? load,
    ClipboardWriter? writeClipboard,
    JsonFileSharer? shareJsonFile,
  }) : _load = load ?? TelemetryRepository().load,
       _writeClipboard = writeClipboard ?? _defaultClipboardWriter,
       _shareJsonFile = shareJsonFile ?? _defaultJsonFileSharer;

  static const _encoder = JsonEncoder.withIndent('  ');

  final TelemetryLoader _load;
  final ClipboardWriter _writeClipboard;
  final JsonFileSharer _shareJsonFile;

  TelemetryAggregateReport aggregate(Iterable<RunTelemetry> runs) {
    final history = runs.toList(growable: false);
    final weaponOffers = <String, int>{};
    final weaponSelections = <String, int>{};
    final weaponDamage = <String, double>{};
    final weaponLevelTimes = <String, Map<int, _Average>>{};
    final masterTimes = <String, _Average>{};
    final masterKills = <String, _Average>{};
    final synergyTimes = <String, _Average>{};
    final synergyDamage = <String, double>{};
    final enemyRoleDamage = <String, double>{};
    final enemyRoleDeaths = <String, int>{};
    var schemaTwoRuns = 0;
    var averageEnemyCountTotal = 0.0;
    var maxEnemyCount = 0;
    var observedFpsRuns = 0;
    var lateAverageFpsTotal = 0.0;
    double? lateMinFps;
    var masteredRuns = 0;
    var masteredWins = 0;
    var nonMasteredRuns = 0;
    var nonMasteredWins = 0;
    var repeatRuns = 0;

    for (final run in history) {
      _addDoubleMap(weaponDamage, run.weaponDamageTotals);
      if (run.schemaVersion != RunTelemetry.currentSchemaVersion) continue;

      schemaTwoRuns += 1;
      final metrics = run.combatMetrics;
      _addIntMap(weaponOffers, metrics.weaponOfferCounts);
      _addIntMap(weaponSelections, metrics.weaponSelectionCounts);
      for (final weaponEntry in metrics.weaponLevelTimes.entries) {
        final levels = weaponLevelTimes.putIfAbsent(
          weaponEntry.key,
          () => <int, _Average>{},
        );
        for (final levelEntry in weaponEntry.value.entries) {
          levels
              .putIfAbsent(levelEntry.key, _Average.new)
              .add(levelEntry.value);
        }
      }
      _addAverages(masterTimes, metrics.firstMasterAtSeconds);
      _addAverages(masterKills, metrics.masterKillsInTenSeconds);
      _addAverages(synergyTimes, metrics.firstSynergyAtSeconds);
      _addDoubleMap(synergyDamage, metrics.synergyDamageTotals);
      _addDoubleMap(enemyRoleDamage, metrics.enemyRoleDamageToPlayer);
      _addIntMap(enemyRoleDeaths, metrics.enemyRoleDeathCauses);

      averageEnemyCountTotal += metrics.averageEnemyCount;
      if (metrics.maxEnemyCount > maxEnemyCount) {
        maxEnemyCount = metrics.maxEnemyCount;
      }
      if (metrics.lateAverageFps > 0) {
        observedFpsRuns += 1;
        lateAverageFpsTotal += metrics.lateAverageFps;
      }
      if (metrics.lateMinFps > 0) {
        lateMinFps = lateMinFps == null
            ? metrics.lateMinFps
            : _minimum(lateMinFps, metrics.lateMinFps);
      }
      if (metrics.masteredWeaponIds.isEmpty) {
        nonMasteredRuns += 1;
        if (run.outcome == RunOutcome.victory) nonMasteredWins += 1;
      } else {
        masteredRuns += 1;
        if (run.outcome == RunOutcome.victory) masteredWins += 1;
      }
      if (metrics.isRepeatRun) repeatRuns += 1;
    }

    final totalDamage = weaponDamage.values.fold<double>(0, (a, b) => a + b);
    final totalSynergyDamage = synergyDamage.values.fold<double>(
      0,
      (a, b) => a + b,
    );
    return TelemetryAggregateReport(
      runCount: history.length,
      weaponOfferCounts: weaponOffers,
      weaponSelectionCounts: weaponSelections,
      weaponSelectionRates: {
        for (final weaponId in {...weaponOffers.keys, ...weaponSelections.keys})
          weaponId: _rate(
            weaponSelections[weaponId] ?? 0,
            weaponOffers[weaponId] ?? 0,
          ),
      },
      weaponDamageShares: {
        for (final entry in weaponDamage.entries)
          entry.key: _share(entry.value, totalDamage),
      },
      weaponLevelAverageTimes: {
        for (final weaponEntry in weaponLevelTimes.entries)
          weaponEntry.key: {
            for (final levelEntry in weaponEntry.value.entries)
              levelEntry.key: levelEntry.value.value,
          },
      },
      firstMasterAverageSeconds: _averageMap(masterTimes),
      masterKillsInTenSecondsAverage: _averageMap(masterKills),
      firstSynergyAverageSeconds: _averageMap(synergyTimes),
      synergyDamageShares: {
        for (final entry in synergyDamage.entries)
          entry.key: _share(entry.value, totalDamage),
      },
      synergyDamageShare: _share(totalSynergyDamage, totalDamage),
      enemyRoleDamageToPlayer: enemyRoleDamage,
      enemyRoleDeathCauses: enemyRoleDeaths,
      averageEnemyCount: _rate(averageEnemyCountTotal, schemaTwoRuns),
      maxEnemyCount: maxEnemyCount,
      lateAverageFps: _rate(lateAverageFpsTotal, observedFpsRuns),
      lateMinFps: lateMinFps ?? 0,
      masteredRunWinRate: _rate(masteredWins, masteredRuns),
      nonMasteredRunWinRate: _rate(nonMasteredWins, nonMasteredRuns),
      repeatRunRate: _rate(repeatRuns, schemaTwoRuns),
    );
  }

  Future<bool> copyRun(String runId) async {
    final history = await _load();
    RunTelemetry? selected;
    for (final run in history) {
      if (run.runId == runId) {
        selected = run;
        break;
      }
    }
    if (selected == null) return false;

    await _writeClipboard(_encoder.convert(selected.toJson()));
    return true;
  }

  Future<bool> exportAll() async {
    final history = await _load();
    if (history.isEmpty) return false;

    final json = _encoder.convert(history.map((run) => run.toJson()).toList());
    await _shareJsonFile(
      'run-telemetry.json',
      'application/json',
      utf8.encode(json),
    );
    return true;
  }

  static Future<void> _defaultClipboardWriter(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
  }

  static Future<void> _defaultJsonFileSharer(
    String fileName,
    String mimeType,
    List<int> bytes,
  ) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(Uint8List.fromList(bytes), mimeType: mimeType)],
        fileNameOverrides: [fileName],
      ),
    );
  }
}

class TelemetryAggregateReport {
  TelemetryAggregateReport({
    required this.runCount,
    required Map<String, int> weaponOfferCounts,
    required Map<String, int> weaponSelectionCounts,
    required Map<String, double> weaponSelectionRates,
    required Map<String, double> weaponDamageShares,
    required Map<String, Map<int, double>> weaponLevelAverageTimes,
    required Map<String, double> firstMasterAverageSeconds,
    required Map<String, double> masterKillsInTenSecondsAverage,
    required Map<String, double> firstSynergyAverageSeconds,
    required Map<String, double> synergyDamageShares,
    required this.synergyDamageShare,
    required Map<String, double> enemyRoleDamageToPlayer,
    required Map<String, int> enemyRoleDeathCauses,
    required this.averageEnemyCount,
    required this.maxEnemyCount,
    required this.lateAverageFps,
    required this.lateMinFps,
    required this.masteredRunWinRate,
    required this.nonMasteredRunWinRate,
    required this.repeatRunRate,
  }) : weaponOfferCounts = _immutableSortedMap(weaponOfferCounts),
       weaponSelectionCounts = _immutableSortedMap(weaponSelectionCounts),
       weaponSelectionRates = _immutableSortedMap(weaponSelectionRates),
       weaponDamageShares = _immutableSortedMap(weaponDamageShares),
       weaponLevelAverageTimes = Map.unmodifiable({
         for (final weaponId in weaponLevelAverageTimes.keys.toList()..sort())
           weaponId: Map<int, double>.unmodifiable(
             Map.fromEntries(
               weaponLevelAverageTimes[weaponId]!.entries.toList()
                 ..sort((a, b) => a.key.compareTo(b.key)),
             ),
           ),
       }),
       firstMasterAverageSeconds = _immutableSortedMap(
         firstMasterAverageSeconds,
       ),
       masterKillsInTenSecondsAverage = _immutableSortedMap(
         masterKillsInTenSecondsAverage,
       ),
       firstSynergyAverageSeconds = _immutableSortedMap(
         firstSynergyAverageSeconds,
       ),
       synergyDamageShares = _immutableSortedMap(synergyDamageShares),
       enemyRoleDamageToPlayer = _immutableSortedMap(enemyRoleDamageToPlayer),
       enemyRoleDeathCauses = _immutableSortedMap(enemyRoleDeathCauses);

  final int runCount;
  final Map<String, int> weaponOfferCounts;
  final Map<String, int> weaponSelectionCounts;
  final Map<String, double> weaponSelectionRates;
  final Map<String, double> weaponDamageShares;
  final Map<String, Map<int, double>> weaponLevelAverageTimes;
  final Map<String, double> firstMasterAverageSeconds;
  final Map<String, double> masterKillsInTenSecondsAverage;
  final Map<String, double> firstSynergyAverageSeconds;
  final Map<String, double> synergyDamageShares;
  final double synergyDamageShare;
  final Map<String, double> enemyRoleDamageToPlayer;
  final Map<String, int> enemyRoleDeathCauses;
  final double averageEnemyCount;
  final int maxEnemyCount;
  final double lateAverageFps;
  final double lateMinFps;
  final double masteredRunWinRate;
  final double nonMasteredRunWinRate;
  final double repeatRunRate;
}

class _Average {
  double total = 0;
  int count = 0;

  void add(num value) {
    total += value.toDouble();
    count += 1;
  }

  double get value => _rate(total, count);
}

void _addIntMap(Map<String, int> target, Map<String, int> source) {
  for (final entry in source.entries) {
    target.update(
      entry.key,
      (value) => value + entry.value,
      ifAbsent: () => entry.value,
    );
  }
}

void _addDoubleMap(Map<String, double> target, Map<String, double> source) {
  for (final entry in source.entries) {
    target.update(
      entry.key,
      (value) => value + entry.value,
      ifAbsent: () => entry.value,
    );
  }
}

void _addAverages(Map<String, _Average> target, Map<String, num> source) {
  for (final entry in source.entries) {
    target.putIfAbsent(entry.key, _Average.new).add(entry.value);
  }
}

Map<String, double> _averageMap(Map<String, _Average> source) => {
  for (final entry in source.entries) entry.key: entry.value.value,
};

Map<String, T> _immutableSortedMap<T>(Map<String, T> source) =>
    Map.unmodifiable({
      for (final key in source.keys.toList()..sort()) key: source[key] as T,
    });

double _rate(num numerator, num denominator) =>
    denominator == 0 ? 0 : numerator / denominator;

double _share(double numerator, double denominator) =>
    denominator <= 0 ? 0 : numerator / denominator;

double _minimum(double left, double right) => left < right ? left : right;
