import 'dart:io';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/game_hud.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
import 'package:pixel_survivor/game/combat/attack_timeline.dart';
import 'package:pixel_survivor/game/combat/attack_visual_event.dart';
import 'package:pixel_survivor/game/combat/combat_vfx_primitives.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/components/enemy_hazard_component.dart';
import 'package:pixel_survivor/game/components/experience_gem_component.dart';
import 'package:pixel_survivor/game/components/five_color_ward_component.dart';
import 'package:pixel_survivor/game/components/frost_field_component.dart';
import 'package:pixel_survivor/game/components/hwando_vfx_component.dart';
import 'package:pixel_survivor/game/components/player_component.dart';
import 'package:pixel_survivor/game/components/projectile_component.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/attack_visual_registry.dart';
import 'package:pixel_survivor/game/content/combat_visual_factory.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/models/player_slot.dart';
import 'package:pixel_survivor/game/pixel_survivor_game.dart';
import 'package:pixel_survivor/game/systems/hwando_executor.dart';
import 'package:pixel_survivor/game/systems/talisman_executor.dart';
import 'package:pixel_survivor/game/systems/weapon_synergy_resolver.dart';

void main() {
  setUpAll(_loadDeterministicGoldenFont);

  testWidgets('release Hwando active strike at 960x540 landscape', (
    tester,
  ) async {
    final fixture = await _pumpHwandoLandscapeFixture(tester);

    expect(fixture.enemies, hasLength(3));
    expect(
      fixture.game.worldChildrenOfType<HwandoVfxComponent>(),
      hasLength(1),
    );
    expect(find.byKey(const Key('hud-status')), findsOneWidget);

    await expectLater(
      find.byKey(const Key('game-surface')),
      matchesGoldenFile('goldens/hwando_release_landscape_16_9.png'),
    );
  });

  testWidgets('balanced casual early combat at 390x844', (tester) async {
    final fixture = await _pumpCombatFixture(tester, late: false);

    _expectReviewedSpectacleFrame(fixture);
    _expectProgressHeader(fixture, tester);

    await expectLater(
      find.byKey(const Key('game-surface')),
      matchesGoldenFile('goldens/balanced_casual_early_390x844.png'),
    );
  });

  testWidgets('balanced casual late mastery combat at 390x844', (tester) async {
    final fixture = await _pumpCombatFixture(tester, late: true);

    expect(fixture.game.enemyCount, greaterThanOrEqualTo(30));
    expect(fixture.enemyIds, containsAll(_representativeEnemyIds));
    expect(fixture.game.weaponSystem.levelOf(hwandoSlash), 6);
    expect(fixture.game.weaponSystem.levelOf(talismanThrow), 6);
    expect(
      fixture.game.worldChildrenOfType<FiveColorWardComponent>().length,
      greaterThanOrEqualTo(2),
    );
    expect(
      fixture.game.worldChildrenOfType<HwandoVfxComponent>().any(
        (effect) => effect.event.effectId == 'hwando_master_circle',
      ),
      isTrue,
    );
    expect(
      fixture.game.worldChildrenOfType<HwandoVfxComponent>().any(
        (effect) => effect.event.effectId == sealingSlash,
      ),
      isTrue,
    );
    expect(find.byKey(const Key('hud-status')), findsOneWidget);

    await expectLater(
      find.byKey(const Key('game-surface')),
      matchesGoldenFile('goldens/balanced_casual_late_390x844.png'),
    );
  });
}

