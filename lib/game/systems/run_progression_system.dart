import 'dart:math';

class ExperienceGainResult {
  const ExperienceGainResult({required this.levelsGained});

  final int levelsGained;

  bool get leveledUp => levelsGained > 0;
}

class RunProgressionSystem {
  int _level = 1;
  double _currentExperience = 0;

  int get level => _level;
  int get currentExperience => _currentExperience.floor();
  int get experienceToNextLevel => experienceRequiredForLevel(_level);

  ExperienceGainResult addExperience(
    int amount, {
    double gainMultiplier = 1,
    double requirementMultiplier = 1,
  }) {
    if (amount <= 0) {
      return const ExperienceGainResult(levelsGained: 0);
    }

    final safeGain = gainMultiplier.isFinite ? max(0, gainMultiplier) : 1.0;
    _currentExperience += amount * safeGain;
    var levelsGained = 0;
    while (true) {
      final requiredExperience = experienceRequiredForLevel(
        _level,
        multiplier: requirementMultiplier,
      );
      if (_currentExperience + 1e-9 < requiredExperience) break;
      _currentExperience -= requiredExperience;
      if (_currentExperience < 0 && _currentExperience > -1e-9) {
        _currentExperience = 0;
      }
      _level += 1;
      levelsGained += 1;
    }

    return ExperienceGainResult(levelsGained: levelsGained);
  }

  int experienceRequiredForLevel(int level, {double multiplier = 1}) {
    final safeMultiplier = multiplier.isFinite
        ? multiplier.clamp(0.2, 1).toDouble()
        : 1.0;
    return ((9 + (level * 2)) * safeMultiplier).ceil();
  }
}
