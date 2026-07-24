import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/compendium_screen.dart';
import 'package:pixel_survivor/app/game_screen.dart';
import 'package:pixel_survivor/app/lobby_controller.dart';
import 'package:pixel_survivor/app/lobby_navigation_dock.dart';
import 'package:pixel_survivor/app/lobby_screen.dart';
import 'package:pixel_survivor/app/settings_screen.dart';
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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('navigation dock preserves lobby menu targets', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: LobbyNavigationDock(
            onStagePressed: () {},
            onCharacterPressed: () {},
            onCompendiumPressed: () {},
            onRecordsPressed: () {},
            onTrainingPressed: () {},
          ),
        ),
      ),
    );

    for (final key in const [
      'lobby-stage',
      'lobby-character',
      'lobby-compendium',
      'lobby-records',
      'lobby-training-entry',
    ]) {
      final button = find.byKey(Key(key));
      expect(button, findsOneWidget);
      expect(
        find.descendant(of: button, matching: find.byKey(Key('$key-face'))),
        findsOneWidget,
      );
      expect(
        find.descendant(of: button, matching: find.byKey(Key('$key-depth'))),
        findsOneWidget,
      );
      expect(tester.getSize(button).height, greaterThanOrEqualTo(72));
    }
  });

  testWidgets(
    'narrow navigation dock scrolls training entry into view and taps it',
    (tester) async {
      var trainingTaps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: LobbyNavigationDock(
                  onStagePressed: () {},
                  onCharacterPressed: () {},
                  onCompendiumPressed: () {},
                  onRecordsPressed: () {},
                  onTrainingPressed: () => trainingTaps += 1,
                ),
              ),
            ),
          ),
        ),
      );

      for (final key in const [
        'lobby-stage',
        'lobby-character',
        'lobby-compendium',
        'lobby-records',
        'lobby-training-entry',
      ]) {
        expect(
          tester.getSize(find.byKey(Key(key))).width,
          greaterThanOrEqualTo(64),
        );
      }
      final trainingEntry = find.byKey(const Key('lobby-training-entry'));
      await tester.ensureVisible(trainingEntry);
      await tester.tap(trainingEntry);
      expect(trainingTaps, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('navigation dock medals derive from their item colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: LobbyNavigationDock(
            onStagePressed: () {},
            onCharacterPressed: () {},
            onCompendiumPressed: () {},
            onRecordsPressed: () {},
            onTrainingPressed: () {},
          ),
        ),
      ),
    );

    const baseColors = {
      'lobby-stage': Color(0xff216b5a),
      'lobby-character': Color(0xff9e2f2f),
      'lobby-compendium': Color(0xff536fa8),
      'lobby-records': Color(0xff9b6a34),
    };
    for (final entry in baseColors.entries) {
      final medal = tester.widget<Container>(
        find.byKey(Key('${entry.key}-medal')),
      );
      final decoration = medal.decoration! as BoxDecoration;
      expect(
        decoration.color,
        Color.alphaBlend(const Color(0x44ffffff), entry.value),
      );
    }
  });

  testWidgets('navigation dock exposes labels and forwards callbacks', (
    tester,
  ) async {
    var stageTaps = 0;
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: LobbyNavigationDock(
            onStagePressed: () => stageTaps += 1,
            onCharacterPressed: () {},
            onCompendiumPressed: () {},
            onRecordsPressed: () {},
            onTrainingPressed: () {},
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('지도'), findsOneWidget);
    await tester.tap(find.byKey(const Key('lobby-stage')));
    expect(stageTaps, 1);
    semantics.dispose();
  });

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
    expect(find.byKey(const Key('lobby-compendium')), findsOneWidget);
    expect(find.byKey(const Key('lobby-deploy')), findsOneWidget);
  });

  testWidgets(
    'lobby keeps deploy and training entry above the safe bottom area',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 667);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final lobby = LobbyController(
        store: _MemorySaveStore(SaveState.defaults()),
      );
      await lobby.load();

      await tester.pumpWidget(
        MaterialApp(
          home: LobbyScreen(
            controller: lobby,
            audioSettingsController: _audioController(),
          ),
        ),
      );

      expect(find.byKey(const Key('lobby-deploy')), findsOneWidget);
      expect(find.byKey(const Key('lobby-training-entry')), findsOneWidget);
      expect(
        find.byKey(const Key('lobby-character-landing-plate')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('lobby-character-contact-shadow')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('lobby opens training with saved progress', (tester) async {
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
    await tester.pumpWidget(
      MaterialApp(
        home: LobbyScreen(
          controller: lobby,
          audioSettingsController: _audioController(),
        ),
      ),
    );

    final trainingEntry = find.byKey(const Key('lobby-training-entry'));
    await tester.ensureVisible(trainingEntry);
    await tester.tap(trainingEntry);
    await tester.pumpAndSettle();

    expect(find.byType(TrainingScreen), findsOneWidget);
    expect(find.byKey(const Key('training-screen')), findsOneWidget);
    expect(find.text('common.max_health'), findsOneWidget);
    expect(find.text('Rank 2'), findsOneWidget);
  });

  testWidgets('390x844 lobby presents the command hierarchy without overflow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final lobby = LobbyController(
      store: _MemorySaveStore(SaveState.defaults()),
    );
    await lobby.load();

    await tester.pumpWidget(
      MaterialApp(
        home: LobbyScreen(
          controller: lobby,
          audioSettingsController: _audioController(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('lobby-title-plaque')), findsOneWidget);
    expect(find.byKey(const Key('lobby-resource-ribbon')), findsOneWidget);
    expect(find.byKey(const Key('lobby-resource-bar')), findsOneWidget);
    expect(find.byKey(const Key('lobby-stage-hero')), findsOneWidget);
    expect(find.byKey(const Key('lobby-character-art')), findsOneWidget);
    expect(find.byKey(const Key('lobby-deploy-face')), findsOneWidget);
    expect(find.byKey(const Key('lobby-navigation-dock')), findsOneWidget);
    expect(find.byKey(const Key('lobby-bottom-menu')), findsOneWidget);
    expect(find.byKey(const Key('lobby-deploy')), findsOneWidget);
    expect(find.byKey(const Key('lobby-character')), findsOneWidget);
    expect(find.byKey(const Key('lobby-stage')), findsOneWidget);
    expect(find.byKey(const Key('lobby-compendium')), findsOneWidget);
    expect(find.byKey(const Key('lobby-records')), findsOneWidget);
    expect(tester.getCenter(find.byKey(const Key('lobby-deploy'))).dx, 195);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    '390x844 lobby keeps every destination reachable at text scale two',
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
      final navigatorObserver = _RecordingNavigatorObserver();
      await lobby.load();

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [navigatorObserver],
          home: LobbyScreen(
            controller: lobby,
            audioSettingsController: _audioController(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('lobby-title-plaque')), findsOneWidget);
      expect(find.byKey(const Key('lobby-resource-ribbon')), findsOneWidget);
      expect(find.byKey(const Key('lobby-stage-hero')), findsOneWidget);
      expect(find.byKey(const Key('lobby-deploy-face')), findsOneWidget);
      expect(find.byKey(const Key('lobby-navigation-dock')), findsOneWidget);

      final lobbyContext = tester.element(find.byType(LobbyScreen));
      for (final key in const [
        Key('lobby-settings'),
        Key('lobby-stage'),
        Key('lobby-character'),
        Key('lobby-compendium'),
        Key('lobby-records'),
      ]) {
        final finder = find.byKey(key);
        final rect = tester.getRect(finder);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(390));
        expect(rect.bottom, lessThanOrEqualTo(844));

        final pushesBeforeTap = navigatorObserver.pushCount;
        await tester.tap(finder);
        expect(navigatorObserver.pushCount, pushesBeforeTap + 1);
        Navigator.of(lobbyContext).pop();
        await tester.pumpAndSettle();
      }

      await tester.ensureVisible(find.byKey(const Key('lobby-deploy')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('lobby-deploy')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(GameScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('settings round trip preserves an unrelated lobby SnackBar', (
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
          audioSettingsController: _audioController(),
        ),
      ),
    );

    ScaffoldMessenger.of(tester.element(find.byType(LobbyScreen))).showSnackBar(
      const SnackBar(
        key: Key('unrelated-lobby-snack'),
        duration: Duration(minutes: 1),
        content: Text('계정 동기화가 완료되었습니다.'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('unrelated-lobby-snack')), findsOneWidget);

    await tester.tap(find.byKey(const Key('lobby-settings')));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('unrelated-lobby-snack')), findsOneWidget);
  });

  testWidgets('lobby settings command meets the primary target size', (
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
          audioSettingsController: _audioController(),
        ),
      ),
    );

    final size = tester.getSize(find.byKey(const Key('lobby-settings')));
    expect(size.width, greaterThanOrEqualTo(64));
    expect(size.height, greaterThanOrEqualTo(72));
  });

  testWidgets('lobby opens the compendium destination', (tester) async {
    final lobby = LobbyController(
      store: _MemorySaveStore(SaveState.defaults()),
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

    await tester.tap(find.byKey(const Key('lobby-compendium')));
    await tester.pumpAndSettle();

    expect(find.byType(CompendiumScreen), findsOneWidget);
    expect(find.text('도감'), findsOneWidget);
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
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: LobbyScreen(
          controller: lobby,
          audioSettingsController: _audioController(),
        ),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('lobby-deploy')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('lobby-deploy')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final screen = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(screen.playerSlot.characterId, exorcistDosa);
    expect(screen.stageId, plagueMarket);
  });

  testWidgets(
    'lobby reset returns with defaults and later selection preserves them',
    (tester) async {
      final store = _MemorySaveStore(
        SaveState.defaults().copyWith(
          unlockedCharacterIds: {rookieConstable, exorcistDosa},
          wallet: const Wallet(coin: 500, spiritJade: 3),
        ),
      );
      final lobby = LobbyController(store: store);
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

      await tester.tap(find.byKey(const Key('lobby-settings')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('reset-progress')),
        240,
        scrollable: find.byType(Scrollable),
      );
      await tester.tap(find.byKey(const Key('reset-progress')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reset-first-confirm')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reset-final-confirm')));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(lobby.state.wallet, Wallet.empty);
      expect(
        lobby.state.unlockedCharacterIds,
        SaveState.defaults().unlockedCharacterIds,
      );
      await tester.tap(find.byKey(const Key('lobby-stage')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('stage-confirm')));
      await tester.pumpAndSettle();
      expect(store.value.wallet, Wallet.empty);
      expect(
        store.value.unlockedCharacterIds,
        SaveState.defaults().unlockedCharacterIds,
      );
    },
  );
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

class _RecordingNavigatorObserver extends NavigatorObserver {
  int pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount += 1;
    super.didPush(route, previousRoute);
  }
}
