import 'dart:math';

class RunProgressionSystem {
  int _level = 1;
  double _currentExperience = 0;

  int get level => _level;
  int get currentExperience => _currentExperience.floor();
  int get experienceToNextLevel => experienceRequiredForLevel(_level);

  bool addExperience(
    int amount, {
    double gainMultiplier = 1,
    double requirementMultiplier = 1,
  }) {
    if (amount <= 0) {
      return false;
    }

    final safeGain = gainMultiplier.isFinite ? max(0, gainMultiplier) : 1.0;
    _currentExperience += amount * safeGain;
    var leveledUp = false;
    while (_currentExperience + 1e-9 >=
        experienceRequiredForLevel(_level, multiplier: requirementMultiplier)) {
      _currentExperience -= experienceRequiredForLevel(
        _level,
        multiplier: requirementMultiplier,
      );
      _level += 1;
      leveledUp = true;
    }

    return leveledUp;
  }

  int experienceRequiredForLevel(int level, {double multiplier = 1}) {
    final safeMultiplier = multiplier.isFinite
        ? multiplier.clamp(0.2, 1).toDouble()
        : 1.0;
    return ((9 + (level * 2)) * safeMultiplier).ceil();
  }
}