Future<_CombatFixture> _pumpHwandoLandscapeFixture(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(960, 540);
  addTearDown(tester.view.reset);

  final game = PixelSurvivorGame(
    playerSlot: const PlayerSlot(index: 0, characterId: exorcistDosa),
    onRunEnded: null,
    random: Random(960540),
    rewardRoll: () => .99,
    bossRoll: () => .5,
    screenShakeEnabled: false,
    damageNumbersEnabled: false,
  );
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        splashFactory: NoSplash.splashFactory,
        fontFamily: _goldenFontFamily,
      ),
      home: RepaintBoundary(
        key: const Key('game-surface'),
        child: Stack(
          fit: StackFit.expand,
          children: [
            GameWidget(
              game: game,
              overlayBuilderMap: {
                PixelSurvivorGame.levelUpOverlayId: (_, _) =>
                    const SizedBox.shrink(),
              },
            ),
            GameHud(source: game, onPause: () {}),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
  for (
    var attempt = 0;
    attempt < 120 && game.activePlayers.isEmpty;
    attempt += 1
  ) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(game.activePlayers, hasLength(1));
  game.pauseEngine();

  await tester.runAsync(
    () => Future.wait([
      game.images.load(PlayerSpriteSheet.authoredAssetKey),
      game.images.load('stages/joseon_courtyard_combat_1024x1824.png'),
      game.images.load(EnemySpriteSheet.specs[bandit]!.assetKey),
      for (final layer in AttackVisualRegistry.byId('hwando_slash').layers)
        game.images.load(layer.assetKey),
    ]),
  );
  game.resumeEngine();
  await tester.pump(const Duration(milliseconds: 1));
  game.pauseEngine();

  final player = game.activePlayers.single;
  final enemies = <EnemyComponent>[
    game.debugSpawnEnemy(bandit, position: player.position + Vector2(46, -18)),
    game.debugSpawnEnemy(bandit, position: player.position + Vector2(70, 0)),
    game.debugSpawnEnemy(bandit, position: player.position + Vector2(104, 20)),
  ];
  game.resumeEngine();
  await tester.pump(const Duration(milliseconds: 1));
  game.pauseEngine();
  for (var attempt = 0; attempt < 12; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 1));
    if (player.animations != null &&
        enemies.every((enemy) => enemy.animations != null)) {
      break;
    }
  }

  final attack = HwandoExecutor()
      .tick(
        HwandoTickInput(
          dt: 0,
          level: 1,
          origin: player.position,
          aimDirection: Vector2(1, 0),
          damageMultiplier: 1,
          sizeMultiplier: 1,
        ),
      )
      .single;
  final effect = _addHwandoVisual(game, attack);
  game.processLifecycleEvents();
  effect.update(.075);
  await tester.pump();
  game.pauseEngine();

  expect(effect.phase, AttackPhase.active);
  expect(enemies.every((enemy) => enemy.isMounted), isTrue);
  expect(tester.takeException(), isNull);
  return _CombatFixture(game: game, enemies: enemies);
}

const _goldenFontFamily = 'BalancedCasualGoldenTestFont';
const _representativeEnemyIds = <String>{
  plagueRatSwarm,
  bandit,
  vengefulSpirit,
  sakkatSpecter,
  dokkaebi,
  plagueCrow,
  spearBandit,
  rottenHerbalist,
  graveEmber,
  blackHatAssassin,
  brokenJangseungSpirit,
  sorrowfulMaidenGhost,
};

const _priorMissingSpriteEnemyIds = <String>{
  plagueCrow,
  spearBandit,
  rottenHerbalist,
  graveEmber,
  blackHatAssassin,
  brokenJangseungSpirit,
  sorrowfulMaidenGhost,
};

void _expectReviewedSpectacleFrame(_CombatFixture fixture) {
  expect(fixture.game.enemyCount, greaterThanOrEqualTo(13));
  expect(fixture.enemyIds, contains(bandit));
  expect(fixture.enemyIds, containsAll(_priorMissingSpriteEnemyIds));
  expect(fixture.game.worldChildrenOfType<FrostFieldComponent>(), isNotEmpty);
  expect(fixture.game.worldChildrenOfType<ProjectileComponent>(), isNotEmpty);
  expect(fixture.game.worldChildrenOfType<EnemyHazardComponent>(), isNotEmpty);
  expect(fixture.enemies.any((enemy) => enemy.warningSnapshot != null), isTrue);
  final gems = fixture.game.worldChildrenOfType<ExperienceGemComponent>();
  expect(gems, isNotEmpty);
  expect(gems.any((gem) => gem.visualScale > 1), isTrue);
}

void _expectProgressHeader(_CombatFixture fixture, WidgetTester tester) {
  expect(fixture.game.currentExperience, greaterThan(0));
  expect(find.byKey(const Key('hud-status')), findsOneWidget);
  expect(find.byKey(const Key('hud-player-level')), findsOneWidget);
  expect(find.byKey(const Key('hud-xp-bar')), findsOneWidget);
  expect(find.byKey(const Key('hud-xp-fill')), findsOneWidget);
}

