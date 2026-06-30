import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import 'components/enemy_component.dart';
import 'components/experience_gem_component.dart';
import 'components/player_component.dart';
import 'components/projectile_component.dart';
import 'content/augment_definitions.dart';
import 'content/character_definitions.dart';
import 'content/enemy_definitions.dart';
import 'content/ids.dart';
import 'content/weapon_definitions.dart';
import 'models/player_slot.dart';
import 'models/run_result.dart';
import 'models/vector_input.dart';
import 'systems/level_up_system.dart';
import 'systems/run_progression_system.dart';
import 'systems/run_stats_tracker.dart';
import 'systems/spawn_system.dart';
import 'systems/weapon_system.dart';

class PixelSurvivorGame extends FlameGame with KeyboardEvents {
  static const levelUpOverlayId = 'levelUp';

  PixelSurvivorGame({
    required List<PlayerSlot> playerSlots,
    this.onRunEnded,
  }) : playerSlots = List.unmodifiable(playerSlots) {
    if (this.playerSlots.isEmpty) {
      throw ArgumentError.value(
        playerSlots,
        'playerSlots',
        'must not be empty',
      );
    }

    _addStartingRunUnlocks();
  }

  final List<PlayerSlot> playerSlots;
  final void Function(RunResult result)? onRunEnded;
  final SpawnSystem spawnSystem = const SpawnSystem();
  final WeaponSystem weaponSystem = WeaponSystem();
  final LevelUpSystem levelUpSystem = const LevelUpSystem();
  final RunProgressionSystem runProgression = RunProgressionSystem();
  final RunStatsTracker runStats = RunStatsTracker();
  final List<PlayerComponent> activePlayers = [];
  final Set<WeaponId> unlockedWeaponIds = {};
  final Set<AugmentId> unlockedAugmentIds = {};
  final Map<AugmentId, int> augmentLevels = {};
  List<LevelUpChoice> _pendingLevelUpChoices = const [];

  VectorInput movementInput = VectorInput.zero;

  double _elapsedSeconds = 0;
  double _spawnTimer = 0;
  int _spawnCursor = 0;
  bool _isGameOver = false;

  double get elapsedSeconds => _elapsedSeconds;
  int get playerLevel => runProgression.level;
  int get currentExperience => runProgression.currentExperience;
  int get experienceToNextLevel => runProgression.experienceToNextLevel;
  int get kills => runStats.kills;
  bool get isGameOver => _isGameOver;
  bool get isLevelUpPending => _pendingLevelUpChoices.isNotEmpty;
  List<LevelUpChoice> get pendingLevelUpChoices =>
      List.unmodifiable(_pendingLevelUpChoices);
  String get playerHealthLabel {
    final player = activePlayers.where((player) => player.isMounted).firstOrNull;
    if (player == null) {
      return '--';
    }

    return '${player.currentHealth.ceil()}/${player.maxHealth.ceil()}';
  }

  int get enemyCount => children
      .whereType<EnemyComponent>()
      .where((enemy) => !enemy.isDead)
      .length;

  String get currentWeaponLabel {
    if (weaponSystem.levels.isEmpty) {
      return 'Weapon Lv 0';
    }

    final entry = weaponSystem.levels.entries.first;
    final definition = weaponDefinitions.firstWhere(
      (definition) => definition.id == entry.key,
      orElse: () => weaponDefinitions.first,
    );
    return '${definition.name} Lv ${entry.value}';
  }

  @override
  Color backgroundColor() => const Color(0xff101820);

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    movementInput = _movementInputFromKeys(keysPressed);
    return KeyEventResult.handled;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder.anchor = Anchor.center;

