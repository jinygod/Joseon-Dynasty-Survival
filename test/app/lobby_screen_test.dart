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

  testWidgets('growth route receives saved training progress', (tester) async {
    final lobby = LobbyController(
      store: _MemorySaveStore(
        SaveState.defaults().copyWith(
          trainingProgress: const TrainingProgress(
            commonRanks: {'common.max_health': 2},
            characterRanks: {},
            activeCoreTraitIds: {},
          ),
        ),
      ),
    );
    await lobby.load();
    await tester.pumpWidget(_lobbyApp(lobby));

    await tester.tap(find.byKey(const Key('lobby-quick-growth')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TrainingScreen), findsOneWidget);
    expect(find.text('common.max_health'), findsOneWidget);
    expect(find.text('Rank 2'), findsOneWidget);
  });

  testWidgets('settings reset survives a stage selection round trip', (
    tester,
  ) async {
    final store = _MemorySaveStore(
      SaveState.defaults().copyWith(
        unlockedCharacterIds: {rookieConstable, exorcistDosa},
        wallet: const Wallet(coin: 500, spiritJade: 3),
      ),
    );
    final lobby = LobbyController(store: store);
    await lobby.load();
    await tester.pumpWidget(_lobbyApp(lobby));

    ScaffoldMessenger.of(tester.element(find.byType(LobbyScreen))).showSnackBar(
      const SnackBar(
        key: Key('unrelated-lobby-snack'),
        duration: Duration(minutes: 1),
        content: Text('동기화 상태 유지'),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('lobby-settings')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.scrollUntilVisible(
      find.byKey(const Key('reset-progress')),
      240,
      scrollable: find
          .descendant(
            of: find.byType(SettingsScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const Key('reset-progress')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reset-first-confirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reset-final-confirm')));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(SettingsScreen))).pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const Key('unrelated-lobby-snack')), findsOneWidget);
    expect(lobby.state.wallet, Wallet.empty);
    await tester.tap(find.byKey(const Key('lobby-stage')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('stage-confirm')));
    await tester.pumpAndSettle();
    expect(store.value.wallet, Wallet.empty);
    expect(
      store.value.unlockedCharacterIds,
      SaveState.defaults().unlockedCharacterIds,
    );
  });

  testWidgets(
    'scaled narrow lobby keeps core actions reachable without overflow',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final lobby = LobbyController(
        store: _MemorySaveStore(SaveState.defaults()),
      );
      await lobby.load();
      await tester.pumpWidget(_lobbyApp(lobby));
      await tester.pump();

      for (final key in const [
        'lobby-settings',
        'lobby-stage',
        'lobby-deploy',
        'lobby-primary-combat',
        'lobby-primary-shop',
      ]) {
        final rect = tester.getRect(find.byKey(Key(key)));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(390));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(844));
      }
      // The no-scaling raster composition keeps every primary action in bounds
      // at the platform's 2x text preference.
    },
  );

  testWidgets('primary combat uses the guarded deploy callback', (
    tester,
  ) async {
    final lobby = LobbyController(
      store: _MemorySaveStore(SaveState.defaults()),
    );
    await lobby.load();
    await tester.pumpWidget(_lobbyApp(lobby));

    await tester.tap(find.byKey(const Key('lobby-primary-combat')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('unavailable primary and side actions open their notices', (
    tester,
  ) async {
    final lobby = LobbyController(
      store: _MemorySaveStore(SaveState.defaults()),
    );
    await lobby.load();
    await tester.pumpWidget(_lobbyApp(lobby));
    const entries = [
      ('lobby-side-mail', '전령의 소식'),
      ('lobby-side-mission', '임무서'),
      ('lobby-side-pass', '승급 준비'),
      ('lobby-side-package', '보급품'),
      ('lobby-quick-relic', '봉인된 유물'),
      ('lobby-quick-companion', '인연'),
      ('lobby-quick-crafting', '대장간'),
      ('lobby-primary-challenge', '봉인된 시련'),
    ];
    for (final entry in entries) {
      await tester.tap(find.byKey(Key(entry.$1)));
      await tester.pumpAndSettle();
      expect(find.text(entry.$2), findsOneWidget);
      await tester.tap(find.byKey(const Key('lobby-feature-notice-confirm')));
      await tester.pumpAndSettle();
    }
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
