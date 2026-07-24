import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/character_select_screen.dart';
import 'package:pixel_survivor/app/game_hud.dart';
import 'package:pixel_survivor/app/game_hud_source.dart';
import 'package:pixel_survivor/app/game_settings_repository.dart';
import 'package:pixel_survivor/app/joseon_ui_theme.dart';
import 'package:pixel_survivor/app/lobby_controller.dart';
import 'package:pixel_survivor/app/lobby_screen.dart';
import 'package:pixel_survivor/app/pause_menu_overlay.dart';
import 'package:pixel_survivor/app/run_summary_screen.dart';
import 'package:pixel_survivor/app/stage_select_screen.dart';
import 'package:pixel_survivor/app/weapon_star_rating.dart';
import 'package:pixel_survivor/game/audio/audio_settings.dart';
import 'package:pixel_survivor/game/audio/audio_settings_controller.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';
import 'package:pixel_survivor/game/content/ids.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/models/player_slot.dart';
import 'package:pixel_survivor/game/models/run_outcome.dart';
import 'package:pixel_survivor/game/models/run_result.dart';
import 'package:pixel_survivor/game/models/vector_input.dart';
import 'package:pixel_survivor/game/pixel_survivor_game.dart';
import 'package:pixel_survivor/game/systems/progression_system.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';

void main() {
  setUpAll(() async {
    await _loadDeterministicGoldenFont();
    await _loadBundledJoseonFonts();
    await _loadMaterialIconsFont();
  });

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
    final game = PixelSurvivorGame(
      playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
      onRunEnded: null,
      random: Random(41),
      loadVisualAssets: false,
    );
    game
      ..debugSpawnEnemy(plagueRatSwarm, position: Vector2(360, 270))
      ..debugSpawnEnemy(bandit, position: Vector2(760, 360))
      ..debugSpawnEnemy(vengefulSpirit, position: Vector2(920, 230));
    const expectedWeaponLevels = <WeaponId, int>{
      hwandoSlash: 6,
      gakgungShot: 5,
      talismanThrow: 6,
    };
    _equipWeapons(game, expectedWeaponLevels);
    final expectedWeaponLabels = [
      for (final entry in expectedWeaponLevels.entries)
        '${_weaponName(entry.key)} 레벨 ${entry.value}',
    ];
    await _expectGolden(
      tester,
      Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(game: game),
          GameHud(source: game, onPause: () {}),
        ],
      ),
      'game_hud_16_9.png',
      beforeCapture: (tester) async {
        expect(
          game.weaponSystem.levels,
          containsPair(hwandoSlash, expectedWeaponLevels[hwandoSlash]),
        );
        expect(
          game.weaponSystem.levels,
          containsPair(gakgungShot, expectedWeaponLevels[gakgungShot]),
        );
        expect(
          game.weaponSystem.levels,
          containsPair(talismanThrow, expectedWeaponLevels[talismanThrow]),
        );
        expect(game.weaponLevelLabels, expectedWeaponLabels);
        expect(find.byKey(const Key('hud-weapon-slot-0')), findsOneWidget);
        expect(find.byType(WeaponStarRating), findsOneWidget);
        expect(
          tester.widget<WeaponStarRating>(find.byType(WeaponStarRating)).level,
          expectedWeaponLevels.values.first,
        );
        expect(find.byKey(const Key('filled-star-5')), findsNothing);
        expect(find.byKey(const Key('hud-weapon-slot-1')), findsNothing);
        expect(find.byKey(const Key('hud-weapon-slot-2')), findsNothing);
        expect(find.byKey(const Key('hud-weapon-slot-3')), findsNothing);
        await _expectWeaponMarksPainted(tester);
      },
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
  String fileName, {
  Future<void> Function(WidgetTester tester)? beforeCapture,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1280, 720);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  final joseonTheme = JoseonUiTheme.create();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: joseonTheme.copyWith(
        textTheme: joseonTheme.textTheme.apply(
          fontFamilyFallback: const [_goldenFontFamily],
        ),
      ),
      home: RepaintBoundary(key: const Key('golden-root'), child: surface),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  expect(tester.takeException(), isNull);
  _expectVisibleTextAndIconsAreConfigured(tester);
  await beforeCapture?.call(tester);
  await expectLater(
    find.byKey(const Key('golden-root')),
    matchesGoldenFile('goldens/$fileName'),
  );
  await tester.pumpWidget(const SizedBox.shrink());
}