    await _addActivePlayers();
    _addStartingAugments();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isGameOver) {
      return;
    }

    _elapsedSeconds += dt;
    _spawnTimer += dt;

    _updatePlayerMovement(dt);
    _applyEnemyContactDamage(dt);

    if (_spawnTimer >= 3) {
      _spawnTimer = 0;
      _addDebugEnemy();
    }

    _updateWeapons(dt);
    _applyProjectileHits();
    _dropExperienceForDeadEnemies();
    _collectExperienceGems();
  }

  void updateMovementInput(VectorInput input) {
    movementInput = input;
  }

  bool gainExperience(int amount) {
    final leveledUp = runProgression.addExperience(amount);
    if (leveledUp && !isLevelUpPending) {
      _queueLevelUpChoices();
    }

    return leveledUp;
  }

  void applyLevelUpChoice(LevelUpChoice choice) {
    switch (choice.type) {
      case LevelUpChoiceType.weapon:
        final weaponId = choice.id;
        unlockedWeaponIds.add(weaponId);
        weaponSystem.upgrade(weaponId, unlockedWeaponIds);
      case LevelUpChoiceType.augment:
        final augmentId = choice.id;
        unlockedAugmentIds.add(augmentId);
        final definition = augmentDefinitions.firstWhere(
          (definition) => definition.id == augmentId,
          orElse: () => augmentDefinitions.first,
        );
        final currentLevel = augmentLevels[augmentId] ?? 0;
        if (currentLevel < definition.maxLevel) {
          augmentLevels[augmentId] = currentLevel + 1;
        }
        _applyAugmentEffects();
    }

    _pendingLevelUpChoices = const [];
    if (isMounted) {
      overlays.remove(levelUpOverlayId);
      resumeEngine();
    }
  }

  RunResult currentRunResult() {
    return runStats.toRunResult(
      survivalSeconds: _elapsedSeconds.floor(),
      level: playerLevel,
      wonWithLowHealth: false,
    );
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

      unlockedWeaponIds.add(character.startingWeaponId);
      if (weaponSystem.levelOf(character.startingWeaponId) == 0) {
        weaponSystem.upgrade(character.startingWeaponId, unlockedWeaponIds);
      }

      activePlayers.add(player);
      await add(player);
    }
    _applyAugmentEffects();
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
        experienceValue: enemyDefinition.experience,
        position: Vector2(size.x / 2, size.y / 2) + offset,
        targetPositionProvider: _nearestActivePlayerPosition,
      ),
    );
  }

  void _updateWeapons(double dt) {
    final player = activePlayers
        .where((player) => player.isMounted)
        .firstOrNull;
    if (player == null) {
      return;
    }

    final result = weaponSystem.tick(
      dt: dt,
      origin: player.position,
      enemies: children.whereType<EnemyComponent>(),
      damageMultiplier: _weaponDamageMultiplier,
    );
    for (final projectile in result.projectiles) {
      add(projectile);
    }
  }

  void _updatePlayerMovement(double dt) {
    for (final player in activePlayers.where((player) => player.isMounted)) {
      player.applyInput(movementInput, dt, bounds: size);
    }
  }

  void _applyProjectileHits() {
    final enemies = children
        .whereType<EnemyComponent>()
        .where((enemy) => !enemy.isDead)
        .toList(growable: false);
    if (enemies.isEmpty) {
      return;
    }

    final projectiles = children.whereType<ProjectileComponent>().toList();
    for (final projectile in projectiles) {
      if (projectile.isExpired || _isProjectileOutsideBounds(projectile)) {
        projectile.removeFromParent();
        continue;
      }

      for (final enemy in enemies) {
        if (!enemy.isDead && projectile.overlapsEnemy(enemy)) {
          enemy.takeDamage(projectile.damage);
          projectile.removeFromParent();
          break;
        }
      }
    }
  }

  void _dropExperienceForDeadEnemies() {
    final deadEnemies = children.whereType<EnemyComponent>().where(
      (enemy) => enemy.isDead,
    );
    for (final enemy in deadEnemies.toList()) {
      final enemyDefinition = _enemyDefinitionFor(enemy.enemyId);
      runStats.recordEnemyDefeat(isBoss: enemyDefinition.isBoss);
      add(
        ExperienceGemComponent(
          experienceValue: enemy.experienceValue,
          position: enemy.position.clone(),
        ),
      );
      enemy.removeFromParent();
    }
  }

  void _applyEnemyContactDamage(double dt) {
    final alivePlayers = activePlayers
        .where((player) => player.isMounted && player.isAlive)
        .toList(growable: false);
    if (alivePlayers.isEmpty) {
      _finishRun();
      return;
    }

    final enemies = children
        .whereType<EnemyComponent>()
        .where((enemy) => !enemy.isDead)
        .toList(growable: false);
    for (final enemy in enemies) {
      for (final player in alivePlayers) {
        if (enemy.overlapsPlayer(player)) {
          player.takeDamage(enemy.damage * dt);
        }
      }
    }

    final hasAlivePlayer = activePlayers.any(
      (player) => player.isMounted && player.isAlive,
    );
    if (!hasAlivePlayer) {
      _finishRun();
    }
  }

  void _collectExperienceGems() {
    final alivePlayers = activePlayers
        .where((player) => player.isMounted && player.currentHealth > 0)
        .toList(growable: false);
    if (alivePlayers.isEmpty) {
      return;
    }

    final gems = children.whereType<ExperienceGemComponent>().toList();
    for (final gem in gems) {
      final canPickup = alivePlayers.any(gem.canBePickedUpBy);
      if (canPickup) {
        gainExperience(gem.experienceValue);
        gem.removeFromParent();
      }
    }
  }

  List<LevelUpChoice> levelUpChoices() {
    return levelUpSystem.choices(
      unlockedWeaponIds: unlockedWeaponIds,
      unlockedAugmentIds: unlockedAugmentIds,
      currentWeaponLevels: weaponSystem.levels,
      currentAugmentLevels: augmentLevels,
    );
  }

  void _addStartingAugments() {
    unlockedAugmentIds.addAll(
      augmentDefinitions
          .where((definition) => definition.startsUnlocked)
      .map((definition) => definition.id),
    );
  }

  void _addStartingRunUnlocks() {
    unlockedWeaponIds.addAll(
      weaponDefinitions
          .where((definition) => definition.startsUnlocked)
          .map((definition) => definition.id),
    );
    _addStartingAugments();
  }

  void _queueLevelUpChoices() {
    final choices = levelUpChoices();
    if (choices.isEmpty) {
      return;
    }

    _pendingLevelUpChoices = choices;
    if (isMounted) {
      pauseEngine();
      overlays.add(levelUpOverlayId);
    }
  }

  void _applyAugmentEffects() {
    final speedMultiplier = _moveSpeedMultiplier;
    for (final player in activePlayers) {
      player.moveSpeedMultiplier = speedMultiplier;
    }
  }

  double get _weaponDamageMultiplier {
    final martialTrainingLevel = augmentLevels[martialTraining] ?? 0;
    final heavyStrikeLevel = augmentLevels[heavyStrike] ?? 0;
    return 1 + (martialTrainingLevel * 0.12) + (heavyStrikeLevel * 0.18);
  }

  double get _moveSpeedMultiplier {
    final quickStepLevel = augmentLevels[quickStep] ?? 0;
    return 1 + (quickStepLevel * 0.08);
  }

  void _finishRun() {
    if (_isGameOver) {
      return;
    }

    _isGameOver = true;
    _pendingLevelUpChoices = const [];
    if (isMounted) {
      overlays.remove(levelUpOverlayId);
      pauseEngine();
    }
    onRunEnded?.call(currentRunResult());
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

  bool _isProjectileOutsideBounds(ProjectileComponent projectile) {
    const margin = 64.0;
    return projectile.position.x < -margin ||
        projectile.position.y < -margin ||
        projectile.position.x > size.x + margin ||
        projectile.position.y > size.y + margin;
  }

  VectorInput _movementInputFromKeys(Set<LogicalKeyboardKey> keysPressed) {
    var x = 0.0;
    var y = 0.0;

    if (keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      x -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      x += 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyW) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      y -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyS) ||
        keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      y += 1;
    }

    return VectorInput(x, y);
  }
}
