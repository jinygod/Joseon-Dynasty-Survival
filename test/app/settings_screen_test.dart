import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/credits_ledger.dart';
import 'package:pixel_survivor/app/game_settings.dart';
import 'package:pixel_survivor/app/game_settings_controller.dart';
import 'package:pixel_survivor/app/game_settings_repository.dart';
import 'package:pixel_survivor/app/settings_screen.dart';
import 'package:pixel_survivor/game/models/meta_progress.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';

void main() {
  testWidgets('sliders toggles and UI size update the unified settings', (
    tester,
  ) async {
    final store = _MemorySettingsStore();
    final controller = GameSettingsController(store: store);
    await tester.pumpWidget(
      _testApp(
        SettingsScreen(
          controller: controller,
          progressStore: _MemorySaveStore(),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('screen-shake-enabled')));
    await tester.tap(find.byKey(const Key('damage-numbers-enabled')));
    await tester.tap(find.byKey(const Key('vibration-enabled')));
    await tester.tap(find.byKey(const Key('ui-scale-large')));
    await tester.drag(
      find.byKey(const Key('music-volume')),
      const Offset(-120, 0),
    );
    await tester.drag(
      find.byKey(const Key('sfx-volume')),
      const Offset(-120, 0),
    );
    await tester.pump();

    expect(controller.settings.screenShakeEnabled, isFalse);
    expect(controller.settings.damageNumbersEnabled, isFalse);
    expect(controller.settings.vibrationEnabled, isFalse);
    expect(controller.settings.uiScale, UiScale.large);
    expect(controller.settings.musicVolume, lessThan(0.7));
    expect(controller.settings.sfxVolume, lessThan(0.8));
  });

  testWidgets('first reset confirmation can be cancelled', (tester) async {
    final saveStore = _MemorySaveStore();
    await tester.pumpWidget(
      _testApp(
        SettingsScreen(
          controller: GameSettingsController(store: _MemorySettingsStore()),
          progressStore: saveStore,
        ),
      ),
    );

    await _revealResetButton(tester);
    await tester.tap(find.byKey(const Key('reset-progress')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reset-first-cancel')));
    await tester.pumpAndSettle();

    expect(saveStore.saveCount, 0);
  });

  testWidgets('credits button opens the asynchronously loaded bundled route', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        SettingsScreen(
          controller: GameSettingsController(store: _MemorySettingsStore()),
          creditsLedgerLoader: () async => const CreditsLedger(
            assets: [
              CreditEntry(
                runtimePath: 'assets/images/path-from-settings.png',
                creator: 'Reviewer',
                sourceUrl: 'https://example.test/source',
                license: 'Test License',
                status: 'approved',
              ),
            ],
            audio: [],
          ),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('credits-licenses')),
      240,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.byKey(const Key('credits-licenses')));
    await tester.pumpAndSettle();

    expect(find.text('assets/images/path-from-settings.png'), findsOneWidget);
    expect(find.text('https://example.test/source'), findsOneWidget);
  });

  testWidgets('second reset confirmation can be cancelled', (tester) async {
    final saveStore = _MemorySaveStore();
    await tester.pumpWidget(
      _testApp(
        SettingsScreen(
          controller: GameSettingsController(store: _MemorySettingsStore()),
          progressStore: saveStore,
        ),
      ),
    );

    await _revealResetButton(tester);
    await tester.tap(find.byKey(const Key('reset-progress')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reset-first-confirm')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reset-final-cancel')));
    await tester.pumpAndSettle();

    expect(saveStore.saveCount, 0);
  });

  testWidgets(
    'final confirmation resets meta progress and preserves settings',
    (tester) async {
      final settingsStore = _MemorySettingsStore();
      final controller = GameSettingsController(store: settingsStore);
      await controller.setScreenShakeEnabled(false);
      final saveStore = _MemorySaveStore();
      await tester.pumpWidget(
        _testApp(
          SettingsScreen(controller: controller, progressStore: saveStore),
        ),
      );

      await _revealResetButton(tester);
      await tester.tap(find.byKey(const Key('reset-progress')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reset-first-confirm')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reset-final-confirm')));
      await tester.pumpAndSettle();

      expect(saveStore.saveCount, 1);
      expect(saveStore.value.totalKills, 0);
      expect(saveStore.value.wallet.coin, 0);
      expect(controller.settings.screenShakeEnabled, isFalse);
      expect(settingsStore.value.screenShakeEnabled, isFalse);
      expect(find.text('진행 데이터가 초기화되었습니다.'), findsOneWidget);
    },
  );
}

Widget _testApp(Widget home) => MaterialApp(
  theme: ThemeData(splashFactory: NoSplash.splashFactory),
  home: home,
);

Future<void> _revealResetButton(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('reset-progress')),
    240,
    scrollable: find.byType(Scrollable),
  );
}

class _MemorySettingsStore implements GameSettingsStore {
  GameSettings value = GameSettings.defaults;

  @override
  Future<GameSettings> load() async => value;

  @override
  Future<void> save(GameSettings settings) async => value = settings;
}

class _MemorySaveStore implements SaveStore {
  SaveState value = SaveState.defaults().copyWith(
    totalKills: 99,
    wallet: const Wallet(coin: 500, spiritJade: 3),
  );
  int saveCount = 0;

  @override
  Future<SaveState> load() async => value;

  @override
  Future<void> save(SaveState state) async {
    saveCount += 1;
    value = state;
  }
}
