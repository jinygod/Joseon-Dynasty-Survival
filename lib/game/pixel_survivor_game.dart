import 'dart:collection';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import '../app/game_hud_source.dart';
import 'components/enemy_component.dart';
import 'components/area_attack_component.dart';
import 'components/boss_component.dart';
import 'components/damage_number_component.dart';
import 'components/experience_gem_component.dart';
import 'components/player_component.dart';
import 'components/projectile_component.dart';
import 'content/augment_definitions.dart';
import 'content/character_definitions.dart';
import 'content/enemy_definitions.dart';
import 'content/ids.dart';
import 'content/weapon_definitions.dart';
import 'models/player_slot.dart';
import 'models/damage_event.dart';
import 'models/run_result.dart';
import 'models/run_outcome.dart';
import 'models/vector_input.dart';
import 'systems/level_up_system.dart';
import 'systems/combat_system.dart';
import 'systems/run_progression_system.dart';
import 'systems/run_stats_tracker.dart';
import 'systems/wave_director.dart';
import 'systems/weapon_system.dart';

class PixelSurvivorGame extends FlameGame
    with KeyboardEvents
    implements GameHudSource {
  static const levelUpOverlayId = 'levelUp';

  PixelSurvivorGame({
    required this.playerSlot,
    required this.onRunEnded,
    Random? random,
  }) : weaponSystem = WeaponSystem(random: random),
       waveDirector = WaveDirector(random: random ?? Random()),
       levelUpSystem = LevelUpSystem(random: random) {
    if (!playerSlot.isActive) {
      throw ArgumentError.value(playerSlot, 'playerSlot', 'must be active');
    }

    _addStartingRunUnlocks();
  }

  final PlayerSlot playerSlot;
  final void Function(RunResult result)? onRunEnded;
  final WeaponSystem weaponSystem;
  final WaveDirector waveDirector;
  final LevelUpSystem levelUpSystem;
  final RunProgressionSystem runProgression = RunProgressionSystem();
  final RunStatsTracker runStats = RunStatsTracker();
  final CombatSystem combatSystem = CombatSystem();
  final List<PlayerComponent> _activePlayers = [];
  late final List<PlayerComponent> _activePlayersView = UnmodifiableListView(
    _activePlayers,
  );
  final Set<WeaponId> unlockedWeaponIds = {};
  final Set<AugmentId> unlockedAugmentIds = {};
  final Map<AugmentId, int> augmentLevels = {};
  List<LevelUpChoice> _pendingLevelUpChoices = const [];

  VectorInput movementInput = VectorInput.zero;

  double _elapsedSeconds = 0;
  int _bossRequestCount = 0;
  int _bossSpawnCount = 0;
  int _currentEnemyCap = 24;
  RunOutcome _runOutcome = RunOutcome.inProgress;
  BossComponent? _boss;
  int _damageNumberCount = 0;
  double _screenShakeRemaining = 0;
  double _screenShakeMagnitude = 0;
  double _screenShakePhase = 0;
  final Vector2 _screenShakeOffset = Vector2.zero();

  @override
  double get elapsedSeconds => _elapsedSeconds;
  @override
  int get playerLevel => runProgression.level;
  @override
  int get currentExperience => runProgression.currentExperience;
  @override
  int get experienceToNextLevel => runProgression.experienceToNextLevel;
  @override
  int get kills => runStats.kills;
  RunOutcome get runOutcome => _runOutcome;
  bool get isGameOver => _runOutcome != RunOutcome.inProgress;
  int get bossRequestCount => _bossRequestCount;
  int get bossSpawnCount => _bossSpawnCount;
  int get currentEnemyCap => _currentEnemyCap;
  @override
  String? get bossName => _boss?.displayName;
  @override
  double? get bossHealthFraction => _boss?.healthFraction;
  Vector2 get screenShakeOffset => _screenShakeOffset.clone();
  double get weaponDamageMultiplier {
    final martialTrainingLevel = augmentLevels[martialTraining] ?? 0;
    final heavyStrikeLevel = augmentLevels[heavyStrike] ?? 0;
    return 1 + (martialTrainingLevel * 0.12) + (heavyStrikeLevel * 0.18);
  }

  double get moveSpeedMultiplier {
    final quickStepLevel = augmentLevels[quickStep] ?? 0;
    return 1 + (quickStepLevel * 0.08);
  }

  double get attackSpeedMultiplier {
    final rapidReloadLevel = augmentLevels[rapidReload] ?? 0;
    return 1 + (rapidReloadLevel * 0.10);
  }

  double get criticalChance {
    final hawkEyeLevel = augmentLevels[hawkEye] ?? 0;
    return (hawkEyeLevel * 0.05).clamp(0, 1).toDouble();
  }

  double get weaponSizeMultiplier {
    final powderMasteryLevel = augmentLevels[powderMastery] ?? 0;
    return 1 + (powderMasteryLevel * 0.10);
  }

  double get experiencePickupRadiusBonus {
    final blessingLevel = augmentLevels[jangseungBlessing] ?? 0;
    return blessingLevel * 16.0;
  }

  bool get isLevelUpPending => _pendingLevelUpChoices.isNotEmpty;
  List<PlayerComponent> get activePlayers => _activePlayersView;
  List<LevelUpChoice> get pendingLevelUpChoices =>
      List.unmodifiable(_pendingLevelUpChoices);
  @override
  String get playerHealthLabel {
    final player = _activePlayers
        .where((player) => player.isMounted)
        .firstOrNull;
    if (player == null) {
      return '--';
    }

    return '${player.currentHealth.ceil()}/${player.maxHealth.ceil()}';
  }

  @override
  int get enemyCount => children
      .whereType<EnemyComponent>()
      .where((enemy) => !enemy.isDead)
      .length;

  String get currentWeaponLabel {
    final labels = weaponLevelLabels;
    if (labels.isEmpty) {
      return 'Weapon Lv 0';
    }
    return labels.first;
  }

  @override
  List<String> get weaponLevelLabels => [
    for (final definition in weaponDefinitions)
      if ((weaponSystem.levels[definition.id] ?? 0) > 0)
        '${definition.name} Lv ${weaponSystem.levels[definition.id]}',
  ];

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
    final safeDt = dt.clamp(0, 0.05).toDouble();
    super.update(safeDt);
    _updateScreenShake(safeDt);
    if (_runOutcome != RunOutcome.inProgress || isLevelUpPending) {
      return;
    }

    _advanceTime(safeDt);
    _spawnWaveEnemies(safeDt);
    _updatePlayerMovement(safeDt);
    _updateWeapons(safeDt);
    _applyProjectileHits();
    _resolveAreaAttacks();
    _dropExperienceForDeadEnemies();
    _resolveBossVictoryBeforePlayerDefeat();
    _applyEnemyContactDamage();
    _collectExperienceGems();
  }

  void _advanceTime(double dt) {
    _elapsedSeconds += dt;
  }

  @override
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
          _applyImmediateAugmentEffect(augmentId);
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
      outcome: _runOutcome,
      survivalSeconds: _elapsedSeconds.floor(),
      level: playerLevel,
      wonWithLowHealth:
          _runOutcome == RunOutcome.victory &&
          (_activePlayers.firstOrNull?.healthFraction ?? 1) <= 0.2,
      weaponLevels: weaponSystem.levels,
    );
  }

  Future<void> _addActivePlayers() async {
    final character = _characterDefinitionFor(playerSlot.characterId);
    final player = PlayerComponent(
      slotIndex: playerSlot.index,
      maxHealth: character.maxHealth,
      moveSpeed: character.moveSpeed,
      position: Vector2(size.x / 2, size.y / 2),
    );

    unlockedWeaponIds.add(character.startingWeaponId);
    if (weaponSystem.levelOf(character.startingWeaponId) == 0) {
      weaponSystem.upgrade(character.startingWeaponId, unlockedWeaponIds);
    }

    _activePlayers.add(player);
    await add(player);
    _applyAugmentEffects();
  }

  void _spawnWaveEnemies(double dt) {
    final wave = waveDirector.tick(
      elapsedSeconds: _elapsedSeconds,
      dt: dt,
      activeEnemyCount: enemyCount,
    );
    _currentEnemyCap = wave.maxActiveEnemies;
    final initialEnemyCount = enemyCount;
    for (var index = 0; index < wave.spawnRequests.length; index += 1) {
      final request = wave.spawnRequests[index];
      _addEnemy(
        request.enemyId,
        initialEnemyCount + index,
        isElite: request.isElite,
      );
    }
    if (wave.spawnBoss) {
      _bossRequestCount += 1;
      _spawnBoss();
    }
  }

  void _spawnBoss() {
    if (_bossSpawnCount > 0) return;

    final definition = _enemyDefinitionFor(fallenGeneral);
    final boss = BossComponent(
      definition: definition,
      position: Vector2(size.x / 2, -36),
      targetPositionProvider: _nearestActivePlayerPosition,
      nearbyEnemiesProvider: () => children.whereType<EnemyComponent>(),
      onAreaAttack: (attack) => add(attack),
      onSummonRequested: _summonBossMinions,
    );
    _boss = boss;
    _bossSpawnCount += 1;
    add(boss);
  }

  void _summonBossMinions() {
    final availableSlots = max(0, _currentEnemyCap - enemyCount);
    final summonCount = min(3, availableSlots);
    for (var index = 0; index < summonCount; index += 1) {
      _addEnemy(vengefulSpirit, enemyCount + index);
    }
  }

  void _addEnemy(EnemyId enemyId, int spawnIndex, {bool isElite = false}) {
    final enemyDefinition = _enemyDefinitionFor(enemyId);
    final offset = _spawnOffsetFor(spawnIndex);
    add(
      EnemyComponent.fromDefinition(
        enemyDefinition,
        isElite: isElite,
        position: Vector2(size.x / 2, size.y / 2) + offset,
        targetPositionProvider: _nearestActivePlayerPosition,
        nearbyEnemiesProvider: () => children.whereType<EnemyComponent>(),
      ),
    );
  }

  void _updateWeapons(double dt) {
    final player = _activePlayers
        .where((player) => player.isMounted)
        .firstOrNull;
    if (player == null) {
      return;
    }

    final result = weaponSystem.tick(
      dt: dt,
      origin: player.position,
      enemies: children.whereType<EnemyComponent>(),
      damageMultiplier: weaponDamageMultiplier,
      attackSpeedMultiplier: attackSpeedMultiplier,
      criticalChance: criticalChance,
      sizeMultiplier: weaponSizeMultiplier,
    );
    _applyDamageEvents(result.damageEvents);
    for (final projectile in result.projectiles) {
      add(projectile);
    }
    for (final arc in result.meleeArcs) {
      add(arc);
    }
    for (final areaAttack in result.areaAttacks) {
      add(areaAttack);
    }
  }

  void _updatePlayerMovement(double dt) {
    for (final player in _activePlayers.where((player) => player.isMounted)) {
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
        if (!enemy.isDead &&
            projectile.overlapsEnemy(enemy) &&
            projectile.registerHit(enemy)) {
          final direction = enemy.position - projectile.position;
          if (direction.length2 > 0) direction.normalize();
          _applyDamageEvents([
            DamageEvent(
              target: enemy,
              damage: projectile.damage,
              knockback: projectile.knockback,
              direction: direction,
              weaponId: projectile.weaponId,
            ),
          ]);
          if (projectile.isSpent) {
            projectile.removeFromParent();
            break;
          }
        }
      }
    }
  }

  void _resolveAreaAttacks() {
    final enemies = children.whereType<EnemyComponent>();
    for (final attack in children.whereType<AreaAttackComponent>().toList()) {
      if (attack.isReady &&
          !attack.hasTriggered &&
          (attack.isBossAttack || attack.weaponId == thunderCrashBomb)) {
        _startScreenShake(attack.isBossAttack ? 4 : 3);
      }
      if (attack.isBossAttack) {
        if (attack.isReady && !attack.hasTriggered) {
          for (final player in _activePlayers.where(
            (player) => player.isAlive,
          )) {
            if (attack.containsPlayer(player)) {
              player.takeDamage(attack.damage);
            }
          }
          attack.collectDamageEvents(const <EnemyComponent>[]);
        }
      } else {
        _applyDamageEvents(attack.collectDamageEvents(enemies));
      }
    }
  }

  void _applyDamageEvents(Iterable<DamageEvent> events) {
    for (final event in events) {
      if (event.target.isDead) continue;
      event.target.takeDamage(event.damage);
      event.target.registerHit(knockback: event.direction * event.knockback);
      _spawnDamageNumber(event);
    }
  }

  void _spawnDamageNumber(DamageEvent event) {
    if (_damageNumberCount >= 40) return;
    _damageNumberCount += 1;
    add(
      DamageNumberComponent(
        damage: event.damage,
        isCritical: event.isCritical,
        position: event.target.position.clone(),
        onExpired: () {
          _damageNumberCount = max(0, _damageNumberCount - 1);
        },
      ),
    );
  }

  void _startScreenShake(double magnitude) {
    _screenShakeRemaining = 0.12;
    _screenShakeMagnitude = magnitude.clamp(0, 4).toDouble();
  }

  void _updateScreenShake(double dt) {
    camera.viewfinder.position.sub(_screenShakeOffset);
    _screenShakeOffset.setZero();
    if (_screenShakeRemaining <= 0) return;

    _screenShakeRemaining = max(0.0, _screenShakeRemaining - dt);
    if (_screenShakeRemaining <= 0) return;
    _screenShakePhase += dt * 90;
    _screenShakeOffset.setValues(
      sin(_screenShakePhase) * _screenShakeMagnitude,
      cos(_screenShakePhase * 1.3) * _screenShakeMagnitude,
    );
    if (_screenShakeOffset.length > 4) {
      _screenShakeOffset.normalize();
      _screenShakeOffset.scale(4);
    }
    camera.viewfinder.position.add(_screenShakeOffset);
  }

  void _dropExperienceForDeadEnemies() {
    final deadEnemies = children.whereType<EnemyComponent>().where(
      (enemy) => enemy.isDead,
    );
    for (final enemy in deadEnemies.toList()) {
      final enemyDefinition = _enemyDefinitionFor(enemy.enemyId);
      runStats.recordEnemyDefeat(isBoss: enemyDefinition.isBoss);
      combatSystem.forget(enemy);
      add(
        ExperienceGemComponent(
          experienceValue: enemy.experienceValue,
          position: enemy.position.clone(),
        ),
      );
      enemy.removeFromParent();
    }
  }

  void _applyEnemyContactDamage() {
    if (_runOutcome != RunOutcome.inProgress) return;

    final alivePlayers = _activePlayers
        .where((player) => player.isMounted && player.isAlive)
        .toList(growable: false);
    if (alivePlayers.isEmpty) {
      _finishRun(RunOutcome.defeat);
      return;
    }

    final enemies = children
        .whereType<EnemyComponent>()
        .where((enemy) => !enemy.isDead)
        .toList(growable: false);
    for (final enemy in enemies) {
      for (final player in alivePlayers) {
        combatSystem.applyContactDamage(
          player: player,
          enemy: enemy,
          now: _elapsedSeconds,
        );
      }
    }

    final hasAlivePlayer = _activePlayers.any(
      (player) => player.isMounted && player.isAlive,
    );
    if (!hasAlivePlayer) {
      _finishRun(RunOutcome.defeat);
    }
  }

  void _resolveBossVictoryBeforePlayerDefeat() {
    final boss = _boss;
    if (boss != null && boss.isDead && !runStats.bossDefeated) {
      runStats.recordEnemyDefeat(isBoss: true);
    }
    if (runStats.bossDefeated) {
      _finishRun(RunOutcome.victory);
    }
  }

  void _collectExperienceGems() {
    final alivePlayers = _activePlayers
        .where((player) => player.isMounted && player.currentHealth > 0)
        .toList(growable: false);
    if (alivePlayers.isEmpty) {
      return;
    }

    final gems = children.whereType<ExperienceGemComponent>().toList();
    for (final gem in gems) {
      final canPickup = alivePlayers.any(
        (player) => gem.canBePickedUpBy(
          player,
          additionalRadius: experiencePickupRadiusBonus,
        ),
      );
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
    for (final player in _activePlayers) {
      player.moveSpeedMultiplier = moveSpeedMultiplier;
    }
  }

  void _applyImmediateAugmentEffect(AugmentId augmentId) {
    for (final player in _activePlayers.where((player) => player.isAlive)) {
      switch (augmentId) {
        case innerBreath:
          player.increaseMaxHealth(10, healAmount: 10);
        case herbalTonic:
          player.heal(12);
      }
    }
  }

  void _finishRun(RunOutcome outcome) {
    if (_runOutcome != RunOutcome.inProgress) {
      return;
    }

    _runOutcome = outcome;
    _pendingLevelUpChoices = const [];
    if (isMounted) {
      overlays.remove(levelUpOverlayId);
      pauseEngine();
    }
    onRunEnded?.call(currentRunResult());
  }

  @visibleForTesting
  void debugAdvanceTo(double elapsedSeconds) {
    if (_runOutcome != RunOutcome.inProgress ||
        elapsedSeconds < _elapsedSeconds) {
      return;
    }

    _elapsedSeconds = elapsedSeconds;
    final wave = waveDirector.tick(
      elapsedSeconds: _elapsedSeconds,
      dt: 0,
      activeEnemyCount: enemyCount,
    );
    _currentEnemyCap = wave.maxActiveEnemies;
    if (wave.spawnBoss) {
      _bossRequestCount += 1;
      _spawnBoss();
    }
  }

  @visibleForTesting
  void debugDefeatBossAndPlayerSameFrame() {
    final boss = _boss;
    if (boss == null) return;
    boss.takeDamage(boss.currentHealth);
    for (final player in _activePlayers) {
      player.takeDamage(player.currentHealth);
    }
    _resolveBossVictoryBeforePlayerDefeat();
    _applyEnemyContactDamage();
  }

  @visibleForTesting
  void debugKillPlayer() {
    for (final player in _activePlayers) {
      player.takeDamage(player.currentHealth);
    }
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
    final alivePlayers = _activePlayers.where(
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
