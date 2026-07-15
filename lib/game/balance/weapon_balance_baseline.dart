import '../content/ids.dart';
import '../content/weapon_definitions.dart';
import '../content/weapon_level_definitions.dart';
import '../models/run_choice_record.dart';
import '../models/run_telemetry.dart';

const _runtimeWeaponIds = <WeaponId>{
  hwandoSlash,
  gakgungShot,
  talismanThrow,
  thunderCrashBomb,
  jangseungWard,
  singijeonVolley,
  frostFlask,
  windThunderFan,
};

class WeaponBaselineSimulator {
  const WeaponBaselineSimulator({
    this.durationSeconds = 60,
    this.targetHealth = 20,
    this.crowdTargetsPerArea = 4,
  });

  final double durationSeconds;
  final double targetHealth;
  final int crowdTargetsPerArea;

  WeaponBaselineReport simulate() {
    if (!durationSeconds.isFinite || durationSeconds <= 0) {
      throw ArgumentError.value(durationSeconds, 'durationSeconds');
    }
    if (!targetHealth.isFinite || targetHealth <= 0) {
      throw ArgumentError.value(targetHealth, 'targetHealth');
    }
    if (crowdTargetsPerArea < 1) {
      throw ArgumentError.value(crowdTargetsPerArea, 'crowdTargetsPerArea');
    }

    final rows = <WeaponBaselineRow>[];
    final unsupported = <WeaponId>{};
    for (final definition in weaponDefinitions) {
      final levels = weaponLevels[definition.id];
      if (levels == null || !_runtimeWeaponIds.contains(definition.id)) {
        unsupported.add(definition.id);
        continue;
      }
      for (var index = 0; index < levels.length; index += 1) {
        final level = index + 1;
        final stats = levels[index];
        final attacks =
            ((durationSeconds - 1e-9) / stats.cooldownSeconds).floor() + 1;
        final hitsPerAttack = _hitsPerAttack(definition.id, stats);
        final damage = attacks * hitsPerAttack * stats.damage;
        rows.add(
          WeaponBaselineRow(
            weaponId: definition.id,
            level: level,
            attacks: attacks,
            hitsPerAttack: hitsPerAttack,
            damage: damage,
            dps: damage / durationSeconds,
            killsPerMinute:
                (damage / targetHealth).floor() * 60 / durationSeconds,
          ),
        );
      }
    }

    return WeaponBaselineReport(
      durationSeconds: durationSeconds,
      targetHealth: targetHealth,
      rows: rows,
      unsupportedWeaponIds: unsupported,
    );
  }

  int _hitsPerAttack(WeaponId weaponId, WeaponLevelDefinition stats) =>
      switch (weaponId) {
        hwandoSlash => stats.projectileCount,
        gakgungShot => stats.projectileCount * (stats.pierce + 1),
        talismanThrow => stats.chainCount,
        thunderCrashBomb => stats.projectileCount * crowdTargetsPerArea,
        jangseungWard => crowdTargetsPerArea,
        singijeonVolley => stats.projectileCount * (stats.pierce + 1),
        frostFlask =>
          crowdTargetsPerArea * (stats.durationSeconds / .5).floor(),
        windThunderFan => stats.projectileCount * 2,
        _ => throw ArgumentError.value(weaponId, 'weaponId'),
      };
}

class WeaponBaselineReport {
  WeaponBaselineReport({
    required this.durationSeconds,
    required this.targetHealth,
    required List<WeaponBaselineRow> rows,
    required Set<WeaponId> unsupportedWeaponIds,
  }) : rows = List.unmodifiable(rows),
       unsupportedWeaponIds = Set.unmodifiable(unsupportedWeaponIds);

  final double durationSeconds;
  final double targetHealth;
  final List<WeaponBaselineRow> rows;
  final Set<WeaponId> unsupportedWeaponIds;

  Set<WeaponId> get supportedWeaponIds =>
      rows.map((row) => row.weaponId).toSet();

