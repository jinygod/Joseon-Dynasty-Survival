import 'package:flutter/foundation.dart';

enum CompendiumSection { character, weapon, augment }

@immutable
class CompendiumEntry {
  const CompendiumEntry({
    required this.key,
    required this.id,
    required this.section,
    required this.name,
    required this.detail,
    required this.isUnlocked,
    required this.isNew,
    required this.unlockCondition,
    required this.currentProgress,
    required this.targetProgress,
    required this.progressFraction,
  });

  final String key;
  final String id;
  final CompendiumSection section;
  final String name;
  final String detail;
  final bool isUnlocked;
  final bool isNew;
  final String unlockCondition;
  final int currentProgress;
  final int targetProgress;
  final double progressFraction;
}
