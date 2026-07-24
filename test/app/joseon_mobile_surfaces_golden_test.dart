import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/character_select_screen.dart';
import 'package:pixel_survivor/app/compendium_screen.dart';
import 'package:pixel_survivor/app/game_settings_repository.dart';
import 'package:pixel_survivor/app/joseon_ui_theme.dart';
import 'package:pixel_survivor/app/pause_menu_overlay.dart';
import 'package:pixel_survivor/app/records_screen.dart';
import 'package:pixel_survivor/app/run_summary_screen.dart';
import 'package:pixel_survivor/app/stage_select_screen.dart';
import 'package:pixel_survivor/game/audio/audio_settings.dart';
import 'package:pixel_survivor/game/audio/audio_settings_controller.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/ids.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/models/run_outcome.dart';
import 'package:pixel_survivor/game/models/run_result.dart';
import 'package:pixel_survivor/game/models/run_telemetry.dart';
import 'package:pixel_survivor/game/systems/meta_history_service.dart';
import 'package:pixel_survivor/game/systems/progression_system.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';

void main() {
  setUpAll(() async {
    await _loadBundledJoseonFonts();
    await _loadMaterialIconsFont();
  });

  for (final size in const [
    Size(390, 844),
    Size(375, 667),
    Size(430, 932),
  ]) {
    final suffix = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('character select $suffix', (tester) async {
      await _expectSurfaceGolden(
        tester,
        size: size,
        surface: CharacterSelectScreen(
          initialCharacterId: rookieConstable,
          unlockedCharacterIds: characterDefinitions
              .map((definition) => definition.id)
              .toSet(),
          onSelected: (_) {},
        ),
        fileName: 'character_select_$suffix.png',
      );
    });

    testWidgets('stage select $suffix', (tester) async {
      await _expectSurfaceGolden(
        tester,
        size: size,
        surface: StageSelectScreen(
          initialStageId: moonlitAbandonedOffice,
          unlockedStageIds: stageDefinitions.map((stage) => stage.id).toSet(),
          onSelected: (_) {},
        ),
        fileName: 'stage_select_$suffix.png',
        verify: (tester) {
          expect(find.textContaining('ASSET MISSING'), findsWidgets);
        },
      );
    });

    testWidgets('locked compendium $suffix', (tester) async {
      await _expectSurfaceGolden(
        tester,
        size: size,
        surface: CompendiumScreen(
          state: SaveState.defaults().copyWith(unlockedAugmentIds: const {}),
        ),
        fileName: 'compendium_locked_$suffix.png',
        prepare: (tester) async {
          await tester.tap(find.byType(TextButton).last);
          await tester.pumpAndSettle();
        },
        verify: (tester) {
          expect(find.byKey(const Key('locked-silhouette')), findsWidgets);
          expect(find.byKey(const Key('locked-original-image')), findsNothing);
        },
      );
    });

    testWidgets('records $suffix', (tester) async {
      await _expectSurfaceGolden(
        tester,
        size: size,
        surface: RecordsScreen(
          state: SaveState.defaults().copyWith(
            totalKills: 1234,
            bestSurvivalSeconds: 754,
            bossDefeats: 12,
            completedGoalIds: const {'first'},
            characterVictoryCounts: const {rookieConstable: 3},
          ),
          historyService: MetaHistoryService(
            loadHistory: () async => [_telemetry()],
          ),
        ),
        fileName: 'records_$suffix.png',
      );
    });

    testWidgets('pause $suffix', (tester) async {
      await _expectSurfaceGolden(
        tester,
        size: size,
        surface: PauseMenuOverlay(
          settingsController: _audioController(),
          onResume: () {},
          onRestart: () {},
          onExitToMenu: () {},
        ),
        fileName: 'pause_$suffix.png',
      );
    });

    testWidgets('run summary $suffix', (tester) async {
      await _expectSurfaceGolden(
        tester,
        size: size,
        surface: RunSummaryScreen(
          result: _result,
          unlocks: const ProgressionUnlocks(),
          onStart: () {},
          onMenu: () {},
        ),
        fileName: 'run_summary_$suffix.png',
        prepare: (tester) async {
          await tester.ensureVisible(find.byKey(const Key('result-retry')));
          await tester.pump();
        },
        verify: (tester) {
          expect(find.byKey(const Key('result-retry')), findsOneWidget);
          expect(find.byKey(const Key('result-menu')), findsOneWidget);
        },
      );
    });
  }
}

