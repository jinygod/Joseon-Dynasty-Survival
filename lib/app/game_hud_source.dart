import '../game/models/vector_input.dart';

abstract interface class GameHudSource {
  double get elapsedSeconds;
  String get playerHealthLabel;
  int get playerLevel;
  int get currentExperience;
  int get experienceToNextLevel;
  int get enemyCount;
  int get kills;
  String? get bossName;
  double? get bossHealthFraction;
  List<String> get weaponLevelLabels;

  void updateMovementInput(VectorInput input);
}
