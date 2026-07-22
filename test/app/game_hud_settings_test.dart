import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/game_hud.dart';
import 'package:pixel_survivor/app/game_hud_source.dart';
import 'package:pixel_survivor/game/models/vector_input.dart';

void main() {
  testWidgets(
    'large HUD keeps safe-area anchors and scales individual controls',
    (tester) async {
      final source = _HudSource();
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 300),
              padding: EdgeInsets.only(left: 30, bottom: 20),
            ),
            child: GameHud(source: source, uiScale: 1.15),
          ),
        ),
      );

      expect(find.byKey(const Key('hud-ui-scale')), findsNothing);
      final joystick = find.byKey(const Key('virtual-joystick'));
      expect(tester.getSize(joystick), const Size.square(104));
      expect(tester.getTopLeft(joystick), const Offset(48, 458));
      final gesture = await tester.startGesture(tester.getCenter(joystick));
      await gesture.moveBy(const Offset(55, 0));
      await gesture.up();
      expect(source.nonZeroInputs, isNotEmpty);
      expect(source.nonZeroInputs.last.x, greaterThan(0.5));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pause remains pinned to the safe-area top left at large scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(left: 24, top: 16),
          ),
          child: GameHud(source: _HudSource(), uiScale: 1.15, onPause: () {}),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.byKey(const Key('hud-pause'))),
      const Offset(32, 24),
    );
  });
}

class _HudSource implements GameHudSource {
  final List<VectorInput> nonZeroInputs = [];
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
  String? get combatNotice => null;
  @override
  double get combatNoticeSecondsRemaining => 0;
  @override
  int get killStreak => 0;
  @override
  int get playerLevel => 1;
  @override
  String get playerHealthLabel => '100/100';
  @override
  List<String> get weaponLevelLabels => const [];
  @override
  void updateMovementInput(VectorInput input) {
    if (input != VectorInput.zero) nonZeroInputs.add(input);
  }
}