Future<void> _expectSurfaceGolden(
  WidgetTester tester, {
  required Size size,
  required Widget surface,
  required String fileName,
  Future<void> Function(WidgetTester tester)? prepare,
  void Function(WidgetTester tester)? verify,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: JoseonUiTheme.create(),
      home: RepaintBoundary(key: const Key('golden-root'), child: surface),
    ),
  );
  for (var attempt = 0; attempt < 3; attempt += 1) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
  await prepare?.call(tester);
  expect(tester.takeException(), isNull);
  verify?.call(tester);
  await expectLater(
    find.byKey(const Key('golden-root')),
    matchesGoldenFile('goldens/$fileName'),
  );
  await tester.pumpWidget(const SizedBox.shrink());
}

Future<void> _loadBundledJoseonFonts() async {
  final displayBytes = await File(
    'assets/fonts/SongMyung-Regular.ttf',
  ).readAsBytes();
  await (FontLoader(
    JoseonUiTheme.displayFontFamily,
  )..addFont(Future.value(ByteData.sublistView(displayBytes)))).load();
  final bodyBytes = await File(
    'assets/fonts/GowunBatang-Regular.ttf',
  ).readAsBytes();
  final boldBodyBytes = await File(
    'assets/fonts/GowunBatang-Bold.ttf',
  ).readAsBytes();
  await (FontLoader(JoseonUiTheme.bodyFontFamily)
        ..addFont(Future.value(ByteData.sublistView(bodyBytes)))
        ..addFont(Future.value(ByteData.sublistView(boldBodyBytes))))
      .load();
}

Future<void> _loadMaterialIconsFont() async {
  var directory = File(Platform.resolvedExecutable).parent;
  File? font;
  while (directory.parent.path != directory.path) {
    final candidate = File(
      '${directory.path}${Platform.pathSeparator}cache'
      '${Platform.pathSeparator}artifacts${Platform.pathSeparator}'
      'material_fonts${Platform.pathSeparator}MaterialIcons-Regular.otf',
    );
    if (candidate.existsSync()) {
      font = candidate;
      break;
    }
    directory = directory.parent;
  }
  if (font == null) {
    throw StateError('Flutter SDK Material Icons font is missing.');
  }
  final bytes = await font.readAsBytes();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
}

AudioSettingsController _audioController() =>
    AudioSettingsController(store: _MemoryAudioStore());

const _result = RunResult(
  outcome: RunOutcome.defeat,
  survivalSeconds: 754,
  kills: 1234,
  level: 18,
  bossDefeated: false,
  wonWithLowHealth: false,
  weaponKillCounts: {hwandoSlash: 87},
  weaponLevels: {hwandoSlash: 6},
  weaponDamageTotals: {hwandoSlash: 4200},
);

RunTelemetry _telemetry() => RunTelemetry(
  runId: 'mobile-golden',
  appVersion: 'test',
  startedAtUtc: DateTime.utc(2026),
  endedAtUtc: DateTime.utc(2026, 1, 1, 0, 12, 34),
  outcome: RunOutcome.defeat,
  survivalSeconds: 754,
  level: 18,
  kills: 1234,
  bossDefeated: false,
  weaponKillCounts: const {hwandoSlash: 87},
  weaponDamageTotals: const {hwandoSlash: 4200},
);

class _MemoryAudioStore implements GameSettingsStore {
  AudioSettings value = AudioSettings.defaults;

  @override
  Future<AudioSettings> load() async => value;

  @override
  Future<void> save(AudioSettings settings) async => value = settings;
}
