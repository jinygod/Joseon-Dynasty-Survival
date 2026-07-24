import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/game_hud.dart';
import 'package:pixel_survivor/app/game_hud_source.dart';
import 'package:pixel_survivor/app/level_up_overlay.dart';
import 'package:pixel_survivor/app/weapon_star_rating.dart';
import 'package:pixel_survivor/game/models/vector_input.dart';
import 'package:pixel_survivor/game/systems/level_up_system.dart';

void main() {
  testWidgets('combat hud labels kills and shows mastery for level six', (
    tester,
  ) async {
    final source = FakeGameHudSource(
      bossName: null,
      bossHealthFraction: null,
      kills: 119,
      weaponLevelLabels: const ['Hwando Slash Lv. 6'],
    );

    await tester.pumpWidget(MaterialApp(home: GameHud(source: source)));

    expect(find.byKey(const Key('kill-count-icon')), findsOneWidget);
    expect(find.text('119'), findsOneWidget);
    expect(find.byType(WeaponStarRating), findsOneWidget);
    expect(
      tester.widget<WeaponStarRating>(find.byType(WeaponStarRating)).level,
      6,
    );
    expect(
      find.text(String.fromCharCodes(const [53685, 45804])),
      findsOneWidget,
    );
    expect(find.byKey(const Key('filled-star-5')), findsNothing);
  });

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
    expect(find.byKey(const Key('hud-weapon-slot-1')), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('portrait HUD keeps combat controls compact', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    final source = FakeGameHudSource(
      bossName: null,
      bossHealthFraction: null,
      playerLevel: 1,
      currentExperience: 4,
      experienceToNextLevel: 12,
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
      lessThanOrEqualTo(64),
    );
    final pause = tester.getRect(find.byKey(const Key('hud-pause')));
    final status = tester.getRect(find.byKey(const Key('hud-status')));
    expect(status.top, greaterThanOrEqualTo(24));
    expect(status.left, 0);
    expect(status.right, 390);
    expect(status.width, 390);
    expect(
      tester.widget<Text>(find.byKey(const Key('hud-player-level'))).data,
      '레벨 1',
    );
    expect(find.text('4/12'), findsOneWidget);
    expect(find.byKey(const Key('hud-health-bar')), findsNothing);
    expect(find.byKey(const Key('hud-xp-bar')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('hud-xp-bar'))).height,
      inInclusiveRange(14, 18),
    );
    final xpBar = tester.getRect(find.byKey(const Key('hud-xp-bar')));
    final xpFill = tester.getRect(find.byKey(const Key('hud-xp-fill')));
    expect(xpBar.left, greaterThanOrEqualTo(pause.right));
    expect(xpBar.width, greaterThanOrEqualTo(220));
    expect(xpFill.width, closeTo(xpBar.width / 3, 0.5));
    expect(
      tester.getSize(find.byKey(const Key('virtual-joystick'))),
      const Size(390, 820),
    );
    expect(
      tester.getSize(find.byKey(const Key('virtual-joystick-base'))),
      const Size.square(104),
    );
    expect(find.byKey(const Key('hud-weapon-slot-0')), findsOneWidget);
    expect(find.byKey(const Key('hud-weapon-slot-1')), findsNothing);
    expect(find.byKey(const Key('hud-weapon-slot-2')), findsNothing);
    expect(find.byKey(const Key('hud-weapon-slot-3')), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('hud-weapon-slot-0'))),
      const Size.square(22),
    );
    final coreWeapon = tester.getRect(find.byKey(const Key('hud-core-weapon')));
    final rating = tester.getRect(
      find.byKey(const Key('hud-core-weapon-rating')),
    );
    expect(rating.height, greaterThanOrEqualTo(12));
    expect(coreWeapon.right, lessThanOrEqualTo(status.right));
    expect(coreWeapon.bottom, lessThanOrEqualTo(status.bottom));
  });

  testWidgets('HUD keeps the compact weapon mastery rating', (tester) async {
    final source = FakeGameHudSource(
      bossName: null,
      bossHealthFraction: null,
      weaponLevelLabels: const ['Hwando Slash Lv. 6'],
    );
    await tester.pumpWidget(MaterialApp(home: GameHud(source: source)));

    expect(find.byKey(const Key('hud-health-bar')), findsNothing);
    expect(find.byType(WeaponStarRating), findsOneWidget);
    expect(
      tester.widget<WeaponStarRating>(find.byType(WeaponStarRating)).level,
      6,
    );
    expect(
      find.text(String.fromCharCodes(const [53685, 45804])),
      findsOneWidget,
    );
    expect(find.byKey(const Key('filled-star-5')), findsNothing);
  });

  for (final size in const [Size(375, 667), Size(390, 844), Size(430, 932)]) {
    testWidgets('core-only HUD remains readable at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final source = FakeGameHudSource(
        bossName: null,
        bossHealthFraction: null,
        weaponLevelLabels: const [
          'Hwando Slash Lv. 6',
          'Talisman Lv. 5',
          'Bow Shot Lv. 4',
        ],
      );

      await tester.pumpWidget(MaterialApp(home: GameHud(source: source)));

      expect(find.byKey(const Key('hud-weapon-slot-0')), findsOneWidget);
      expect(find.byKey(const Key('hud-weapon-slot-1')), findsNothing);
      expect(find.byKey(const Key('hud-weapon-slot-2')), findsNothing);
      expect(find.byKey(const Key('hud-core-weapon-rating')), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('virtual-joystick-base'))),
        const Size.square(104),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('weapon slots expose name and level in the semantics tree', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    const label = '부적 투척 레벨 6';
    final source = FakeGameHudSource(
      bossName: null,
      bossHealthFraction: null,
      weaponLevelLabels: const [label],
    );

    await tester.pumpWidget(MaterialApp(home: GameHud(source: source)));

    expect(
      tester.getSemantics(find.byKey(const Key('hud-weapon-slot-0'))).label,
      label,
    );
    semantics.dispose();
  });

  testWidgets('core weapon mark follows the first equipped weapon', (
    tester,
  ) async {
    final source = FakeGameHudSource(
      bossName: null,
      bossHealthFraction: null,
      weaponLevelLabels: const ['부적 투척 레벨 6', '각궁 사격 레벨 5', '환도 베기 레벨 6'],
    );

    await tester.pumpWidget(MaterialApp(home: GameHud(source: source)));

    expect(find.byKey(const Key('hud-weapon-mark-0-talisman')), findsOneWidget);
    expect(find.byKey(const Key('hud-weapon-mark-1-projectile')), findsNothing);
    expect(find.byKey(const Key('hud-weapon-mark-2-hwando')), findsNothing);
  });

  testWidgets('a talisman-only legacy source still paints a talisman', (
    tester,
  ) async {
    final source = FakeGameHudSource(
      bossName: null,
      bossHealthFraction: null,
      weaponLevelLabels: const ['Talisman Lv. 4'],
    );

    await tester.pumpWidget(MaterialApp(home: GameHud(source: source)));

    expect(find.byKey(const Key('hud-weapon-mark-0-talisman')), findsOneWidget);
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

  testWidgets(
    'large kill value stays inside the compact panel at text scale two',
    (tester) async {
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
        ],
        kills: 9223372036854775807,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              textScaler: TextScaler.linear(2),
            ),
            child: GameHud(source: source, onPause: () {}),
          ),
        ),
      );

      final status = tester.getRect(find.byKey(const Key('hud-status')));
      final kills = tester.getRect(find.byKey(const Key('hud-kills-value')));
      expect(kills.left, greaterThanOrEqualTo(status.left));
      expect(kills.right, lessThanOrEqualTo(status.right));
      expect(kills.bottom, lessThanOrEqualTo(status.bottom));
      expect(tester.takeException(), isNull);
    },
  );

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

  testWidgets('streak does not add a persistent combat row', (tester) async {
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

    expect(find.byKey(const Key('kill-streak')), findsNothing);
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
    expect(find.text('레벨 0 → 1'), findsOneWidget);
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
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: GameHud(source: source, onPause: () => pauses += 1),
      ),
    );

    expect(find.byKey(const Key('virtual-joystick')), findsOneWidget);
    await tester.tap(find.byKey(const Key('hud-pause')));
    expect(pauses, 1);
  });

  testWidgets('combat notice does not add a persistent HUD row', (
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

    expect(find.text('Sealing Slash'), findsNothing);
    expect(find.byKey(const Key('kill-streak')), findsNothing);

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
    this.playerLevel = 9,
    this.currentExperience = 4,
    this.experienceToNextLevel = 12,
    this.kills = 88,
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
  final int playerLevel;
  @override
  final int currentExperience;
  @override
  final int experienceToNextLevel;
  @override
  int get enemyCount => 20;
  @override
  final int kills;
  @override
  void updateMovementInput(VectorInput input) {}
}
