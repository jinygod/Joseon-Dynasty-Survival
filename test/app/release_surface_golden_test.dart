import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/character_select_screen.dart';
import 'package:pixel_survivor/app/game_hud.dart';
import 'package:pixel_survivor/app/game_hud_source.dart';
import 'package:pixel_survivor/app/game_settings_repository.dart';
import 'package:pixel_survivor/app/lobby_controller.dart';
import 'package:pixel_survivor/app/lobby_screen.dart';
import 'package:pixel_survivor/app/pause_menu_overlay.dart';
import 'package:pixel_survivor/app/run_summary_screen.dart';
import 'package:pixel_survivor/app/stage_select_screen.dart';
import 'package:pixel_survivor/game/audio/audio_settings.dart';
import 'package:pixel_survivor/game/audio/audio_settings_controller.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
import 'package:pixel_survivor/game/models/run_outcome.dart';
import 'package:pixel_survivor/game/models/run_result.dart';
import 'package:pixel_survivor/game/models/vector_input.dart';
import 'package:pixel_survivor/game/systems/progression_system.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';

void main() {
  testWidgets('lobby 16:9 golden', (tester) async {
    final controller = LobbyController(
      store: _MemorySaveStore(SaveState.defaults()),
    );
    await controller.load();
    await _expectGolden(
      tester,
      LobbyScreen(
        controller: controller,
        audioSettingsController: _audioController(),
      ),
      'lobby_16_9.png',
    );
  });

  testWidgets('character selection 16:9 golden', (tester) async {
    await _expectGolden(
      tester,
      CharacterSelectScreen(
        initialCharacterId: rookieConstable,
        unlockedCharacterIds: characterDefinitions
            .map((definition) => definition.id)
            .toSet(),
        onSelected: (_) {},
      ),
      'character_select_16_9.png',
    );
  });

  testWidgets('stage selection 16:9 golden', (tester) async {
    await _expectGolden(
      tester,
      StageSelectScreen(
        initialStageId: moonlitAbandonedOffice,
        unlockedStageIds: stageDefinitions
            .map((definition) => definition.id)
            .toSet(),
        onSelected: (_) {},
      ),
      'stage_select_16_9.png',
    );
  });

  testWidgets('game HUD 16:9 golden', (tester) async {
    await _expectGolden(
      tester,
      GameHud(source: _GoldenHudSource(), onPause: () {}),
      'game_hud_16_9.png',
    );
  });

  testWidgets('pause menu 16:9 golden', (tester) async {
    await _expectGolden(
      tester,
      PauseMenuOverlay(
        settingsController: _audioController(),
        onResume: () {},
        onRestart: () {},
        onExitToMenu: () {},
      ),
      'pause_menu_16_9.png',
    );
  });

  testWidgets('run summary 16:9 golden', (tester) async {
    await _expectGolden(
      tester,
      RunSummaryScreen(
        result: _result,
        unlocks: const ProgressionUnlocks(),
        onStart: () {},
        onMenu: () {},
      ),
      'run_summary_16_9.png',
    );
  });
}

Future<void> _expectGolden(
  WidgetTester tester,
  Widget surface,
  String fileName,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 720);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff3fbf7f)),
        splashFactory: NoSplash.splashFactory,
        useMaterial3: false,
      ),
      home: RepaintBoundary(key: const Key('golden-root'), child: surface),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  expect(tester.takeException(), isNull);
  await expectLater(
    find.byKey(const Key('golden-root')),
    matchesGoldenFile('goldens/$fileName'),
  );
  await tester.pumpWidget(const SizedBox.shrink());
}

const _result = RunResult(
  outcome: RunOutcome.defeat,
  survivalSeconds: 247,
  kills: 184,
  level: 11,
  bossDefeated: false,
  wonWithLowHealth: false,
  weaponKillCounts: {},
  weaponLevels: {},
);

class _GoldenHudSource implements GameHudSource {
  @override
  String? get bossName => '타락한 장군';
  @override
  double? get bossHealthFraction => 0.64;
  @override
  int get currentExperience => 42;
  @override
  double get elapsedSeconds => 274;
  @override
  int get enemyCount => 72;
  @override
  int get experienceToNextLevel => 100;
  @override
  int get kills => 184;
  @override
  int get playerLevel => 11;
  @override
  String get playerHealthLabel => '78/120';
  @override
  List<String> get weaponLevelLabels => const ['환도 베기 5', '각궁 사격 4'];
  @override
  void updateMovementInput(VectorInput input) {}
}

AudioSettingsController _audioController() =>
    AudioSettingsController(store: _MemoryAudioStore());

class _MemorySaveStore implements SaveStore {
  _MemorySaveStore(this.value);
  SaveState value;
  @override
  Future<SaveState> load() async => value;
  @override
  Future<void> save(SaveState state) async => value = state;
}

class _MemoryAudioStore implements GameSettingsStore {
  AudioSettings value = AudioSettings.defaults;
  @override
  Future<AudioSettings> load() async => value;
  @override
  Future<void> save(AudioSettings settings) async => value = settings;
}
