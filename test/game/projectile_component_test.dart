import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/components/projectile_component.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/models/player_slot.dart';
import 'package:pixel_survivor/game/pixel_survivor_game.dart';

void main() {
  ProjectileComponent projectileAt(
    Vector2 position, {
    Vector2? velocity,
    int pierce = 0,
  }) {
    return ProjectileComponent(
      weaponId: gakgungShot,
      damage: 3,
      position: position,
      velocity: velocity ?? Vector2.zero(),
      pierce: pierce,
      sizeMultiplier: 1,
    );
  }

  EnemyComponent enemyAt(Vector2 position) {
    return EnemyComponent(
      enemyId: 'bandit',
      maxHealth: 10,
      moveSpeed: 0,
      damage: 1,
      position: position,
      size: Vector2.all(18),
    );
  }

  test('update retains the exact previous world position', () {
    final projectile = projectileAt(Vector2.zero(), velocity: Vector2(100, 0));

    projectile.update(.5);

    expect(projectile.previousPosition, Vector2.zero());
    expect(projectile.position, Vector2(50, 0));
  });

  test('swept contacts are returned in travel order', () {
    final projectile = projectileAt(
      Vector2.zero(),
      velocity: Vector2(100, 0),
      pierce: 1,
    );
    projectile.update(1);

    final contacts = projectile.contactsFor([
      enemyAt(Vector2(75, 0)),
      enemyAt(Vector2(25, 0)),
    ]);

    expect(
      contacts.map((item) => item.enemy.position.x),
      orderedEquals([25, 75]),
    );
    expect(
      contacts.first.contact.travelFraction,
      lessThan(contacts.last.contact.travelFraction),
    );
  });

  test('swept collision excludes a near miss beyond the enemy hurtbox', () {
    final projectile = projectileAt(Vector2.zero(), velocity: Vector2(100, 0));
    projectile.update(1);

    expect(projectile.contactsFor([enemyAt(Vector2(50, 12))]), isEmpty);
  });

  test('pause synchronization never replays the old movement segment', () {
    final projectile = projectileAt(Vector2.zero(), velocity: Vector2(100, 0));
    final enemyOnlyInOldSweep = enemyAt(Vector2(-15, 0));
    projectile.update(.1);
    expect(projectile.contactsFor([enemyOnlyInOldSweep]), isNotEmpty);

    final beforePause = projectile.position.clone();
    projectile.synchronizePreviousPosition();

    expect(projectile.previousPosition, beforePause);
    expect(projectile.contactsFor([enemyOnlyInOldSweep]), isEmpty);
  });

  test('contact and hit registration apply once per enemy', () {
    final projectile = projectileAt(
      Vector2.zero(),
      velocity: Vector2(100, 0),
      pierce: 1,
    );
    final enemy = enemyAt(Vector2(50, 0));
    projectile.update(1);

    final contact = projectile.contactsFor([enemy]).single;

    expect(contact.contact.point.x, lessThan(enemy.position.x));
    expect(projectile.registerHit(contact.enemy), isTrue);
    expect(projectile.registerHit(contact.enemy), isFalse);
  });

  test('missing projectile art prevents combat from starting', () async {
    final image = await _solidImage();
    addTearDown(image.dispose);
    final game = PixelSurvivorGame(
      playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
      onRunEnded: null,
      visualAssetLoader: (key) async {
        if (key == 'projectiles/player/hawk_flight_128.png') {
          throw StateError('missing $key');
        }
        return image;
      },
    );
    game.onGameResize(Vector2(960, 540));
    addTearDown(game.onDispose);

    await expectLater(game.onLoad(), throwsStateError);
  });
}

Future<ui.Image> _solidImage() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(const ui.Rect.fromLTWH(0, 0, 1, 1), ui.Paint());
  return recorder.endRecording().toImage(1, 1);
}