Future<_CombatFixture> _pumpCombatFixture(
  WidgetTester tester, {
  required bool late,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final game = PixelSurvivorGame(
    playerSlot: const PlayerSlot(index: 0, characterId: exorcistDosa),
    onRunEnded: null,
    random: Random(late ? 844390 : 390844),
    rewardRoll: () => .99,
    bossRoll: () => .5,
    screenShakeEnabled: false,
    damageNumbersEnabled: false,
  );
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        splashFactory: NoSplash.splashFactory,
        fontFamily: _goldenFontFamily,
      ),
      home: RepaintBoundary(
        key: const Key('game-surface'),
        child: Stack(
          fit: StackFit.expand,
          children: [
            GameWidget(
              game: game,
              overlayBuilderMap: {
                PixelSurvivorGame.levelUpOverlayId: (_, _) =>
                    const SizedBox.shrink(),
              },
            ),
            GameHud(source: game, onPause: () {}),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
  for (
    var attempt = 0;
    attempt < 120 && game.activePlayers.isEmpty;
    attempt++
  ) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(game.activePlayers, hasLength(1));
  game.pauseEngine();

  await tester.runAsync(
    () => Future.wait([
      game.images.load(PlayerSpriteSheet.authoredAssetKey),
      game.images.load('effects/hwando_slash_ribbon_512.png'),
      game.images.load('stages/joseon_courtyard_combat_1024x1824.png'),
      for (final enemyId in _representativeEnemyIds)
        game.images.load(EnemySpriteSheet.specs[enemyId]!.assetKey),
    ]),
  );

  game.debugAdvanceTo(late ? 245 : 18);
  final positions = late ? _lateEnemyPositions() : _earlyEnemyPositions();
  final viewportOrigin = game.activePlayers.single.position - Vector2(195, 422);
  final enemies = <EnemyComponent>[];
  for (var index = 0; index < positions.length; index += 1) {
    enemies.add(
      game.debugSpawnEnemy(
        _representativeEnemyIds.elementAt(
          index % _representativeEnemyIds.length,
        ),
        position: viewportOrigin + positions[index],
      ),
    );
  }
  game.resumeEngine();
  await tester.pump(const Duration(milliseconds: 1));
  game.pauseEngine();
  for (var attempt = 0; attempt < 12; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 1));
    if (game.activePlayers.single.animations != null &&
        enemies.every((enemy) => enemy.animations != null)) {
      break;
    }
  }
  expect(game.activePlayers.single.animations, isNotNull);
  expect(enemies.every((enemy) => enemy.isMounted), isTrue);
  expect(enemies.every((enemy) => enemy.animations != null), isTrue);

  if (late) {
    _upgradeTo(game, hwandoSlash, 6);
    _upgradeTo(game, talismanThrow, 6);
    game.activePlayers.single.playAttack(Vector2(1, 0));
    _addLateMasteryPresentation(game, enemies);
    game.resumeEngine();
    await tester.pump(const Duration(milliseconds: 1));
    game.pauseEngine();
  } else {
    expect(game.gainExperience(4), isFalse);
    _addReviewedCombatPresentation(game);
    game.resumeEngine();
    await tester.pump(const Duration(milliseconds: 1));
    game.pauseEngine();
  }

  expect(tester.takeException(), isNull);
  return _CombatFixture(game: game, enemies: enemies);
}

void _addReviewedCombatPresentation(PixelSurvivorGame game) {
  final viewportOrigin = game.activePlayers.single.position - Vector2(195, 422);
  game.addWorldComponent(
    FrostFieldComponent(
      weaponId: frostFlask,
      damage: 0,
      radius: 52,
      durationSeconds: 30,
      slowFraction: .25,
      knockback: 0,
      position: viewportOrigin + Vector2(100, 410),
      tier: CombatVfxTier.master,
    ),
  );
  game.addWorldComponent(
    ProjectileComponent(
      weaponId: singijeonVolley,
      damage: 0,
      position: viewportOrigin + Vector2(145, 535),
      velocity: Vector2(80, -18),
      lifetime: 30,
      pierce: 99,
      isMasterLead: true,
      tier: CombatVfxTier.master,
      size: Vector2.all(18),
    ),
  );
  game.addWorldComponent(
    EnemyHazardComponent.poison(
      position: viewportOrigin + Vector2(295, 420),
      damage: 0,
      sourceId: 'golden-poison-warning',
    ),
  );
  game.addWorldComponent(
    ExperienceGemComponent(
      experienceValue: 1,
      position: viewportOrigin + Vector2(78, 720),
    ),
  );
  game.addWorldComponent(
    ExperienceGemComponent(
      experienceValue: 64,
      position: viewportOrigin + Vector2(300, 710),
    ),
  );
}

void _upgradeTo(PixelSurvivorGame game, String weaponId, int level) {
  game.unlockedWeaponIds.add(weaponId);
  while (game.weaponSystem.levelOf(weaponId) < level) {
    game.weaponSystem.upgrade(weaponId, game.unlockedWeaponIds);
  }
}

void _addLateMasteryPresentation(
  PixelSurvivorGame game,
  List<EnemyComponent> enemies,
) {
  final playerPosition = game.activePlayers.single.position;
  final hwando = HwandoExecutor();
  final hwandoAttacks = <AttackInstance>[];
  for (var step = 0; step < 8; step += 1) {
    hwandoAttacks.addAll(
      hwando.tick(
        HwandoTickInput(
          dt: step == 0 ? 0 : .05,
          level: 6,
          origin: playerPosition,
          aimDirection: Vector2(1, 0),
          damageMultiplier: 1,
          sizeMultiplier: 1,
        ),
      ),
    );
  }
  final masterCircle = hwandoAttacks.singleWhere(
    (attack) => attack.spec.id == 'hwando_master_circle',
  );
  _addAttackVisual(game, masterCircle);

  final talisman = TalismanExecutor(random: Random(390844));
  final talismanResult = talisman.tick(
    TalismanTickInput(
      dt: 0,
      level: 6,
      now: 245,
      origin: playerPosition,
      enemies: enemies,
      damageMultiplier: 1,
      sizeMultiplier: 1,
    ),
  );
  expect(talismanResult.wards, hasLength(TalismanExecutor.maxMasterWards));
  for (final ward in talismanResult.wards) {
    game.addWorldComponent(
      FiveColorWardComponent(
        attack: ward.attack,
        tickSeconds: ward.tickSeconds,
      ),
    );
  }

  final synergy = WeaponSynergyResolver();
  final target = enemies[16];
  synergy.onHwandoHit(
    target: target,
    nearby: enemies,
    now: 244.9,
    originatingAttackId: 1,
  );
  final detonation = synergy.onHwandoHit(
    target: target,
    nearby: enemies,
    now: 245,
    originatingAttackId: 2,
  );
  _addAttackVisual(game, detonation.attack!);
}

void _addAttackVisual(PixelSurvivorGame game, AttackInstance attack) {
  final event = AttackVisualEvent.fromAttack(attack);
  final spec = AttackVisualRegistry.byId(event.effectId);
  final images = {
    for (final layer in spec.layers)
      layer.assetKey: game.images.fromCache(layer.assetKey),
  };
  game.addWorldComponent(
    CombatVisualFactory(images: images).createFromSpec(event, spec),
  );
}

HwandoVfxComponent _addHwandoVisual(
  PixelSurvivorGame game,
  AttackInstance attack,
) {
  final event = AttackVisualEvent.fromAttack(attack);
  final spec = AttackVisualRegistry.byId(event.effectId);
  final images = {
    for (final layer in spec.layers)
      layer.assetKey: game.images.fromCache(layer.assetKey),
  };
  final component =
      CombatVisualFactory(images: images).createFromSpec(event, spec)
          as HwandoVfxComponent;
  game.addWorldComponent(component);
  return component;
}

List<Vector2> _earlyEnemyPositions() => [
  Vector2(52, 175),
  Vector2(145, 185),
  Vector2(245, 180),
  Vector2(338, 205),
  Vector2(52, 300),
  Vector2(335, 315),
  Vector2(48, 505),
  Vector2(340, 515),
  Vector2(65, 615),
  Vector2(155, 645),
  Vector2(245, 635),
  Vector2(335, 610),
  Vector2(195, 750),
];

List<Vector2> _lateEnemyPositions() => [
  for (var row = 0; row < 6; row += 1)
    for (var column = 0; column < 6; column += 1)
      Vector2(45 + column * 60, 150 + row * 108),
];

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
  if (font == null) throw StateError('Flutter SDK Ahem test font is missing.');
  final bytes = await font.readAsBytes();
  await (FontLoader(
    _goldenFontFamily,
  )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
}

class _CombatFixture {
  const _CombatFixture({required this.game, required this.enemies});

  final PixelSurvivorGame game;
  final List<EnemyComponent> enemies;

  Set<String> get enemyIds => enemies.map((enemy) => enemy.enemyId).toSet();
}
