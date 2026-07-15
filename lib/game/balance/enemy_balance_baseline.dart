import '../content/character_definitions.dart';
import '../content/enemy_definitions.dart';
import '../content/ids.dart';
import '../content/wave_definitions.dart';
import '../content/weapon_definitions.dart';
import '../content/weapon_level_definitions.dart';
import '../systems/combat_system.dart';

class EnemyBalanceAnalyzer {
  const EnemyBalanceAnalyzer();

  EnemyBalanceReport analyze() {
    final starter = characterDefinitions.singleWhere(
      (character) => character.id == rookieConstable,
    );
    final starterWeapon = weaponLevelFor(hwandoSlash, 1);
    final rows = <EnemyBalanceRow>[
      for (final enemy in enemyDefinitions.where((enemy) => !enemy.isBoss))
        _rowFor(enemy, starter, starterWeapon),
    ];
    final preBossWaves = waveDefinitions
        .where((wave) => wave.endSecond <= 270)
        .toList(growable: false);
    final bossWave = waveDefinitions.firstWhere(
      (wave) => wave.startSecond == 270,
    );
    return EnemyBalanceReport(
      rows: rows,
      preBossActiveCaps: [
        for (final wave in preBossWaves)
          wavePressureForSecond(wave.endSecond - 0.001).maxActiveEnemies,
      ],
      preBossSpawnRates: [
        for (final wave in preBossWaves)
          wavePressureForSecond(wave.endSecond - 0.001).spawnsPerSecond,
      ],
      bossActiveCap: wavePressureForSecond(
        bossWave.startSecond.toDouble(),
      ).maxActiveEnemies,
    );
  }

  EnemyBalanceRow _rowFor(
    EnemyDefinition enemy,
    CharacterDefinition starter,
    WeaponLevelDefinition starterWeapon,
  ) {
    final hitsToKill = (enemy.maxHealth / starterWeapon.damage).ceil();
    final contactHitsToDefeat = (starter.maxHealth / enemy.damage).ceil();
    return EnemyBalanceRow(
      enemyId: enemy.id,
      starterHitsToKill: hitsToKill,
      starterTimeToKillSeconds:
          (hitsToKill - 1) * starterWeapon.cooldownSeconds,
      continuousContactSurvivalSeconds:
          (contactHitsToDefeat - 1) * CombatSystem.contactCooldownSeconds,
      speedRatio: enemy.moveSpeed / starter.moveSpeed,
    );
  }
}

class EnemyBalanceReport {
  EnemyBalanceReport({
    required List<EnemyBalanceRow> rows,
    required List<int> preBossActiveCaps,
    required List<double> preBossSpawnRates,
    required this.bossActiveCap,
  }) : rows = List.unmodifiable(rows),
       preBossActiveCaps = List.unmodifiable(preBossActiveCaps),
       preBossSpawnRates = List.unmodifiable(preBossSpawnRates);

  final List<EnemyBalanceRow> rows;
  final List<int> preBossActiveCaps;
  final List<double> preBossSpawnRates;
  final int bossActiveCap;

  EnemyBalanceRow rowFor(EnemyId enemyId) =>
      rows.singleWhere((row) => row.enemyId == enemyId);

  bool get meetsSafetyTargets =>
      rowFor(plagueRatSwarm).starterHitsToKill == 1 &&
      rows.every(
        (row) =>
            row.starterTimeToKillSeconds <= 3 &&
            row.continuousContactSurvivalSeconds >= 4 &&
            row.speedRatio < 0.5,
      ) &&
      hasMonotonicPreBossPressure &&
      bossActiveCap < preBossActiveCaps.last;

  bool get hasMonotonicPreBossPressure =>
      _strictlyIncreasing(preBossActiveCaps) &&
      _strictlyIncreasing(preBossSpawnRates);

  bool _strictlyIncreasing(List<num> values) {
    for (var index = 1; index < values.length; index += 1) {
      if (values[index] <= values[index - 1]) return false;
    }
    return true;
  }
}

class EnemyBalanceRow {
  const EnemyBalanceRow({
    required this.enemyId,
    required this.starterHitsToKill,
    required this.starterTimeToKillSeconds,
    required this.continuousContactSurvivalSeconds,
    required this.speedRatio,
  });

  final EnemyId enemyId;
  final int starterHitsToKill;
  final double starterTimeToKillSeconds;
  final double continuousContactSurvivalSeconds;
  final double speedRatio;
}
