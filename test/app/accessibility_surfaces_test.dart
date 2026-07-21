import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/accessible_status_badge.dart';
import 'package:pixel_survivor/app/compendium_screen.dart';
import 'package:pixel_survivor/app/game_hud.dart';
import 'package:pixel_survivor/app/game_hud_source.dart';
import 'package:pixel_survivor/app/records_screen.dart';
import 'package:pixel_survivor/game/models/vector_input.dart';
import 'package:pixel_survivor/game/systems/meta_history_service.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';

void main() {
  testWidgets('status badge distinguishes state with icon label and outline', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AccessibleStatusBadge(
            icon: Icons.lock_outline,
            label: '잠김',
            semanticsLabel: '잠긴 항목',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.text('잠김'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(AccessibleStatusBadge)).label,
      contains('잠긴 항목'),
    );
    final decorated = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    expect((decorated.decoration as BoxDecoration).border, isNotNull);
    semantics.dispose();
  });

  testWidgets('large text keeps compendium and records scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const media = MediaQueryData(
      size: Size(320, 568),
      textScaler: TextScaler.linear(2),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: media,
          child: CompendiumScreen(state: SaveState.defaults()),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(AccessibleStatusBadge), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: media,
          child: RecordsScreen(
            state: SaveState.defaults(),
            historyService: MetaHistoryService(loadHistory: () async => []),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -250));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('HUD tolerates UI 1.15 and system text scale two', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 450);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(800, 450),
            textScaler: TextScaler.linear(2),
          ),
          child: GameHud(source: _HudSource(), uiScale: 1.15),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'active combat notice and streak are accessibility live regions',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(home: GameHud(source: _ActiveHudSource())),
      );

      final notice = tester.widget<Semantics>(
        find.byKey(const Key('combat-notice')),
      );
      final streak = tester.widget<Semantics>(
        find.byKey(const Key('kill-streak')),
      );
      expect(notice.properties.liveRegion, isTrue);
      expect(notice.properties.label, contains('봉마참'));
      expect(streak.properties.liveRegion, isTrue);
      expect(streak.properties.label, contains('7'));
      semantics.dispose();
    },
  );
}

class _HudSource implements GameHudSource {
  @override
  String? get bossName => '긴 보스 이름';
  @override
  double? get bossHealthFraction => 0.5;
  @override
  int get currentExperience => 123;
  @override
  double get elapsedSeconds => 123;
  @override
  int get experienceToNextLevel => 456;
  @override
  int get enemyCount => 99;
  @override
  int get kills => 999;
  @override
  String? get combatNotice => null;
  @override
  double get combatNoticeSecondsRemaining => 0;
  @override
  int get killStreak => 0;
  @override
  int get playerLevel => 15;
  @override
  String get playerHealthLabel => '100/100';
  @override
  List<String> get weaponLevelLabels => const [
    '매우 긴 무기 이름 첫 번째 5단계',
    '매우 긴 무기 이름 두 번째 5단계',
  ];
  @override
  void updateMovementInput(VectorInput input) {}
}

class _ActiveHudSource extends _HudSource {
  @override
  String? get combatNotice => '봉마참';
  @override
  double get combatNoticeSecondsRemaining => 1.2;
  @override
  int get killStreak => 7;
}
