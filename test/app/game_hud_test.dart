import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/game_hud.dart';
import 'package:pixel_survivor/app/game_hud_source.dart';
import 'package:pixel_survivor/app/level_up_overlay.dart';
import 'package:pixel_survivor/game/models/vector_input.dart';
import 'package:pixel_survivor/game/systems/level_up_system.dart';

void main() {
  testWidgets('hud shows boss bar and all equipped weapons', (tester) async {
    final source = FakeGameHudSource(
      bossName: '타락한 관군 대장',
      bossHealthFraction: 0.5,
      weaponLevelLabels: const ['환도 베기 Lv 3', '각궁 사격 Lv 2'],
    );

    await tester.pumpWidget(MaterialApp(home: GameHud(source: source)));

    expect(find.text('타락한 관군 대장'), findsOneWidget);
    expect(find.text('환도 베기 Lv 3'), findsOneWidget);
    expect(find.text('각궁 사격 Lv 2'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('level-up card shows effect description', (tester) async {
    const choice = LevelUpChoice(
      id: 'inner_breath',
      displayName: '내공 호흡',
      effectDescription: '최대 체력 +10, 체력 10 회복',
      type: LevelUpChoiceType.augment,
      currentLevel: 0,
      nextLevel: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LevelUpOverlay(choices: const [choice], onChoiceSelected: (_) {}),
      ),
    );

    expect(find.text(choice.displayName), findsOneWidget);
    expect(find.text('Lv 0 -> 1'), findsOneWidget);
    expect(find.text(choice.effectDescription), findsOneWidget);
  });

  testWidgets('hud shows production joystick and invokes pause', (
    tester,
  ) async {
    var pauses = 0;
    final source = FakeGameHudSource(
      bossName: null,
      bossHealthFraction: null,
      weaponLevelLabels: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GameHud(source: source, onPause: () => pauses += 1),
      ),
    );

    expect(find.byKey(const Key('virtual-joystick')), findsOneWidget);
    await tester.tap(find.byKey(const Key('hud-pause')));
    expect(pauses, 1);
  });
}

class FakeGameHudSource implements GameHudSource {
  FakeGameHudSource({
    required this.bossName,
    required this.bossHealthFraction,
    required this.weaponLevelLabels,
  });

  @override
  final String? bossName;
  @override
  final double? bossHealthFraction;
  @override
  final List<String> weaponLevelLabels;
  @override
  double get elapsedSeconds => 275;
  @override
  String get playerHealthLabel => '80/100';
  @override
  int get playerLevel => 9;
  @override
  int get currentExperience => 4;
  @override
  int get experienceToNextLevel => 12;
  @override
  int get enemyCount => 20;
  @override
  int get kills => 88;
  @override
  void updateMovementInput(VectorInput input) {}
}
