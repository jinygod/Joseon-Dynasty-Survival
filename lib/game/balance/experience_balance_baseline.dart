import 'dart:math';

import '../content/enemy_definitions.dart';
import '../content/wave_definitions.dart';
import '../systems/run_progression_system.dart';

const defaultExperienceProfiles = <ExperienceAcquisitionProfile>[
  ExperienceAcquisitionProfile(id: 'beginner', acquisitionRate: 0.18),
  ExperienceAcquisitionProfile(id: 'expected', acquisitionRate: 0.25),
  ExperienceAcquisitionProfile(id: 'strong', acquisitionRate: 0.30),
];

class ExperienceAcquisitionProfile {
  const ExperienceAcquisitionProfile({
    required this.id,
    required this.acquisitionRate,
  });

  final String id;
  final double acquisitionRate;
}

class ExperienceBalanceSimulator {
  const ExperienceBalanceSimulator({
    this.durationSeconds = 300,
    this.minimumTargetLevelUps = 8,
    this.maximumTargetLevelUps = 12,
  });

  final int durationSeconds;
  final int minimumTargetLevelUps;
  final int maximumTargetLevelUps;

  ExperienceBalanceReport simulate({
    List<ExperienceAcquisitionProfile> profiles = defaultExperienceProfiles,
  }) {
    if (durationSeconds <= 0) {
      throw ArgumentError.value(durationSeconds, 'durationSeconds');
    }
    if (profiles.isEmpty) {
      throw ArgumentError.value(profiles, 'profiles', 'must not be empty');
    }
    for (final profile in profiles) {
      if (!profile.acquisitionRate.isFinite ||
          profile.acquisitionRate < 0 ||
          profile.acquisitionRate > 1) {
        throw ArgumentError.value(
          profile.acquisitionRate,
          'acquisitionRate',
          'must be between 0 and 1',
        );
      }
    }

    final expectedSpawnedExperience = _expectedSpawnedExperience();
    final results = <ExperienceProfileResult>[];
    for (final profile in profiles) {
      final earnedExperience =
          (expectedSpawnedExperience * profile.acquisitionRate).floor();
      final progression = RunProgressionSystem()
        ..addExperience(earnedExperience);
      results.add(
        ExperienceProfileResult(
          profileId: profile.id,
          acquisitionRate: profile.acquisitionRate,
          earnedExperience: earnedExperience,
          levelUps: progression.level - 1,
          finalLevel: progression.level,
          remainingExperience: progression.currentExperience,
        ),
      );
    }

    return ExperienceBalanceReport(
      durationSeconds: durationSeconds,
      expectedSpawnedExperience: expectedSpawnedExperience,
      minimumTargetLevelUps: minimumTargetLevelUps,
      maximumTargetLevelUps: maximumTargetLevelUps,
      profileResults: results,
    );
  }

  int costForLevel(int level) =>
      RunProgressionSystem().experienceRequiredForLevel(level);

  int experienceForLevelUps(int count) {
    if (count < 0) throw ArgumentError.value(count, 'count');
    var total = 0;
    for (var level = 1; level <= count; level += 1) {
      total += costForLevel(level);
    }
    return total;
  }

  double _expectedSpawnedExperience() {
    var total = 0.0;
    for (final wave in waveDefinitions) {
      final activeSeconds = max(
        0,
        min(durationSeconds, wave.endSecond) - wave.startSecond,
      );
      if (activeSeconds == 0) continue;
      final totalWeight = wave.enemyWeights.values.fold<int>(
        0,
        (sum, weight) => sum + weight,
      );
      final weightedExperience = wave.enemyWeights.entries.fold<double>(
        0,
        (sum, entry) => sum + _experienceForEnemy(entry.key) * entry.value,
      );
      final averageExperience = weightedExperience / totalWeight;
      final eliteMultiplier = 1 + (wave.eliteChance * 2);
      total +=
          activeSeconds *
          wave.spawnsPerSecond *
          averageExperience *
          eliteMultiplier;
    }
    return total;
  }

  int _experienceForEnemy(String enemyId) => enemyDefinitions
      .singleWhere((definition) => definition.id == enemyId)
      .experience;
}

class ExperienceBalanceReport {
  ExperienceBalanceReport({
    required this.durationSeconds,
    required this.expectedSpawnedExperience,
    required this.minimumTargetLevelUps,
    required this.maximumTargetLevelUps,
    required List<ExperienceProfileResult> profileResults,
  }) : profileResults = List.unmodifiable(profileResults);

  final int durationSeconds;
  final double expectedSpawnedExperience;
  final int minimumTargetLevelUps;
  final int maximumTargetLevelUps;
  final List<ExperienceProfileResult> profileResults;

  double get averageLevelUps =>
      profileResults.fold<int>(0, (sum, result) => sum + result.levelUps) /
      profileResults.length;

  bool get meetsTargetBand => profileResults.every(
    (result) =>
        result.levelUps >= minimumTargetLevelUps &&
        result.levelUps <= maximumTargetLevelUps,
  );

  Map<String, Object> toJson() => {
    'durationSeconds': durationSeconds,
    'expectedSpawnedExperience': expectedSpawnedExperience,
    'minimumTargetLevelUps': minimumTargetLevelUps,
    'maximumTargetLevelUps': maximumTargetLevelUps,
    'averageLevelUps': averageLevelUps,
    'meetsTargetBand': meetsTargetBand,
    'profileResults': profileResults
        .map((result) => result.toJson())
        .toList(growable: false),
  };
}

class ExperienceProfileResult {
  const ExperienceProfileResult({
    required this.profileId,
    required this.acquisitionRate,
    required this.earnedExperience,
    required this.levelUps,
    required this.finalLevel,
    required this.remainingExperience,
  });

  final String profileId;
  final double acquisitionRate;
  final int earnedExperience;
  final int levelUps;
  final int finalLevel;
  final int remainingExperience;

  Map<String, Object> toJson() => {
    'profileId': profileId,
    'acquisitionRate': acquisitionRate,
    'earnedExperience': earnedExperience,
    'levelUps': levelUps,
    'finalLevel': finalLevel,
    'remainingExperience': remainingExperience,
  };
}
