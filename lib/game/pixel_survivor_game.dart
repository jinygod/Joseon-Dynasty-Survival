import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import 'components/enemy_component.dart';
import 'components/player_component.dart';
import 'content/character_definitions.dart';
import 'content/enemy_definitions.dart';
import 'content/ids.dart';
import 'models/player_slot.dart';
import 'systems/spawn_system.dart';

class PixelSurvivorGame extends FlameGame {
  PixelSurvivorGame({required List<PlayerSlot> playerSlots})
    : playerSlots = List.unmodifiable(playerSlots) {
    if (this.playerSlots.isEmpty) {
      throw ArgumentError.value(
        playerSlots,
        'playerSlots',
        'must not be empty',
      );
    }
  }

  final List<PlayerSlot> playerSlots;
  final SpawnSystem spawnSystem = const SpawnSystem();
  final List<PlayerComponent> activePlayers = [];

  double _elapsedSeconds = 0;
  double _spawnTimer = 0;
  int _spawnCursor = 0;

  @override
  Color backgroundColor() => const Color(0xff101820);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder.anchor = Anchor.center;

    await add(
      TextComponent(
        text: 'Joseon Dynasty Survival',
        anchor: Anchor.center,
        position: Vector2(size.x / 2, 32),
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color(0xfff4ead2),
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    await _addActivePlayers();
  }

  @override
  void update(double dt) {
    super.update(dt);

    _elapsedSeconds += dt;
    _spawnTimer += dt;

    if (_spawnTimer >= 3) {
      _spawnTimer = 0;
      _addDebugEnemy();
    }
  }

  Future<void> _addActivePlayers() async {
    final activeSlots = playerSlots.where((slot) => slot.isActive).toList();
    const spacing = 36.0;
    final startX = size.x / 2 - ((activeSlots.length - 1) * spacing / 2);

    for (var i = 0; i < activeSlots.length; i += 1) {
      final slot = activeSlots[i];
      final character = _characterDefinitionFor(slot.characterId);
      final player = PlayerComponent(
        slotIndex: slot.index,
        maxHealth: character.maxHealth,
        moveSpeed: character.moveSpeed,
        position: Vector2(startX + (i * spacing), size.y / 2),
      );

      activePlayers.add(player);
      await add(player);
    }
  }

  void _addDebugEnemy() {
    final enemyIds = SpawnSystem.enemiesForSecond(_elapsedSeconds.floor());
    final enemyId = enemyIds[_spawnCursor % enemyIds.length];
    _spawnCursor += 1;

    final enemyDefinition = _enemyDefinitionFor(enemyId);
    final offset = _spawnOffsetFor(_spawnCursor);
    add(
      EnemyComponent(
        enemyId: enemyDefinition.id,
        maxHealth: enemyDefinition.maxHealth,
        moveSpeed: enemyDefinition.moveSpeed,
        damage: enemyDefinition.damage,
        position: Vector2(size.x / 2, size.y / 2) + offset,
        targetPositionProvider: _nearestActivePlayerPosition,
      ),
    );
  }

  CharacterDefinition _characterDefinitionFor(CharacterId characterId) {
    return characterDefinitions.firstWhere(
      (definition) => definition.id == characterId,
      orElse: () => characterDefinitions.first,
    );
  }

  EnemyDefinition _enemyDefinitionFor(EnemyId enemyId) {
    return enemyDefinitions.firstWhere(
      (definition) => definition.id == enemyId,
      orElse: () => enemyDefinitions.first,
    );
  }

  Vector2? _nearestActivePlayerPosition(Vector2 source) {
    final alivePlayers = activePlayers.where(
      (player) => player.isMounted && player.currentHealth > 0,
    );
    if (alivePlayers.isEmpty) {
      return null;
    }

    PlayerComponent? nearestPlayer;
    var nearestDistance = double.infinity;
    for (final player in alivePlayers) {
      final distance = player.position.distanceToSquared(source);
      if (distance < nearestDistance) {
        nearestPlayer = player;
        nearestDistance = distance;
      }
    }

    return nearestPlayer?.position.clone();
  }

  Vector2 _spawnOffsetFor(int spawnIndex) {
    final side = spawnIndex % 4;
    final halfWidth = size.x / 2;
    final halfHeight = size.y / 2;

    return switch (side) {
      0 => Vector2(-halfWidth - 24, 0),
      1 => Vector2(halfWidth + 24, 0),
      2 => Vector2(0, -halfHeight - 24),
      _ => Vector2(0, halfHeight + 24),
    };
  }
}
