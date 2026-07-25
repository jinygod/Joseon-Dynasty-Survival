import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/character_select_screen.dart';
import 'package:pixel_survivor/app/compendium_screen.dart';
import 'package:pixel_survivor/app/game_screen.dart';
import 'package:pixel_survivor/app/lobby_controller.dart';
import 'package:pixel_survivor/app/lobby_screen.dart';
import 'package:pixel_survivor/app/records_screen.dart';
import 'package:pixel_survivor/app/settings_screen.dart';
import 'package:pixel_survivor/app/stage_select_screen.dart';
import 'package:pixel_survivor/app/training_screen.dart';
import 'package:pixel_survivor/game/audio/audio_settings.dart';
import 'package:pixel_survivor/game/audio/audio_settings_controller.dart';
import 'package:pixel_survivor/game/audio/audio_settings_repository.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
import 'package:pixel_survivor/game/models/meta_progress.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final size in [
    const Size(640, 360),
    const Size(780, 360),
    const Size(800, 360),
  ]) {
    testWidgets(
      'release lobby has no overflow at ${size.width}x${size.height}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final lobby = LobbyController(
          store: _MemorySaveStore(SaveState.defaults()),
        );
        await lobby.load();

        await tester.pumpWidget(_lobbyApp(lobby));
        await tester.pump();

        expect(find.byKey(const Key('lobby-deploy')), findsOneWidget);
        expect(find.byKey(const Key('lobby-character-art')), findsOneWidget);
        expect(find.byKey(const Key('lobby-status-bar')), findsOneWidget);
        expect(
          find.byKey(const Key('lobby-primary-navigation')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('release lobby avoids stock Material surfaces', (tester) async {
    final lobby = LobbyController(
      store: _MemorySaveStore(SaveState.defaults()),
    );
    await lobby.load();

    await tester.pumpWidget(_lobbyApp(lobby));

    final screen = find.byType(LobbyScreen);
    for (final type in [Card, ListTile, AppBar, ActionChip]) {
      expect(
        find.descendant(of: screen, matching: find.byType(type)),
        findsNothing,
      );
    }
  });

  testWidgets('640 landscape uses reachable compact horizontal command rails', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(640, 360);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final lobby = LobbyController(
      store: _MemorySaveStore(SaveState.defaults()),
    );
    await lobby.load();
    await tester.pumpWidget(_lobbyApp(lobby));
    await tester.pump();

    expect(
      find.byKey(const Key('lobby-side-menu-horizontal')),
      findsNWidgets(2),
    );
    expect(find.byKey(const Key('lobby-side-menu-vertical')), findsNothing);
    for (final key in const [
      'lobby-side-mail',
      'lobby-side-mission',
      'lobby-side-pass',
      'lobby-side-package',
      'lobby-side-compendium',
      'lobby-side-records',
    ]) {
      final rect = tester.getRect(find.byKey(Key(key)));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(640));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('lobby routes every implemented destination', (tester) async {
    final lobby = LobbyController(
      store: _MemorySaveStore(SaveState.defaults()),
    );
    await lobby.load();
    await tester.pumpWidget(_lobbyApp(lobby));

    final destinations = [
      (const Key('lobby-stage'), find.byType(StageSelectScreen)),
      (
        const Key('lobby-primary-character'),
        find.byType(CharacterSelectScreen),
      ),
      (const Key('lobby-side-compendium'), find.byType(CompendiumScreen)),
      (const Key('lobby-side-records'), find.byType(RecordsScreen)),
      (const Key('lobby-quick-growth'), find.byType(TrainingScreen)),
      (const Key('lobby-settings'), find.byType(SettingsScreen)),
    ];

    for (final destination in destinations) {
      await tester.tap(find.byKey(destination.$1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(destination.$2, findsOneWidget);
      Navigator.of(tester.element(destination.$2)).pop();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }
  });

  testWidgets('unavailable lobby action opens its approved notice', (
    tester,
  ) async {
    final lobby = LobbyController(
      store: _MemorySaveStore(SaveState.defaults()),
    );
    await lobby.load();
    await tester.pumpWidget(_lobbyApp(lobby));

    await tester.tap(find.byKey(const Key('lobby-quick-crafting')));
    await tester.pumpAndSettle();

    expect(find.text('대장간'), findsOneWidget);
    expect(find.byKey(const Key('lobby-feature-notice')), findsOneWidget);
  });

  testWidgets('deploy uses the persisted character and stage', (tester) async {
    final lobby = LobbyController(
      store: _MemorySaveStore(
        SaveState.defaults().copyWith(
          unlockedCharacterIds: {rookieConstable, exorcistDosa},
          unlockedStageIds: {moonlitAbandonedOffice, plagueMarket},
          selectedCharacterId: exorcistDosa,
          selectedStageId: plagueMarket,
        ),
      ),
    );
    await lobby.load();
    await tester.pumpWidget(_lobbyApp(lobby));

    await tester.tap(find.byKey(const Key('lobby-deploy')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final screen = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(screen.playerSlot.characterId, exorcistDosa);
    expect(screen.stageId, plagueMarket);
  });
}

Widget _lobbyApp(LobbyController lobby) => MaterialApp(
  theme: ThemeData(splashFactory: NoSplash.splashFactory),
  home: LobbyScreen(
    controller: lobby,
    audioSettingsController: _audioController(),
  ),
);

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
