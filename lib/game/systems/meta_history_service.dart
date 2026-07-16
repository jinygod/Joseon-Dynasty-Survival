import '../content/weapon_definitions.dart';
import '../models/meta_history.dart';
import '../models/run_telemetry.dart';
import 'telemetry_repository.dart';

typedef TelemetryHistoryLoader = Future<List<RunTelemetry>> Function();

class MetaHistoryService {
  MetaHistoryService({TelemetryHistoryLoader? loadHistory})
    : _loadHistory = loadHistory ?? TelemetryRepository().load;

  final TelemetryHistoryLoader _loadHistory;

  Future<List<WeaponUsageRecord>> loadWeaponUsage() async {
    List<RunTelemetry> history;
    try {
      history = await _loadHistory();
    } on Object {
      return const [];
    }

    final knownIds = weaponDefinitions.map((item) => item.id).toSet();
    final usageRuns = <String, int>{};
    final kills = <String, int>{};
    final damage = <String, double>{};
    for (final run in history) {
      final usedIds = {
        ...run.weaponKillCounts.keys,
        ...run.weaponDamageTotals.keys,
      }.where(knownIds.contains);
      for (final id in usedIds) {
        usageRuns[id] = (usageRuns[id] ?? 0) + 1;
      }
      for (final entry in run.weaponKillCounts.entries) {
        if (!knownIds.contains(entry.key)) continue;
        kills[entry.key] = (kills[entry.key] ?? 0) + entry.value;
      }
      for (final entry in run.weaponDamageTotals.entries) {
        if (!knownIds.contains(entry.key)) continue;
        damage[entry.key] = (damage[entry.key] ?? 0) + entry.value;
      }
    }

    return List.unmodifiable([
      for (final definition in weaponDefinitions)
        if (usageRuns.containsKey(definition.id))
          WeaponUsageRecord(
            weaponId: definition.id,
            weaponName: definition.name,
            usageRuns: usageRuns[definition.id]!,
            kills: kills[definition.id] ?? 0,
            damage: damage[definition.id] ?? 0,
          ),
    ]);
  }
}
