import 'package:flutter/foundation.dart';

@immutable
class WeaponUsageRecord {
  const WeaponUsageRecord({
    required this.weaponId,
    required this.weaponName,
    required this.usageRuns,
    required this.kills,
    required this.damage,
  });

  final String weaponId;
  final String weaponName;
  final int usageRuns;
  final int kills;
  final double damage;
}
