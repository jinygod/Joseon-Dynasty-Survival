class RunProgressionSystem {
  int _level = 1;
  int _currentExperience = 0;

  int get level => _level;
  int get currentExperience => _currentExperience;
  int get experienceToNextLevel => experienceRequiredForLevel(_level);

  bool addExperience(int amount) {
    if (amount <= 0) {
      return false;
    }

    _currentExperience += amount;
    var leveledUp = false;
    while (_currentExperience >= experienceToNextLevel) {
      _currentExperience -= experienceToNextLevel;
      _level += 1;
      leveledUp = true;
    }

    return leveledUp;
  }

  int experienceRequiredForLevel(int level) => 3 + ((level - 1) * 2);
}
