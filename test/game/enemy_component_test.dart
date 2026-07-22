import 'dart:io';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/components/player_component.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';
import 'package:pixel_survivor/game/content/ids.dart';
import 'package:pixel_survivor/game/content/wave_definitions.dart';
import 'package:pixel_survivor/game/models/damage_event.dart';
import 'package:pixel_survivor/game/systems/enemy_behavior_controller.dart';

void main() {
  group('EnemyComponent', () {
    test('representative enemies keep collisions but use approved sizes', () {
      for (final entry in const {
        plagueRatSwarm: 32.0,
        vengefulSpirit: 40.0,
        sakkatSpecter: 40.0,
        dokkaebi: 44.0,
      }.entries) {
        final enemy = EnemyComponent.fromDefinition(
          enemyDefinitionFor(entry.key)!,
        );

        expect(enemy.size, Vector2.all(18), reason: entry.key);
        expect(enemy.visualSize, entry.value, reason: entry.key);
        expect(
          EnemySpriteSheet.specs[entry.key]!.frameSize,
          128,
          reason: entry.key,
        );
      }
    });

    test('unknown future enemies preserve constructor rank presentation', () {
      final elite = EnemyComponent(
        enemyId: 'future_elite',
        maxHealth: 100,
        moveSpeed: 30,
        damage: 10,
        rank: EnemyRank.elite,
      );
      final boss = EnemyComponent(
        enemyId: 'future_boss',
        maxHealth: 1000,
        moveSpeed: 20,
        damage: 20,
        rank: EnemyRank.boss,
      );

      expect(elite.size, Vector2.all(40));
      expect(elite.visualSize, 81);
      expect(boss.size, Vector2.all(42));
      expect(boss.visualSize, 126);
    });

    test('normal enemy keeps its hitbox while doubling its visual size', () {
      final enemy = EnemyComponent.fromDefinition(enemyDefinitionFor(bandit)!);

      expect(enemy.size, Vector2.all(18));
      expect(enemy.visualSize, 54);
      expect(enemy.visualScale, 3);
      expect(enemy.maxHealth, 18);
      expect(enemy.moveSpeed, 60);
      expect(enemy.damage, 8);
      expect(enemy.experienceValue, 1);
      expect(enemy.anchor, Anchor.center);
      expect(enemy.paint.filterQuality, FilterQuality.medium);
    });

    test('representative 128px enemy art uses smooth downsampling', () {
      final enemy = EnemyComponent.fromDefinition(
        enemyDefinitionFor(plagueRatSwarm)!,
      );

      expect(enemy.paint.filterQuality, FilterQuality.medium);
    });

    test('environmental slow changes movement and can be reset', () {
      final enemy = EnemyComponent(
        enemyId: 'test_enemy',
        maxHealth: 10,
        moveSpeed: 100,
        damage: 1,
        position: Vector2.zero(),
      );

      enemy.setEnvironmentalSlow(0.45);
      enemy.moveToward(Vector2(1000, 0), 1);
      expect(enemy.position.x, closeTo(55, 0.001));
      expect(enemy.effectiveMoveSpeed, closeTo(55, 0.001));

      enemy.setEnvironmentalSlow(0);
      expect(enemy.effectiveMoveSpeed, 100);
    });

    test('detects player overlap using component sizes', () {
      final enemy = EnemyComponent(
        enemyId: 'test_enemy',
        maxHealth: 10,
        moveSpeed: 0,
        damage: 1,
        position: Vector2.zero(),
        size: Vector2.all(18),
      );
      final nearPlayer = PlayerComponent(
        slotIndex: 0,
        maxHealth: 100,
        moveSpeed: 100,
        position: Vector2(20, 0),
        size: Vector2.all(24),
      );
      final farPlayer = PlayerComponent(
        slotIndex: 0,
        maxHealth: 100,
        moveSpeed: 100,
        position: Vector2(22, 0),
        size: Vector2.all(24),
      );

      expect(enemy.overlapsPlayer(nearPlayer), isTrue);
      expect(enemy.overlapsPlayer(farPlayer), isFalse);
    });

    test('unique elite uses authored stats without generic scaling', () {
      final definition = enemyDefinitions.singleWhere(
        (item) => item.id == blackHatAssassin,
      );

      final enemy = EnemyComponent.fromDefinition(definition);

      expect(enemy.isElite, isTrue);
      expect(enemy.rank, EnemyRank.elite);
      expect(enemy.maxHealth, 160);
      expect(enemy.damage, 16);
      expect(enemy.experienceValue, 12);
      expect(enemy.size.x, 40);
      expect(enemy.visualSize, 81);
      expect(enemy.visualScale, closeTo(2.025, 0.00001));
      expect(enemy.anchor, Anchor.center);
    });

    test('herbalist exposes exactly one death zone after lethal damage', () {
      final enemy = EnemyComponent.fromDefinition(
        enemyDefinitionFor(rottenHerbalist)!,
      );

      enemy.takeDamage(enemy.maxHealth);

      expect(enemy.consumeDeathZone(), isTrue);
      expect(enemy.consumeDeathZone(), isFalse);
    });

    test('spear warning locks direction before its thrust request', () {
      var target = Vector2(100, 0);
      final enemy = EnemyComponent.fromDefinition(
        enemyDefinitionFor(spearBandit)!,
        position: Vector2.zero(),
        targetPositionProvider: (_) => target,
      );
      for (var i = 0; i < 45; i++) {
        enemy.update(.05);
      }
      target = Vector2(0, 100);
      for (var i = 0; i < 12; i++) {
        enemy.update(.05);
      }

      final request = enemy.drainAttackRequests().singleWhere(
        (item) => item.kind == EnemyAttackKind.thrust,
      );
      expect(request.direction.x, greaterThan(.99));
      expect(request.direction.y.abs(), lessThan(.01));
    });

    test('vengeful spirit tracks before entering a short dash', () {
      final enemy = EnemyComponent(
        enemyId: vengefulSpirit,
        maxHealth: 22,
        moveSpeed: 10,
        damage: 10,
        behaviorType: EnemyBehaviorType.dash,
        position: Vector2.zero(),
        targetPositionProvider: (_) => Vector2(1000, 0),
      );

      enemy.update(2.4);
      final trackedDistance = enemy.position.x;
      enemy.update(.05);
      expect(enemy.attackPhase, EnemyBehaviorPhase.warning);
      enemy.update(0.55);

      expect(trackedDistance, closeTo(24, 0.001));
      expect(enemy.position.x - trackedDistance, greaterThan(1));
      expect(enemy.isDashing, isTrue);
      enemy.update(0.35);
      expect(enemy.isDashing, isFalse);
    });

    test('dash warning endpoint matches its controller attack endpoint', () {
      final enemy = EnemyComponent(
        enemyId: vengefulSpirit,
        maxHealth: 22,
        moveSpeed: 10,
        damage: 10,
        behaviorType: EnemyBehaviorType.dash,
        position: Vector2.zero(),
        targetPositionProvider: (_) => Vector2(1000, 0),
      );

      enemy.update(2.45);
      final preview = enemy.warningSnapshot!;
      enemy.update(.5);
      final attack = enemy.drainAttackRequests().single;

      expect(preview.telegraphEndpoint, attack.telegraphEndpoint);
    });

    test('ranged warning movement preserves the locked aim facing', () {
      var target = Vector2(180, 0);
      final enemy = EnemyComponent.fromDefinition(
        enemyDefinitionFor(sakkatSpecter)!,
        position: Vector2.zero(),
        targetPositionProvider: (_) => target,
      );
      enemy.update(.05);
      expect(enemy.attackPhase, EnemyBehaviorPhase.warning);
      final before = enemy.position.clone();

      target = Vector2(0, 220);
      enemy.update(.05);

      expect(enemy.position.distanceTo(before), greaterThan(0));
      expect(enemy.facingDirection.x, greaterThan(.99));
      expect(enemy.facingDirection.y.abs(), lessThan(.01));
    });

    test('ranged warning endpoint matches its controller shot endpoint', () {
      final enemy = EnemyComponent.fromDefinition(
        enemyDefinitionFor(sakkatSpecter)!,
        position: Vector2.zero(),
        targetPositionProvider: (_) => Vector2(180, 0),
      );

      enemy.update(.05);
      final preview = enemy.warningSnapshot!;
      enemy.update(.7);
      final shot = enemy.drainAttackRequests().single;

      expect(preview.telegraphEndpoint, shot.telegraphEndpoint);
    });

    test('dokkaebi reduces received knockback by seventy percent', () {
      final enemy = EnemyComponent(
        enemyId: dokkaebi,
        maxHealth: 38,
        moveSpeed: 36,
        damage: 13,
        behaviorType: EnemyBehaviorType.tank,
      );

      enemy.applyKnockback(Vector2(100, 0));

      expect(enemy.knockbackVelocity.x, closeTo(30, 0.001));
    });

    test('dokkaebi reduces frontal normal hits but not rear explosions', () {
      final enemy = EnemyComponent.fromDefinition(
        enemyDefinitionFor(dokkaebi)!,
        position: Vector2.zero(),
      );
      enemy.debugFace(Vector2(1, 0));
      final frontMeleeEvent = DamageEvent(
        target: enemy,
        damage: 10,
        knockback: 0,
        direction: Vector2(-1, 0),
        traits: const {AttackTrait.melee},
      );
      final rearExplosionEvent = DamageEvent(
        target: enemy,
        damage: 10,
        knockback: 0,
        direction: Vector2(1, 0),
        traits: const {AttackTrait.explosion},
      );

      expect(enemy.resolveIncomingDamage(frontMeleeEvent), 5);
      expect(enemy.consumeBlockFeedback(), isTrue);
      expect(enemy.resolveIncomingDamage(rearExplosionEvent), 10);
      expect(enemy.consumeBlockFeedback(), isFalse);
    });

    test('dokkaebi exposes a directional shield matching its facing', () {
      final enemy = EnemyComponent.fromDefinition(enemyDefinitionFor(dokkaebi)!)
        ..debugFace(Vector2(0, -1));

      expect(enemy.hasDirectionalShield, isTrue);
      expect(enemy.shieldDirection, Vector2(0, -1));
    });

    test('synergy bypasses the shield without block feedback', () {
      final enemy = EnemyComponent.fromDefinition(enemyDefinitionFor(dokkaebi)!)
        ..debugFace(Vector2(1, 0));
      final event = DamageEvent(
        target: enemy,
        damage: 10,
        knockback: 0,
        direction: Vector2(-1, 0),
        traits: const {AttackTrait.synergy},
      );

      expect(enemy.resolveIncomingDamage(event), 10);
      expect(enemy.isShieldBypassedBy(event), isTrue);
      expect(enemy.consumeBlockFeedback(), isFalse);
    });

    test('dokkaebi only partly blocks frontal piercing hits', () {
      final enemy = EnemyComponent.fromDefinition(
        enemyDefinitionFor(dokkaebi)!,
      );
      enemy.debugFace(Vector2(1, 0));
      final event = DamageEvent(
        target: enemy,
        damage: 10,
        knockback: 0,
        direction: Vector2(-1, 0),
        traits: const {AttackTrait.projectile, AttackTrait.piercing},
      );

      expect(enemy.resolveIncomingDamage(event), 8);
    });

    test('plague rats separate from nearby rats while pursuing', () {
      late EnemyComponent enemy;
      final neighbor = EnemyComponent(
        enemyId: plagueRatSwarm,
        maxHealth: 10,
        moveSpeed: 0,
        damage: 6,
        position: Vector2(0, 2),
      );
      enemy = EnemyComponent(
        enemyId: plagueRatSwarm,
        maxHealth: 10,
        moveSpeed: 10,
        damage: 6,
        behaviorType: EnemyBehaviorType.swarm,
        position: Vector2.zero(),
        targetPositionProvider: (_) => Vector2(100, 0),
        nearbyEnemiesProvider: () => [enemy, neighbor],
      );

      enemy.update(1);

      expect(enemy.position.y, lessThan(0));
      expect(enemy.position.x, greaterThan(0));
    });

    test('enemy hit flash expires and knockback decays', () {
      final enemy = EnemyComponent(
        enemyId: bandit,
        maxHealth: 18,
        moveSpeed: 60,
        damage: 8,
        position: Vector2.zero(),
      );

      enemy.registerHit(knockback: Vector2(80, 0));
      expect(enemy.isHitFlashing, isTrue);
      enemy.update(0.3);

      expect(enemy.isHitFlashing, isFalse);
      expect(enemy.knockbackVelocity.length, lessThan(80));
    });

    test('move attack hit and death select matching visual states', () {
      final enemy = EnemyComponent(
        enemyId: bandit,
        maxHealth: 18,
        moveSpeed: 60,
        damage: 8,
        position: Vector2.zero(),
      );

      enemy.moveToward(Vector2(10, 0), 0.1);
      expect(enemy.visualState, EnemyAnimationState.moving);

      enemy.playAttack();
      expect(enemy.visualState, EnemyAnimationState.attacking);

      enemy.takeDamage(1);
      expect(enemy.visualState, EnemyAnimationState.hit);

      enemy.takeDamage(100);
      expect(enemy.visualState, EnemyAnimationState.death);
    });

    test('enemy sheets totally route every current stage enemy', () {
      final stageEnemyIds = stageWaveDefinitions.values
          .expand((waves) => waves)
          .expand(
            (wave) => [...wave.enemyWeights.keys, ...wave.eliteWeights.keys],
          )
          .toSet();
      final definedEnemyIds = enemyDefinitions.map((enemy) => enemy.id).toSet();

      expect(EnemySpriteSheet.specs.keys, containsAll(stageEnemyIds));
      expect(EnemySpriteSheet.specs.keys, containsAll(definedEnemyIds));
      expect(EnemySpriteSheet.specs[bandit]!.frameSize, 128);
      expect(
        EnemySpriteSheet.specs[bandit]!.assetKey,
        'monsters/bandit_128.png',
      );
    });

    test('enemy sheets share the 4-4-2-6 frame contract', () {
      expect(EnemySpriteSheet.moveFrames, [0, 1, 2, 3]);
      expect(EnemySpriteSheet.attackFrames, [4, 5, 6, 7]);
      expect(EnemySpriteSheet.hitFrames, [8, 9]);
      expect(EnemySpriteSheet.deathFrames, [10, 11, 12, 13, 14, 15]);
      expect(
        EnemySpriteSheet.specs.keys,
        containsAll(enemyDefinitions.map((enemy) => enemy.id)),
      );
      expect(EnemySpriteSheet.specs[plagueRatSwarm]!.frameSize, 128);
      expect(EnemySpriteSheet.specs[vengefulSpirit]!.frameSize, 128);
      expect(EnemySpriteSheet.specs[sakkatSpecter]!.frameSize, 128);
      expect(EnemySpriteSheet.specs[dokkaebi]!.frameSize, 128);
      expect(
        EnemySpriteSheet.specs[plagueRatSwarm]!.assetKey,
        'monsters/plague_rat_swarm_128.png',
      );
      expect(
        EnemySpriteSheet.specs[vengefulSpirit]!.assetKey,
        'monsters/vengeful_spirit_128.png',
      );
      expect(
        EnemySpriteSheet.specs[sakkatSpecter]!.assetKey,
        'monsters/sakkat_specter_128.png',
      );
      expect(
        EnemySpriteSheet.specs[dokkaebi]!.assetKey,
        'monsters/dokkaebi_128.png',
      );
      expect(EnemySpriteSheet.specs[bandit]!.frameSize, 128);
      expect(
        EnemySpriteSheet.specs[bandit]!.assetKey,
        'monsters/bandit_128.png',
      );
      expect(EnemySpriteSheet.specs[fallenGeneral]!.frameSize, 128);
    });

    test('fallback renderer never draws a full-body rectangle', () {
      final source = File(
        'lib/game/components/enemy_component.dart',
      ).readAsStringSync();

      expect(source, contains('final head = Path()'));
      expect(source, contains('final body = Path()'));
      expect(source, isNot(contains('canvas.drawRect(')));
    });

    test('representative atlases build real role animation maps', () async {
      for (final id in const [
        plagueRatSwarm,
        vengefulSpirit,
        sakkatSpecter,
        dokkaebi,
      ]) {
        final spec = EnemySpriteSheet.specs[id]!;
        final image = await _loadEnemyAtlas(spec);
        addTearDown(image.dispose);
        final animations = EnemySpriteSheet.animations(image, spec);

        expect(
          animations[EnemyAnimationState.moving]!.frames,
          hasLength(4),
          reason: '$id move',
        );
        expect(
          animations[EnemyAnimationState.attacking]!.frames,
          hasLength(4),
          reason: '$id attack',
        );
        expect(
          animations[EnemyAnimationState.hit]!.frames,
          hasLength(2),
          reason: '$id hit',
        );
        expect(
          animations[EnemyAnimationState.death]!.frames,
          hasLength(6),
          reason: '$id death',
        );
        expect(
          animations[EnemyAnimationState.moving]!
              .frames
              .first
              .sprite
              .srcPosition,
          Vector2(0, 0),
          reason: '$id move frame 0',
        );
        expect(
          animations[EnemyAnimationState.attacking]!
              .frames
              .first
              .sprite
              .srcPosition,
          Vector2(0, 128),
          reason: '$id attack frame 4',
        );
        expect(
          animations[EnemyAnimationState.hit]!.frames.first.sprite.srcPosition,
          Vector2(0, 256),
          reason: '$id hit frame 8',
        );
        expect(
          animations[EnemyAnimationState.death]!
              .frames
              .first
              .sprite
              .srcPosition,
          Vector2(256, 256),
          reason: '$id death frame 10',
        );
      }
    });

    test(
      'dash warning holds frame four then active dash replays attack',
      () async {
        final spec = EnemySpriteSheet.specs[vengefulSpirit]!;
        final image = await _loadEnemyAtlas(spec);
        addTearDown(image.dispose);
        final enemy = EnemyComponent.fromDefinition(
          enemyDefinitionFor(vengefulSpirit)!,
          targetPositionProvider: (_) => Vector2(100, 0),
        )..animations = EnemySpriteSheet.animations(image, spec);
        enemy.current = EnemyAnimationState.moving;

        enemy.update(enemy.behaviorProfile.cooldownSeconds + 0.01);

        expect(enemy.attackPhase, EnemyBehaviorPhase.warning);
        expect(enemy.visualState, EnemyAnimationState.attacking);
        expect(enemy.animationTicker!.currentIndex, 0);
        expect(enemy.animationTicker!.isPaused, isTrue);

        enemy.playAttack();
        expect(enemy.animationTicker!.currentIndex, 0);
        expect(enemy.animationTicker!.isPaused, isTrue);

        enemy.update(enemy.behaviorProfile.warningSeconds);

        expect(enemy.attackPhase, EnemyBehaviorPhase.active);
        expect(enemy.visualState, EnemyAnimationState.attacking);
        expect(enemy.animationTicker!.currentIndex, 0);
        expect(enemy.animationTicker!.isPaused, isFalse);
        enemy.update(0.09);
        expect(enemy.animationTicker!.currentIndex, greaterThan(0));
      },
    );

    test(
      'authored hit flash tints then clears without cancelling warning',
      () async {
        final spec = EnemySpriteSheet.specs[sakkatSpecter]!;
        final image = await _loadEnemyAtlas(spec);
        addTearDown(image.dispose);
        final enemy = EnemyComponent.fromDefinition(
          enemyDefinitionFor(sakkatSpecter)!,
          targetPositionProvider: (_) => Vector2(100, 0),
        )..animations = EnemySpriteSheet.animations(image, spec);
        enemy.current = EnemyAnimationState.moving;

        enemy.update(0);
        expect(enemy.attackPhase, EnemyBehaviorPhase.warning);
        enemy.registerHit();

        expect(enemy.isHitFlashing, isTrue);
        expect(enemy.attackPhase, EnemyBehaviorPhase.warning);
        expect(enemy.visualState, EnemyAnimationState.attacking);
        expect(enemy.animationTicker!.currentIndex, 0);
        expect(enemy.animationTicker!.isPaused, isTrue);
        expect(
          enemy.paint.colorFilter,
          isNotNull,
          reason: 'authored sprite paint must visibly tint during hit flash',
        );

        enemy.update(EnemySpriteSheet.hitDurationSeconds + 0.01);

        expect(enemy.isHitFlashing, isFalse);
        expect(enemy.paint.colorFilter, isNull);
        expect(enemy.attackPhase, EnemyBehaviorPhase.warning);
        expect(enemy.visualState, EnemyAnimationState.attacking);
        expect(enemy.animationTicker!.currentIndex, 0);
        expect(enemy.animationTicker!.isPaused, isTrue);
      },
    );

    test('lethal damage keeps death visuals alive for their full sequence', () {
      final enemy = EnemyComponent(
        enemyId: bandit,
        maxHealth: 18,
        moveSpeed: 60,
        damage: 8,
      );

      enemy.takeDamage(18);
      expect(enemy.deathVisualComplete, isFalse);
      enemy.update(EnemySpriteSheet.deathDurationSeconds - 0.01);
      expect(enemy.deathVisualComplete, isFalse);
      enemy.update(0.01);
      expect(enemy.deathVisualComplete, isTrue);
    });
  });
}

Future<Image> _loadEnemyAtlas(EnemySpriteSpec spec) async {
  final bytes = File('assets/images/${spec.assetKey}').readAsBytesSync();
  final codec = await instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
}
