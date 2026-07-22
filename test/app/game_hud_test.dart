import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/game_hud.dart';
import 'package:pixel_survivor/app/game_hud_source.dart';
import 'package:pixel_survivor/app/level_up_overlay.dart';
import 'package:pixel_survivor/game/models/vector_input.dart';
import 'package:pixel_survivor/game/systems/level_up_system.dart';

void main() {
  testWidgets('hud shows boss bar and compact equipped weapon slots', (
    tester,
  ) async {
    final source = FakeGameHudSource(
      bossName: 'Corrupted Guard Captain',
      bossHealthFraction: 0.5,
      weaponLevelLabels: const ['Hwando Slash Lv. 3', 'Talisman Lv. 2'],
    );

    await tester.pumpWidget(MaterialApp(home: GameHud(source: source)));

    expect(find.text('Corrupted Guard Captain'), findsOneWidget);
    expect(find.byKey(const Key('hud-weapon-slot-0')), findsOneWidget);
    expect(find.byKey(const Key('hud-weapon-slot-1')), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('portrait HUD keeps combat controls compact', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final source = FakeGameHudSource(
      bossName: null,
      bossHealthFraction: null,
      weaponLevelLabels: const [
        'Hwando Slash Lv. 6',
        'Talisman Lv. 6',
        'Bow Shot Lv. 5',
        'Fourth weapon must not appear',
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GameHud(source: source, onPause: () {}),
      ),
    );

    expect(
      tester.getSize(find.byKey(const Key('hud-pause'))),
      const Size.square(48),
    );
    expect(
      tester.getSize(find.byKey(const Key('hud-status'))).height,
      lessThanOrEqualTo(92),
    );
    expect(find.byKey(const Key('hud-health-bar')), findsOneWidget);
    expect(find.byKey(const Key('hud-xp-bar')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('hud-health-bar'))).height,
      inInclusiveRange(8, 10),
    );
    expect(
      tester.getSize(find.byKey(const Key('hud-xp-bar'))).height,
      inInclusiveRange(8, 10),
    );
    expect(
      tester.getSize(find.byKey(const Key('virtual-joystick'))),
      const Size.square(104),
    );
    expect(find.byKey(const Key('hud-weapon-slot-0')), findsOneWidget);
    expect(find.byKey(const Key('hud-weapon-slot-1')), findsOneWidget);
    expect(find.byKey(const Key('hud-weapon-slot-2')), findsOneWidget);
    expect(find.byKey(const Key('hud-weapon-slot-3')), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('hud-weapon-slot-0'))),
      const Size.square(32),
    );
  });

  testWidgets('HUD derives visible health fill and weapon badge level', (
    tester,
  ) async {
    final source = FakeGameHudSource(
      bossName: null,
      bossHealthFraction: null,
      weaponLevelLabels: const ['Hwando Slash Lv. 6'],
    );
    await tester.pumpWidget(MaterialApp(home: GameHud(source: source)));

    final bar = tester.getRect(find.byKey(const Key('hud-health-bar')));
    final fill = tester.getRect(find.byKey(const Key('hud-health-fill')));
    expect(fill.width, closeTo(bar.width * 0.8, 0.5));
    expect(
      tester.widget<Text>(find.byKey(const Key('hud-weapon-level-0'))).data,
      '6',
    );
  });

  testWidgets('top status shows kills without a competing enemy count', (
    tester,
  ) async {
    final source = FakeGameHudSource(
      bossName: null,
      bossHealthFraction: null,
      weaponLevelLabels: const [],
    );
    await tester.pumpWidget(MaterialApp(home: GameHud(source: source)));

    expect(
      tester.widget<Text>(find.byKey(const Key('hud-kills-value'))).data,
      '88',
    );
    expect(find.textContaining('20'), findsNothing);
  });

  testWidgets('pause uses one localized semantic button and painted glyph', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GameHud(
          source: FakeGameHudSource(
            bossName: null,
            bossHealthFraction: null,
            weaponLevelLabels: const [],
          ),
          onPause: () {},
        ),
      ),
    );

    expect(find.bySemanticsLabel('일시 정지'), findsOneWidget);
    expect(find.byKey(const Key('hud-pause-glyph')), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsNothing);
  });

  testWidgets('streak uses the centered Korean presentation', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final source = FakeGameHudSource(
      bossName: null,
      bossHealthFraction: null,
      weaponLevelLabels: const [],
      killStreak: 7,
    );
    await tester.pumpWidget(MaterialApp(home: GameHud(source: source)));

    expect(find.text('7 연속 처치'), findsOneWidget);
    final streak = tester.getRect(find.byKey(const Key('kill-streak')));
    expect(streak.center.dx, closeTo(195, 1));
  });

  testWidgets('level-up card shows effect description', (tester) async {
    const choice = LevelUpChoice(
      id: 'inner_breath',
      displayName: 'Inner Breath',
      effectDescription: 'Maximum health +10 and recover 10 health.',
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

  testWidgets('combat notice stays below boss warning and expires', (
    tester,
  ) async {
    final source = FakeGameHudSource(
      bossName: 'Corrupted Guard Captain',
      bossHealthFraction: 0.5,
      weaponLevelLabels: const [],
      combatNotice: 'Sealing Slash',
      combatNoticeSecondsRemaining: 1.2,
      killStreak: 7,
    );

    await tester.pumpWidget(MaterialApp(home: GameHud(source: source)));

    expect(find.text('Sealing Slash'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Sealing Slash')).dy, greaterThan(80));
    expect(find.byKey(const Key('kill-streak')), findsOneWidget);

    source.combatNoticeSecondsRemaining = 0;
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Sealing Slash'), findsNothing);
  });
}

class FakeGameHudSource implements GameHudSource {
  FakeGameHudSource({
    required this.bossName,
    required this.bossHealthFraction,
    required this.weaponLevelLabels,
    this.combatNotice,
    this.combatNoticeSecondsRemaining = 0,
    this.killStreak = 0,
  });

  @override
  final String? bossName;
  @override
  final double? bossHealthFraction;
  @override
  final List<String> weaponLevelLabels;
  @override
  final String? combatNotice;
  @override
  double combatNoticeSecondsRemaining;
  @override
  final int killStreak;
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