Future<void> _expectWeaponMarksPainted(WidgetTester tester) async {
  const expectedMarks = [
    (index: 0, style: 'hwando', color: (217, 247, 255)),
  ];
  final marks = [
    for (final expected in expectedMarks)
      find.byKey(Key('hud-weapon-mark-${expected.index}-${expected.style}')),
  ];
  for (final mark in marks) {
    expect(mark, findsOneWidget);
  }
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('golden-root')),
  );
  final rects = marks.map(tester.getRect).toList(growable: false);
  final rendered = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return (width: image.width, pixels: bytes?.buffer.asUint8List());
  });
  expect(rendered, isNotNull);
  expect(rendered!.pixels, isNotNull);
  final pixels = rendered.pixels!;
  for (var index = 0; index < rects.length; index++) {
    final rect = rects[index];
    final expected = expectedMarks[index].color;
    var paintedPixels = 0;
    for (var y = rect.top.floor(); y < rect.bottom.ceil(); y++) {
      for (var x = rect.left.floor(); x < rect.right.ceil(); x++) {
        final pixel = (y * rendered.width + x) * 4;
        final red = pixels[pixel];
        final green = pixels[pixel + 1];
        final blue = pixels[pixel + 2];
        final alpha = pixels[pixel + 3];
        if ((red - expected.$1).abs() <= 20 &&
            (green - expected.$2).abs() <= 20 &&
            (blue - expected.$3).abs() <= 20 &&
            alpha > 240) {
          paintedPixels += 1;
        }
      }
    }
    expect(paintedPixels, greaterThan(12), reason: 'weapon mark $index');
  }
}

String _weaponName(WeaponId id) =>
    weaponDefinitions.singleWhere((definition) => definition.id == id).name;

void _equipWeapons(PixelSurvivorGame game, Map<WeaponId, int> targetLevels) {
  game.unlockedWeaponIds.addAll(targetLevels.keys);
  for (final entry in targetLevels.entries) {
    while (game.weaponSystem.levelOf(entry.key) < entry.value) {
      game.weaponSystem.upgrade(entry.key, game.unlockedWeaponIds);
    }
  }
}

const _goldenFontFamily = 'ReleaseGoldenTestFont';

Future<void> _loadDeterministicGoldenFont() async {
  var directory = File(Platform.resolvedExecutable).parent;
  File? font;
  while (directory.parent.path != directory.path) {
    final candidate = File(
      '${directory.path}${Platform.pathSeparator}packages'
      '${Platform.pathSeparator}flutter_tools${Platform.pathSeparator}static'
      '${Platform.pathSeparator}Ahem.ttf',
    );
    if (candidate.existsSync()) {
      font = candidate;
      break;
    }
    directory = directory.parent;
  }
  if (font == null) {
    throw StateError('Flutter SDK Ahem test font is missing.');
  }
  final bytes = await font.readAsBytes();
  await (FontLoader(
    _goldenFontFamily,
  )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
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

void _expectVisibleTextAndIconsAreConfigured(WidgetTester tester) {
  for (final text in find.byType(Text).evaluate()) {
    final value = (text.widget as Text).data;
    expect(value, isNot(contains('\ufffd')));
  }
  for (final icon in find.byType(Icon).evaluate()) {
    expect((icon.widget as Icon).icon?.fontFamily, 'MaterialIcons');
  }
}

const _result = RunResult(
  outcome: RunOutcome.defeat,
  survivalSeconds: 247,
  kills: 184,
  level: 11,
  bossDefeated: false,
  wonWithLowHealth: false,
  weaponKillCounts: {hwandoSlash: 87},
  weaponLevels: {hwandoSlash: 6},
  weaponDamageTotals: {hwandoSlash: 4200},
);

// Retained as a compact non-game HUD source for local golden diagnostics.
// ignore: unused_element
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
  String? get combatNotice => null;
  @override
  double get combatNoticeSecondsRemaining => 0;
  @override
  int get killStreak => 0;
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
