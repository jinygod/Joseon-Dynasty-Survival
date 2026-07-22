import 'dart:io';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/game_hud.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
import 'package:pixel_survivor/game/components/attack_effect_component.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/components/five_color_ward_component.dart';
import 'package:pixel_survivor/game/components/player_component.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/models/player_slot.dart';
import 'package:pixel_survivor/game/pixel_survivor_game.dart';
import 'package:pixel_survivor/game/systems/hwando_executor.dart';
import 'package:pixel_survivor/game/systems/talisman_executor.dart';
import 'package:pixel_survivor/game/systems/weapon_synergy_resolver.dart';

void main() {
  setUpAll(_loadDeterministicGoldenFont);

  testWidgets('balanced casual early combat at 390x844', (tester) async {
    final fixture = await _pumpCombatFixture(tester, late: false);

    expect(fixture.game.enemyCount, 8);
    expect(fixture.enemyIds, containsAll(_representativeEnemyIds));
    expect(find.byKey(const Key('hud-status')), findsOneWidget);

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
      fixture.game.children.whereType<FiveColorWardComponent>().length,
      greaterThanOrEqualTo(2),
    );
    expect(
      fixture.game.children.whereType<AttackEffectComponent>().any(
        (effect) => effect.instance.spec.id == 'hwando_master_circle',
      ),
      isTrue,
    );
    expect(
      fixture.game.children.whereType<AttackEffectComponent>().any(
        (effect) => effect.instance.spec.id == sealingSlash,
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

const _goldenFontFamily = 'BalancedCasualGoldenTestFont';
const _representativeEnemyIds = <String>{
  plagueRatSwarm,
  vengefulSpirit,
  sakkatSpecter,
  dokkaebi,
};

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
  await tester.pump(const Duration(milliseconds: 16));
  expect(game.activePlayers, hasLength(1));
  game.pauseEngine();

  await tester.runAsync(
    () => Future.wait([
      game.images.load(PlayerSpriteSheet.authoredAssetKey),
      for (final enemyId in _representativeEnemyIds)
        game.images.load(EnemySpriteSheet.specs[enemyId]!.assetKey),
    ]),
  );

  game.debugAdvanceTo(late ? 245 : 18);
  final positions = late ? _lateEnemyPositions() : _earlyEnemyPositions();
  final enemies = <EnemyComponent>[];
  for (var index = 0; index < positions.length; index += 1) {
    enemies.add(
      game.debugSpawnEnemy(
        _representativeEnemyIds.elementAt(
          index % _representativeEnemyIds.length,
        ),
        position: positions[index],
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
  }

  expect(tester.takeException(), isNull);
  return _CombatFixture(game: game, enemies: enemies);
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
  game.add(AttackEffectComponent(instance: masterCircle));

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
    game.add(
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
  game.add(AttackEffectComponent(instance: detonation.attack!));
}

List<Vector2> _earlyEnemyPositions() => [
  Vector2(72, 250),
  Vector2(195, 220),
  Vector2(320, 278),
  Vector2(82, 474),
  Vector2(312, 492),
  Vector2(110, 650),
  Vector2(242, 650),
  Vector2(330, 680),
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
