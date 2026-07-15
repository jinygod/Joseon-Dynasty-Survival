import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/character_select_screen.dart';
import 'package:pixel_survivor/app/first_run_tutorial_overlay.dart';
import 'package:pixel_survivor/app/game_hud.dart';
import 'package:pixel_survivor/app/game_hud_source.dart';
import 'package:pixel_survivor/app/lobby_controller.dart';
import 'package:pixel_survivor/app/lobby_screen.dart';
import 'package:pixel_survivor/app/pause_menu_overlay.dart';
import 'package:pixel_survivor/app/run_summary_screen.dart';
import 'package:pixel_survivor/app/stage_select_screen.dart';
import 'package:pixel_survivor/game/models/run_outcome.dart';
import 'package:pixel_survivor/game/audio/audio_settings_controller.dart';
import 'package:pixel_survivor/game/audio/audio_settings_repository.dart';
import 'package:pixel_survivor/game/models/run_result.dart';
import 'package:pixel_survivor/game/models/vector_input.dart';
import 'package:pixel_survivor/game/systems/progression_system.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const sizes = <String, Size>{
    '16:9': Size(800, 450),
    '18:9': Size(900, 450),
    '19.5:9': Size(975, 450),
    'tablet 4:3': Size(1024, 768),
  };

  for (final entry in sizes.entries) {
    testWidgets('${entry.key} release surfaces stay inside safe area', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = entry.value;
      tester.view.padding = const FakeViewPadding(
        left: 24,
        top: 8,
        right: 24,
        bottom: 8,
      );
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetPadding();
      });
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      final lobbyController = LobbyController(
        store: _MemorySaveStore(SaveState.defaults()),
      );
      await lobbyController.load();
      await _pumpSurface(
        tester,
        LobbyScreen(
          controller: lobbyController,
          audioSettingsController: AudioSettingsController(
            store: AudioSettingsRepository(preferences: preferences),
          ),
        ),
      );
      _expectSafe(tester, find.byKey(const Key('lobby-deploy')), entry.value);

      await _pumpSurface(
        tester,
        CharacterSelectScreen(
          initialCharacterId: rookieConstable,
          unlockedCharacterIds: SaveState.defaults().unlockedCharacterIds,
          onSelected: (_) {},
        ),
        settle: true,
      );
      _expectSafe(
        tester,
        find.byKey(const Key('character-confirm')),
        entry.value,
      );

      await _pumpSurface(
        tester,
        StageSelectScreen(
          initialStageId: moonlitAbandonedOffice,
          onSelected: (_) {},
        ),
      );
      _expectSafe(tester, find.byKey(const Key('stage-confirm')), entry.value);

      await _pumpSurface(tester, FirstRunTutorialOverlay(onCompleted: () {}));
      _expectSafe(tester, find.byKey(const Key('tutorial-next')), entry.value);

      await _pumpSurface(tester, GameHud(source: _HudSource(), onPause: () {}));
      _expectSafe(
        tester,
        find.byKey(const Key('virtual-joystick')),
        entry.value,
      );
      _expectSafe(tester, find.byKey(const Key('hud-pause')), entry.value);

      await _pumpSurface(
        tester,
        PauseMenuOverlay(
          settingsController: AudioSettingsController(
            store: AudioSettingsRepository(preferences: preferences),
          ),
          onResume: () {},
          onRestart: () {},
          onExitToMenu: () {},
        ),
      );
      _expectSafe(tester, find.byKey(const Key('pause-resume')), entry.value);
      await tester.tap(find.byKey(const Key('pause-settings')));
      await tester.pump();
      expect(tester.takeException(), isNull);
      _expectSafe(
        tester,
        find.byKey(const Key('pause-settings-back')),
        entry.value,
      );

      await _pumpSurface(
        tester,
        RunSummaryScreen(
          result: _result,
          unlocks: const ProgressionUnlocks(),
          onStart: () {},
          onMenu: () {},
        ),
      );
      final retry = find.byKey(const Key('result-retry'));
      await tester.ensureVisible(retry);
      await tester.pump();
      expect(tester.takeException(), isNull);
      _expectSafe(tester, retry, entry.value);
    });
  }
}

Future<void> _pumpSurface(
  WidgetTester tester,
  Widget surface, {
  bool settle = false,
}) async {
  await tester.pumpWidget(MaterialApp(home: surface));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  expect(tester.takeException(), isNull);
}

void _expectSafe(WidgetTester tester, Finder finder, Size size) {
  expect(finder, findsOneWidget);
  final rect = tester.getRect(finder);
  expect(rect.left, greaterThanOrEqualTo(24));
  expect(rect.top, greaterThanOrEqualTo(8));
  expect(rect.right, lessThanOrEqualTo(size.width - 24));
  expect(rect.bottom, lessThanOrEqualTo(size.height - 8));
}

const _result = RunResult(
  outcome: RunOutcome.defeat,
  survivalSeconds: 120,
  kills: 20,
  level: 5,
  bossDefeated: false,
  wonWithLowHealth: false,
  weaponKillCounts: {},
  weaponLevels: {},
);

class _HudSource implements GameHudSource {
  @override
  double get elapsedSeconds => 120;
  @override
  String get playerHealthLabel => '80/100';
  @override
  int get playerLevel => 5;
  @override
  int get currentExperience => 4;
  @override
  int get experienceToNextLevel => 10;
  @override
  int get enemyCount => 20;
  @override
  int get kills => 30;
  @override
  String? get bossName => null;
  @override
  double? get bossHealthFraction => null;
  @override
  List<String> get weaponLevelLabels => const ['환도 베기 레벨 3'];
  @override
  void updateMovementInput(VectorInput input) {}
}

class _MemorySaveStore implements SaveStore {
  _MemorySaveStore(this.value);

  SaveState value;

  @override
  Future<SaveState> load() async => value;

  @override
  Future<void> save(SaveState state) async => value = state;
}
