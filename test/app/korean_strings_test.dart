import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/game_hud.dart';
import 'package:pixel_survivor/app/game_hud_source.dart';
import 'package:pixel_survivor/app/lobby_controller.dart';
import 'package:pixel_survivor/app/lobby_screen.dart';
import 'package:pixel_survivor/app/run_summary_screen.dart';
import 'package:pixel_survivor/game/content/augment_definitions.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/audio/audio_settings.dart';
import 'package:pixel_survivor/game/audio/audio_settings_controller.dart';
import 'package:pixel_survivor/game/audio/audio_settings_repository.dart';
import 'package:pixel_survivor/game/models/run_outcome.dart';
import 'package:pixel_survivor/game/models/run_result.dart';
import 'package:pixel_survivor/game/models/vector_input.dart';
import 'package:pixel_survivor/game/systems/progression_system.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';

void main() {
  test('every content display name is Korean', () {
    final names = [
      ...characterDefinitions.map((item) => item.name),
      ...enemyDefinitions.map((item) => item.name),
      ...weaponDefinitions.map((item) => item.name),
      ...augmentDefinitions.map((item) => item.name),
    ];

    expect(names.where(_hasLatinLetters), isEmpty);
  });

  testWidgets('main menu and gameplay HUD expose no English copy', (
    tester,
  ) async {
    final lobby = LobbyController(
      store: _MemorySaveStore(SaveState.defaults()),
    );
    await lobby.load();
    await tester.pumpWidget(
      MaterialApp(
        home: LobbyScreen(
          controller: lobby,
          audioSettingsController: AudioSettingsController(
            store: _MemoryAudioStore(),
          ),
        ),
      ),
    );
    _expectRenderedTextIsKorean(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: GameHud(source: _HudSource(), onPause: () {}),
      ),
    );
    _expectRenderedTextIsKorean(tester);
  });

  testWidgets('result screen exposes no English technical labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RunSummaryScreen(
          result: _result,
          unlocks: const ProgressionUnlocks(),
          onStart: () {},
          onMenu: () {},
          onCopyRunJson: () async => true,
          onExportAllJson: () async => true,
        ),
      ),
    );

    _expectRenderedTextIsKorean(tester);
  });
}

bool _hasLatinLetters(String text) => RegExp('[A-Za-z]').hasMatch(text);

void _expectRenderedTextIsKorean(WidgetTester tester) {
  final rendered = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data ?? widget.textSpan?.toPlainText() ?? '')
      .where((text) => text.isNotEmpty)
      .toList();
  expect(
    rendered.where(_hasLatinLetters),
    isEmpty,
    reason: '영문이 남은 화면 문구: $rendered',
  );
}

const _result = RunResult(
  outcome: RunOutcome.victory,
  survivalSeconds: 300,
  kills: 80,
  level: 10,
  bossDefeated: true,
  wonWithLowHealth: false,
  weaponKillCounts: {hwandoSlash: 50},
  weaponLevels: {hwandoSlash: 5},
  weaponDamageTotals: {hwandoSlash: 1200},
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
  String? get combatNotice => null;
  @override
  double get combatNoticeSecondsRemaining => 0;
  @override
  int get killStreak => 0;
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

class _MemoryAudioStore implements AudioSettingsStore {
  AudioSettings value = AudioSettings.defaults;

  @override
  Future<AudioSettings> load() async => value;

  @override
  Future<void> save(AudioSettings settings) async => value = settings;
}
