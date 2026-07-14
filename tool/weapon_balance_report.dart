import 'dart:io';

import 'package:pixel_survivor/game/balance/weapon_balance_baseline.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';

void main() {
  final report = const WeaponBaselineSimulator().simulate();
  stdout.writeln('| 무기 | 레벨 | DPS | 분당 환산 처치 |');
  stdout.writeln('| --- | ---: | ---: | ---: |');
  for (final row in report.rows) {
    if (row.level != 1 && row.level != 5) continue;
    stdout.writeln(
      '| ${_nameFor(row.weaponId)} | ${row.level} | '
      '${row.dps.toStringAsFixed(2)} | '
      '${row.killsPerMinute.toStringAsFixed(1)} |',
    );
  }
  stdout.writeln();
  stdout.writeln(
    '미구현: ${report.unsupportedWeaponIds.map(_nameFor).join(', ')}',
  );
}

String _nameFor(String weaponId) => weaponDefinitions
    .singleWhere((definition) => definition.id == weaponId)
    .name;
