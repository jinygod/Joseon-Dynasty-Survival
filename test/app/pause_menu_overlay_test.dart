import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/pause_menu_overlay.dart';
import 'package:pixel_survivor/game/audio/audio_settings_controller.dart';
import 'package:pixel_survivor/game/audio/audio_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('pause menu exposes every run action', (tester) async {
    var resumes = 0;
    var restarts = 0;
    var exits = 0;
    final controller = await _controller();
    await tester.pumpWidget(
      MaterialApp(
        home: PauseMenuOverlay(
          settingsController: controller,
          onResume: () => resumes += 1,
          onRestart: () => restarts += 1,
          onExitToMenu: () => exits += 1,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('pause-resume')));
    await tester.tap(find.byKey(const Key('pause-restart')));
    await tester.tap(find.byKey(const Key('pause-menu')));

    expect((resumes, restarts, exits), (1, 1, 1));
  });

  testWidgets('settings show defaults and can return to pause menu', (
    tester,
  ) async {
    final controller = await _controller();
    await _pumpOverlay(tester, controller);

    await tester.tap(find.byKey(const Key('pause-settings')));
    await tester.pump();

    expect(find.text('설정'), findsOneWidget);
    expect(find.text('음악 70%'), findsOneWidget);
    expect(find.text('효과음 80%'), findsOneWidget);
    final vibration = tester.widget<SwitchListTile>(
      find.byKey(const Key('audio-vibration')),
    );
    expect(vibration.value, isTrue);

    await tester.tap(find.byKey(const Key('pause-settings-back')));
    await tester.pump();
    expect(find.byKey(const Key('pause-resume')), findsOneWidget);
  });

  testWidgets('sliders and vibration update and persist', (tester) async {
    final controller = await _controller();
    await _pumpOverlay(tester, controller);
    await tester.tap(find.byKey(const Key('pause-settings')));
    await tester.pump();

    final music = tester.widget<Slider>(
      find.byKey(const Key('audio-music-volume')),
    );
    final effects = tester.widget<Slider>(
      find.byKey(const Key('audio-sfx-volume')),
    );
    music.onChanged!(0.3);
    effects.onChanged!(0.5);
    await tester.tap(find.byKey(const Key('audio-vibration')));
    await tester.pump();
    await tester.pump();

    expect(find.text('음악 30%'), findsOneWidget);
    expect(find.text('효과음 50%'), findsOneWidget);
    expect(controller.settings.vibrationEnabled, isFalse);
    final persisted = await AudioSettingsRepository(
      preferences: await SharedPreferences.getInstance(),
    ).load();
    expect(persisted.musicVolume, 0.3);
    expect(persisted.sfxVolume, 0.5);
    expect(persisted.vibrationEnabled, isFalse);
  });
}

Future<AudioSettingsController> _controller() async {
  final controller = AudioSettingsController(
    store: AudioSettingsRepository(
      preferences: await SharedPreferences.getInstance(),
    ),
  );
  await controller.load();
  return controller;
}

Future<void> _pumpOverlay(
  WidgetTester tester,
  AudioSettingsController controller,
) => tester.pumpWidget(
  MaterialApp(
    home: PauseMenuOverlay(
      settingsController: controller,
      onResume: () {},
      onRestart: () {},
      onExitToMenu: () {},
    ),
  ),
);
