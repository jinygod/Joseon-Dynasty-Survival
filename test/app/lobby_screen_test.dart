import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/game_screen.dart';
import 'package:pixel_survivor/app/lobby_controller.dart';
import 'package:pixel_survivor/app/lobby_screen.dart';
import 'package:pixel_survivor/game/audio/audio_settings.dart';
import 'package:pixel_survivor/game/audio/audio_settings_controller.dart';
import 'package:pixel_survivor/game/audio/audio_settings_repository.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/models/meta_progress.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';

void main() {
  testWidgets('lobby shows saved state and working destinations', (
    tester,
  ) async {
    final lobby = LobbyController(
      store: _MemorySaveStore(
        SaveState.defaults().copyWith(
          wallet: const Wallet(coin: 120, spiritJade: 2),
        ),
      ),
    );
    await lobby.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: LobbyScreen(
          controller: lobby,
          audioSettingsController: _audioController(),
        ),
      ),
    );

    expect(find.text('엽전 120'), findsOneWidget);
    expect(find.text('혼옥 2'), findsOneWidget);
    expect(find.text('신참 포졸'), findsOneWidget);
    expect(find.byKey(const Key('lobby-character')), findsOneWidget);
    expect(find.byKey(const Key('lobby-stage')), findsOneWidget);
    expect(find.byKey(const Key('lobby-settings')), findsOneWidget);
    expect(find.byKey(const Key('lobby-records')), findsOneWidget);
    expect(find.byKey(const Key('lobby-deploy')), findsOneWidget);
  });

  testWidgets('deploy uses the persisted character and stage', (tester) async {
    final lobby = LobbyController(
      store: _MemorySaveStore(
        SaveState.defaults().copyWith(selectedCharacterId: exorcistDosa),
      ),
    );
    await lobby.load();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: LobbyScreen(
          controller: lobby,
          audioSettingsController: _audioController(),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('lobby-deploy')));
    await tester.pump();
    final screen = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(screen.playerSlot.characterId, exorcistDosa);
    expect(screen.stageId, lobby.state.selectedStageId);
  });
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

class _MemoryAudioStore implements AudioSettingsStore {
  AudioSettings value = AudioSettings.defaults;

  @override
  Future<AudioSettings> load() async => value;

  @override
  Future<void> save(AudioSettings settings) async => value = settings;
}
