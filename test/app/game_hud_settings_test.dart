import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/game_hud.dart';
import 'package:pixel_survivor/app/game_hud_source.dart';
import 'package:pixel_survivor/game/models/vector_input.dart';

void main() {
  testWidgets('HUD applies the selected UI scale', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: GameHud(source: _HudSource(), uiScale: 1.15)),
    );

    final transform = tester.widget<Transform>(
      find.byKey(const Key('hud-ui-scale')),
    );
    expect(transform.transform.getMaxScaleOnAxis(), closeTo(1.15, 0.001));
  });
}

class _HudSource implements GameHudSource {
  @override
  String? get bossName => null;
  @override
  double? get bossHealthFraction => null;
  @override
  int get currentExperience => 0;
  @override
  double get elapsedSeconds => 0;
  @override
  int get experienceToNextLevel => 10;
  @override
  int get enemyCount => 0;
  @override
  int get kills => 0;
  @override
  int get playerLevel => 1;
  @override
  String get playerHealthLabel => '100/100';
  @override
  List<String> get weaponLevelLabels => const [];
  @override
  void updateMovementInput(VectorInput input) {}
}