  WeaponBaselineRow rowFor(WeaponId weaponId, int level) =>
      rows.singleWhere((row) => row.weaponId == weaponId && row.level == level);

  Map<String, Object> toJson() => {
    'durationSeconds': durationSeconds,
    'targetHealth': targetHealth,
    'rows': rows.map((row) => row.toJson()).toList(growable: false),
    'unsupportedWeaponIds': unsupportedWeaponIds.toList()..sort(),
  };
}

class WeaponBaselineRow {
  const WeaponBaselineRow({
    required this.weaponId,
    required this.level,
    required this.attacks,
    required this.hitsPerAttack,
    required this.damage,
    required this.dps,
    required this.killsPerMinute,
  });

  final WeaponId weaponId;
  final int level;
  final int attacks;
  final int hitsPerAttack;
  final double damage;
  final double dps;
  final double killsPerMinute;

  Map<String, Object> toJson() => {
    'weaponId': weaponId,
    'level': level,
    'attacks': attacks,
    'hitsPerAttack': hitsPerAttack,
    'damage': damage,
    'dps': dps,
    'killsPerMinute': killsPerMinute,
  };
}

class WeaponUsageAggregator {
  const WeaponUsageAggregator();

  List<WeaponObservedBaseline> aggregate(Iterable<RunTelemetry> runs) {
    final runList = runs.toList(growable: false);
    if (runList.isEmpty) return const [];
    final totals = <WeaponId, _ObservedTotals>{};

    for (final run in runList) {
      final usedIds = <WeaponId>{
        ...run.weaponDamageTotals.keys,
        ...run.weaponKillCounts.keys,
        ...run.choices
            .where((choice) => choice.type == RunChoiceType.weapon)
            .map((choice) => choice.contentId),
      };
      for (final weaponId in usedIds) {
        final total = totals.putIfAbsent(weaponId, _ObservedTotals.new);
        total.usedRuns += 1;
        if (run.survivalSeconds > 0) {
          total.observedSeconds += run.survivalSeconds;
        }
        total.damage += run.weaponDamageTotals[weaponId] ?? 0;
        total.kills += run.weaponKillCounts[weaponId] ?? 0;
      }
    }

    final orderedIds = totals.keys.toList()
      ..sort((a, b) => _weaponOrder(a).compareTo(_weaponOrder(b)));
    return [
      for (final weaponId in orderedIds)
        WeaponObservedBaseline._fromTotals(
          weaponId: weaponId,
          totalRuns: runList.length,
          totals: totals[weaponId]!,
        ),
    ];
  }

  static int _weaponOrder(WeaponId id) {
    final index = weaponDefinitions.indexWhere(
      (definition) => definition.id == id,
    );
    return index < 0 ? weaponDefinitions.length : index;
  }
}

class WeaponObservedBaseline {
  const WeaponObservedBaseline({
    required this.weaponId,
    required this.usedRuns,
    required this.usageRate,
    required this.observedDps,
    required this.killsPerMinute,
  });

  factory WeaponObservedBaseline._fromTotals({
    required WeaponId weaponId,
    required int totalRuns,
    required _ObservedTotals totals,
  }) {
    final observedMinutes = totals.observedSeconds / 60;
    return WeaponObservedBaseline(
      weaponId: weaponId,
      usedRuns: totals.usedRuns,
      usageRate: totals.usedRuns / totalRuns,
      observedDps: totals.observedSeconds == 0
          ? 0
          : totals.damage / totals.observedSeconds,
      killsPerMinute: observedMinutes == 0 ? 0 : totals.kills / observedMinutes,
    );
  }

  final WeaponId weaponId;
  final int usedRuns;
  final double usageRate;
  final double observedDps;
  final double killsPerMinute;
}

class _ObservedTotals {
  int usedRuns = 0;
  int observedSeconds = 0;
  double damage = 0;
  int kills = 0;
}
