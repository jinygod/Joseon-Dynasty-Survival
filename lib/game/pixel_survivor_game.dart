import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import '../app/game_hud_source.dart';
import 'components/area_attack_component.dart';
import 'audio/audio_cue.dart';
import 'components/boss_component.dart';
import 'components/combat_effect_component.dart';
import 'components/damage_number_component.dart';
import 'components/enemy_component.dart';
import 'components/enemy_hazard_component.dart';
import 'components/experience_gem_component.dart';
import 'components/frost_field_component.dart';
import 'components/player_component.dart';
import 'components/projectile_component.dart';
import 'components/spirit_jade_component.dart';
import 'components/ward_aura_component.dart';
import 'balance/meta_reward_balance.dart';
import 'content/augment_definitions.dart';
import 'content/boss_definitions.dart';
import 'content/character_definitions.dart';
import 'content/combat_effect_atlas.dart';
import 'content/enemy_definitions.dart';
import 'content/ids.dart';
import 'content/playtest_content_policy.dart';
import 'content/stage_definitions.dart';
import 'content/wave_definitions.dart';
import 'content/weapon_definitions.dart';
import 'content/weapon_level_definitions.dart';
import 'content/visual_asset_load_policy.dart';
import 'game_performance_budget.dart';
import 'models/player_slot.dart';
import 'models/damage_event.dart';
import 'models/run_choice_record.dart';
import 'models/run_result.dart';
import 'models/run_outcome.dart';
import 'models/vector_input.dart';
import 'systems/level_up_system.dart';
import 'systems/augment_effect_resolver.dart';
import 'systems/meta_reward_policy.dart';
import 'systems/combat_feedback_tuning.dart';
import 'systems/combat_system.dart';
import 'systems/character_passive_modifiers.dart';
import 'systems/enemy_aura_resolver.dart';
import 'systems/enemy_behavior_controller.dart';
import 'systems/run_progression_system.dart';
import 'systems/run_stats_tracker.dart';
import 'systems/wave_director.dart';
import 'systems/weapon_system.dart';

class PixelSurvivorGame extends FlameGame
    with KeyboardEvents
    implements GameHudSource, RewardCollectionHudSource, VisualAssetLoadPolicy {
  static const levelUpOverlayId = 'levelUp';
  static const maxExperienceGemComponents = 128;

  PixelSurvivorGame({
    required this.playerSlot,
    required this.onRunEnded,
    this.stageId = moonlitAbandonedOffice,
    this.onAudioCue,
    this.persistSpiritJade,
    this.firstBossRewardAvailable = false,
    this.screenShakeEnabled = true,
    this.damageNumbersEnabled = true,
    String? pickupIdPrefix,
    double Function()? rewardRoll,
    double Function()? bossRoll,
    Random? random,
    this.performanceBudget = GamePerformanceBudget.standard,
    this.onPerformanceDiagnostic,
    this.loadVisualAssets = true,
    this.contentPolicy = const PlaytestContentPolicy(
      unlockAllBaseWeapons: false,
    ),
  }) : weaponSystem = WeaponSystem(random: random),
       waveDirector = WaveDirector(
         random: random ?? Random(),
         definitions: waveDefinitionsForStage(stageId),
       ),
       levelUpSystem = LevelUpSystem(random: random),
       pickupIdPrefix =
           pickupIdPrefix ?? DateTime.now().microsecondsSinceEpoch.toString(),
       _rewardRoll = rewardRoll ?? Random().nextDouble,
       _bossRoll = bossRoll ?? random?.nextDouble ?? Random().nextDouble {
    if (!playerSlot.isActive) {
      throw ArgumentError.value(playerSlot, 'playerSlot', 'must be active');
    }

    _addStartingRunUnlocks();
  }

  final PlayerSlot playerSlot;
  final String stageId;
  final void Function(RunResult result)? onRunEnded;
  final void Function(AudioCue cue)? onAudioCue;
  final SpiritJadePersistence? persistSpiritJade;
  bool firstBossRewardAvailable;
  bool screenShakeEnabled;
  bool damageNumbersEnabled;
  final String pickupIdPrefix;
  final double Function() _rewardRoll;
  final double Function() _bossRoll;
  final GamePerformanceBudget performanceBudget;
  final GamePerformanceDiagnosticReporter? onPerformanceDiagnostic;
  @override
  final bool loadVisualAssets;
  final PlaytestContentPolicy contentPolicy;
  final MetaRewardPolicy _metaRewardPolicy = const MetaRewardPolicy();
  final AugmentEffectResolver _augmentEffectResolver =
      const AugmentEffectResolver();
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
  final Map<EnemyComponent, WeaponId> _lastWeaponHitByEnemy = {};
  final Set<EnemyComponent> _recordedEnemyDefeats = {};
  final Map<EnemyComponent, bool> _pendingSpiritJadeDrops = {};
  int _spiritJadeDropSequence = 0;
  double? _rewardCollectionSecondsRemaining;
  int _pendingBossSpiritJade = 0;
  List<LevelUpChoice> _pendingLevelUpChoices = const [];

  VectorInput movementInput = VectorInput.zero;

  double _elapsedSeconds = 0;
  int _bossRequestCount = 0;
  int _bossSpawnCount = 0;
  bool _bossSpawnPending = false;
  int _currentEnemyCap = 24;
  RunOutcome _runOutcome = RunOutcome.inProgress;
  BossComponent? _boss;
  int _damageNumberCount = 0;
  int _combatEffectCount = 0;
  final Map<GamePopulationKind, int> _rejectedPopulations = {};
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
  int get experienceToNextLevel => runProgression.experienceRequiredForLevel(
    runProgression.level,
    multiplier: experienceRequirementMultiplier,
  );
  @override
  int get kills => runStats.kills;
  RunOutcome get runOutcome => _runOutcome;
  bool get isGameOver => _runOutcome != RunOutcome.inProgress;
  bool get canPauseRun =>
      _runOutcome == RunOutcome.inProgress && !isLevelUpPending;
  @override
  double? get rewardCollectionSecondsRemaining =>
      _rewardCollectionSecondsRemaining;
  @override
  bool get isSpiritJadeSaveRetrying =>
      _rewardCollectionSecondsRemaining != null &&
      _rewardCollectionSecondsRemaining! <= 0 &&
      children.whereType<SpiritJadeComponent>().any(
        (jade) => jade.isBossDrop && !jade.isSaving && !jade.canRetry,
      );
  int get bossRequestCount => _bossRequestCount;
  int get bossSpawnCount => _bossSpawnCount;
  int get currentEnemyCap => _currentEnemyCap;
  @override
  String? get bossName => _boss?.displayName;
  String? get bossId => _boss?.enemyId;
  @override
  double? get bossHealthFraction => _boss?.healthFraction;
  Vector2 get screenShakeOffset => _screenShakeOffset.clone();
  GamePerformanceSnapshot get performanceSnapshot => GamePerformanceSnapshot(
    budget: performanceBudget,
    counts: {
      GamePopulationKind.enemy: _enemyComponentCount,
      GamePopulationKind.projectile: _projectileComponentCount,
      GamePopulationKind.damageNumber: _damageNumberCount,
      GamePopulationKind.combatEffect: _combatEffectCount,
    },
    rejected: _rejectedPopulations,
  );

  int get performanceRetainedOwnerCount =>
      _activePlayers.length +
      _lastWeaponHitByEnemy.length +
      _recordedEnemyDefeats.length +
      _pendingSpiritJadeDrops.length;

  void applyAccessibilitySettings({
    required bool screenShakeEnabled,
    required bool damageNumbersEnabled,
  }) {
    this.screenShakeEnabled = screenShakeEnabled;
    this.damageNumbersEnabled = damageNumbersEnabled;
    if (!screenShakeEnabled) _clearScreenShake();
  }

  double get weaponDamageMultiplier =>
      _resolvedAugmentModifiers.weaponDamageMultiplier;

  double get moveSpeedMultiplier =>
      _resolvedAugmentModifiers.moveSpeedMultiplier;

  double get attackSpeedMultiplier =>
      _resolvedAugmentModifiers.attackSpeedMultiplier;

  double get criticalChance {
    return (_resolvedAugmentModifiers.criticalChanceBonus +
            _passiveModifiers.bonusCriticalChance)
        .clamp(0, 1)
        .toDouble();
  }

  double get incomingContactDamageMultiplier =>
      _passiveModifiers.incomingContactDamageMultiplier *
      _resolvedAugmentModifiers.incomingContactDamageMultiplier;

  Map<ElementType, double> get elementDamageMultipliers {
    final multipliers = Map<ElementType, double>.of(
      _resolvedAugmentModifiers.elementDamageMultipliers,
    );
    final passiveMagic = _passiveModifiers.magicDamageMultiplier;
    if (passiveMagic != 1) {
      multipliers[ElementType.magic] =
          (multipliers[ElementType.magic] ?? 1) * passiveMagic;
    }
    return Map.unmodifiable(multipliers);
  }

  double get weaponSizeMultiplier =>
      _resolvedAugmentModifiers.weaponSizeMultiplier;

  double get experienceGainMultiplier =>
      _resolvedAugmentModifiers.experienceGainMultiplier;

  double get experienceRequirementMultiplier =>
      _resolvedAugmentModifiers.experienceRequirementMultiplier;

  double get experiencePickupRadiusBonus =>
      max(-21.0, _resolvedAugmentModifiers.pickupRadiusBonus);

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
      return '무기 레벨 0';
    }
    return labels.first;
  }

  @override
  List<String> get weaponLevelLabels => [
    for (final definition in weaponDefinitions)
      if ((weaponSystem.levels[definition.id] ?? 0) > 0)
        '${definition.name} 레벨 ${weaponSystem.levels[definition.id]}',
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
  void onDispose() {
    processLifecycleEvents();
    while (children.isNotEmpty) {
      removeAll(children.toList(growable: false));
      processLifecycleEvents();
    }
    super.onDispose();
  }

  @override
  void update(double dt) {
    final safeDt = dt.clamp(0, 0.05).toDouble();
    super.update(safeDt);
    _trySpawnPendingBoss();
    _updateScreenShake(safeDt);
    if (_runOutcome != RunOutcome.inProgress || isLevelUpPending) {
      return;
    }

    if (_rewardCollectionSecondsRemaining != null) {
      _updateRewardCollection(safeDt);
      return;
    }

    _advanceTime(safeDt);
    _spawnWaveEnemies(safeDt);
    _updatePlayerMovement(safeDt);
    _updateWeapons(safeDt);
    _applyProjectileHits();
    _resolveAreaAttacks();
    _resolveFrostFields();
    _resolveEnemyActions();
    _resolveEnemyHazards();
    _resolveEnemyAuras();
    _recordNewEnemyDefeats();
    _dropExperienceForDeadEnemies();
    _resolveBossVictoryBeforePlayerDefeat();
    _applyEnemyContactDamage();
    _collectExperienceGems();
    _collectSpiritJade();
  }

  void _advanceTime(double dt) {
    _elapsedSeconds += dt;
  }

  @override
  void updateMovementInput(VectorInput input) {
    movementInput = input;
  }

  bool gainExperience(int amount) {
    final leveledUp = runProgression.addExperience(
      amount,
      gainMultiplier: experienceGainMultiplier,
      requirementMultiplier: experienceRequirementMultiplier,
    );
    if (leveledUp && !isLevelUpPending) {
      _queueLevelUpChoices();
    }

    return leveledUp;
  }

  void applyLevelUpChoice(LevelUpChoice choice) {
    final selectedAugment = choice.type == LevelUpChoiceType.augment
        ? augmentDefinitionFor(choice.id)
        : null;
    if (choice.type == LevelUpChoiceType.augment && selectedAugment == null) {
      return;
    }

    runStats.recordChoice(
      RunChoiceRecord(
        type: switch (choice.type) {
          LevelUpChoiceType.weapon => RunChoiceType.weapon,
          LevelUpChoiceType.augment => RunChoiceType.augment,
        },
        contentId: choice.id,
        selectedAtSeconds: _elapsedSeconds.floor(),
        selectedLevel: choice.nextLevel,
      ),
    );
    switch (choice.type) {
      case LevelUpChoiceType.weapon:
        final weaponId = choice.id;
        unlockedWeaponIds.add(weaponId);
        weaponSystem.upgrade(weaponId, unlockedWeaponIds);
      case LevelUpChoiceType.augment:
        final augmentId = choice.id;
        unlockedAugmentIds.add(augmentId);
        final definition = selectedAugment!;
        final currentLevel = augmentLevels[augmentId] ?? 0;
        if (currentLevel < definition.maxLevel) {
          augmentLevels[augmentId] = currentLevel + 1;
          _applyImmediateAugmentEffects(definition);
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
    _currentEnemyCap = min(wave.maxActiveEnemies, performanceBudget.maxEnemies);
    final initialEnemyCount = enemyCount;
    final admittedCount = performanceBudget.admitCount(
      GamePopulationKind.enemy,
      current: _enemyComponentCount,
      requested: wave.spawnRequests.length,
      secondaryAvailable: _currentEnemyCap - initialEnemyCount,
    );
    for (var index = 0; index < admittedCount; index += 1) {
      final request = wave.spawnRequests[index];
      _addEnemy(request.enemyId, initialEnemyCount + index);
    }
    _rejectPopulation(
      GamePopulationKind.enemy,
      wave.spawnRequests.length - admittedCount,
    );
    if (wave.spawnBoss) {
      _bossRequestCount += 1;
      _emitAudio(AudioCue.bossWarning);
      _emitAudio(AudioCue.bossMusic);
      _requestBossSpawn();
    }
  }

  void _requestBossSpawn() {
    if (_bossSpawnCount > 0) return;
    _bossSpawnPending = true;
    _trySpawnPendingBoss();
  }

  void _trySpawnPendingBoss() {
    if (!_bossSpawnPending || _bossSpawnCount > 0) return;
    if (_enemyComponentCount >= performanceBudget.maxEnemies) {
      final nonBoss = children
          .whereType<EnemyComponent>()
          .where((enemy) => enemy is! BossComponent && !enemy.isRemoving)
          .firstOrNull;
      nonBoss?.removeFromParent();
      if (_enemyComponentCount >= performanceBudget.maxEnemies) return;
    }

    final definition = bossDefinitionForStage(stageId, roll: _bossRoll());
    final boss = BossComponent.fromBossDefinition(
      definition: definition,
      position: Vector2(size.x / 2, -36),
      targetPositionProvider: _nearestActivePlayerPosition,
      nearbyEnemiesProvider: () => children.whereType<EnemyComponent>(),
      onAreaAttack: (attack) => add(attack),
      onSummonEnemiesRequested: _summonBossMinions,
    );
    _bossSpawnPending = false;
    _boss = boss;
    _bossSpawnCount += 1;
    add(boss);
  }

  void _summonBossMinions(List<EnemyId> enemyIds) {
    final availableSlots = max(
      0,
      min(
        _currentEnemyCap - enemyCount,
        performanceBudget.maxEnemies - _enemyComponentCount,
      ),
    );
    final summonCount = min(enemyIds.length, availableSlots);
    for (var index = 0; index < summonCount; index += 1) {
      _addEnemy(enemyIds[index], enemyCount + index);
    }
    _rejectPopulation(GamePopulationKind.enemy, enemyIds.length - summonCount);
  }

  void _addEnemy(EnemyId enemyId, int spawnIndex) {
    final offset = _spawnOffsetFor(spawnIndex);
    add(_createEnemy(enemyId, Vector2(size.x / 2, size.y / 2) + offset));
  }

  EnemyComponent _createEnemy(EnemyId enemyId, Vector2 position) {
    return EnemyComponent.fromDefinition(
      _enemyDefinitionFor(enemyId),
      position: position,
      targetPositionProvider: _nearestActivePlayerPosition,
      nearbyEnemiesProvider: () => children.whereType<EnemyComponent>(),
    );
  }

  void _updateWeapons(double dt) {
    final player = _activePlayers
        .where((player) => player.isMounted)
        .firstOrNull;
    if (player == null) {
      return;
    }
    _ensureWardAura(player);

    final result = weaponSystem.tick(
      dt: dt,
      origin: player.position,
      enemies: children.whereType<EnemyComponent>(),
      damageMultiplier: weaponDamageMultiplier,
      attackSpeedMultiplier: attackSpeedMultiplier,
      criticalChance: criticalChance,
      sizeMultiplier: weaponSizeMultiplier,
      elementDamageMultipliers: elementDamageMultipliers,
      hwandoFallbackDirection: player.preferredAttackDirection,
    );
    if (result.hwandoDirection case final direction?) {
      player.playAttack(direction);
    }
    for (final weaponId in result.firedWeaponIds) {
      _emitAudio(_attackCueFor(weaponId));
    }
    _applyDamageEvents(result.damageEvents);
    var projectileSlots = max(
      0,
      performanceBudget.maxProjectiles - _projectileComponentCount,
    );
    for (final projectile in result.projectiles) {
      if (projectileSlots > 0) {
        add(projectile);
        projectileSlots -= 1;
      } else {
        _rejectPopulation(GamePopulationKind.projectile, 1);
      }
    }
    for (final arc in result.meleeArcs) {
      add(arc);
    }
    for (final areaAttack in result.areaAttacks) {
      add(areaAttack);
    }
    for (final frostField in result.frostFields) {
      final activeFields = children.whereType<FrostFieldComponent>().toList();
      if (activeFields.length >= 3) activeFields.first.removeFromParent();
      add(frostField);
    }
  }

  void _ensureWardAura(PlayerComponent player) {
    final level = weaponSystem.levelOf(jangseungWard);
    if (level == 0 || children.whereType<WardAuraComponent>().isNotEmpty) {
      return;
    }
    add(
      WardAuraComponent(
        positionProvider: () => player.position,
        radiusProvider: () {
          final currentLevel = weaponSystem.levelOf(jangseungWard);
          if (currentLevel == 0) return 0;
          return weaponLevelFor(jangseungWard, currentLevel).range *
              weaponSizeMultiplier;
        },
      ),
    );
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
              final healthBefore = player.currentHealth;
              player.takeDamage(attack.damage, now: _elapsedSeconds);
              _recordPlayerDamage(
                player: player,
                healthBefore: healthBefore,
                sourceId: _boss?.enemyId ?? 'boss_area_attack',
              );
            }
          }
          attack.collectDamageEvents(const <EnemyComponent>[]);
        }
      } else {
        _applyDamageEvents(attack.collectDamageEvents(enemies));
      }
    }
  }

  void _resolveFrostFields() {
    final enemies = children
        .whereType<EnemyComponent>()
        .where((enemy) => !enemy.isDead)
        .toList();
    final fields = children
        .whereType<FrostFieldComponent>()
        .where((field) => !field.isExpired)
        .toList();
    for (final enemy in enemies) {
      var strongestSlow = 0.0;
      for (final field in fields) {
        if (field.containsEnemy(enemy) && field.slowFraction > strongestSlow) {
          strongestSlow = field.slowFraction;
        }
      }
      enemy.setEnvironmentalSlow(strongestSlow);
    }
    for (final field in fields) {
      _applyDamageEvents(field.collectDamageEvents(enemies));
    }
  }

  void _resolveEnemyActions() {
    for (final enemy in children.whereType<EnemyComponent>().where(
      (enemy) => !enemy.isDead,
    )) {
      for (final request in enemy.drainAttackRequests()) {
        switch (request.kind) {
          case EnemyAttackKind.dive:
          case EnemyAttackKind.thrust:
          case EnemyAttackKind.dash:
            final end = request.origin + request.direction * request.range;
            for (final player in _activePlayers.where(
              (player) => player.isAlive,
            )) {
              if (_distanceToSegment(player.position, request.origin, end) <=
                  player.size.x / 2 + enemy.size.x / 2) {
                _damagePlayerFromEnemy(player, enemy, enemy.damage);
              }
            }
            break;
          case EnemyAttackKind.shockwave:
            _addCappedHazard(
              EnemyHazardComponent.shockwave(
                position: request.origin,
                radius: request.range,
                damage: enemy.damage * enemy.behaviorProfile.effectMultiplier,
                sourceId: enemy.enemyId,
              ),
            );
            break;
          case EnemyAttackKind.scream:
            _addCappedHazard(
              EnemyHazardComponent.scream(
                position: request.origin,
                radius: request.range,
                damage: enemy.damage * enemy.behaviorProfile.effectMultiplier,
                sourceId: enemy.enemyId,
              ),
            );
            break;
        }
      }
    }
  }

  void _resolveEnemyHazards() {
    for (final hazard in children.whereType<EnemyHazardComponent>().where(
      (hazard) => !hazard.isExpired,
    )) {
      for (final player in _activePlayers.where((player) => player.isAlive)) {
        final damage = hazard.damageFor(player);
        if (damage <= 0) continue;
        final healthBefore = player.currentHealth;
        if (player.takeDamage(damage, now: _elapsedSeconds)) {
          _recordPlayerDamage(
            player: player,
            healthBefore: healthBefore,
            sourceId: hazard.sourceId,
          );
        }
      }
    }
  }

  void _resolveEnemyAuras() {
    final enemies = children
        .whereType<EnemyComponent>()
        .where((enemy) => !enemy.isDead)
        .toList(growable: false);
    final hasteSources = enemies.where((enemy) => enemy.hasteAuraFraction > 0);
    for (final enemy in enemies.where(
      (enemy) => enemy.rank == EnemyRank.normal,
    )) {
      final fractions = hasteSources
          .where((source) {
            if (identical(source, enemy)) return false;
            final range = source.behaviorProfile.range;
            return source.position.distanceToSquared(enemy.position) <=
                range * range;
          })
          .map((source) => source.hasteAuraFraction);
      enemy.setEnvironmentalHaste(
        const EnemyAuraResolver()
            .resolve(hasteFractions: fractions, slowFractions: const [])
            .hasteFraction,
      );
    }
    final slowSources = enemies.where((enemy) => enemy.slowAuraFraction > 0);
    for (final player in _activePlayers) {
      final fractions = slowSources
          .where((source) {
            final range = source.behaviorProfile.range;
            return source.position.distanceToSquared(player.position) <=
                range * range;
          })
          .map((source) => source.slowAuraFraction);
      player.setEnvironmentalSlow(
        const EnemyAuraResolver()
            .resolve(hasteFractions: const [], slowFractions: fractions)
            .slowFraction,
      );
    }
  }

  void _damagePlayerFromEnemy(
    PlayerComponent player,
    EnemyComponent enemy,
    double damage,
  ) {
    final healthBefore = player.currentHealth;
    if (player.takeDamage(damage, now: _elapsedSeconds)) {
      _recordPlayerDamage(
        player: player,
        healthBefore: healthBefore,
        sourceId: enemy.enemyId,
      );
    }
  }

  static double _distanceToSegment(Vector2 point, Vector2 start, Vector2 end) {
    final segment = end - start;
    if (segment.length2 == 0) return point.distanceTo(start);
    final projection = ((point - start).dot(segment) / segment.length2)
        .clamp(0, 1)
        .toDouble();
    return point.distanceTo(start + segment * projection);
  }

  void _addCappedHazard(EnemyHazardComponent hazard) {
    final candidates = children
        .whereType<EnemyHazardComponent>()
        .where(
          (item) => hazard.kind == EnemyHazardKind.poison
              ? item.kind == EnemyHazardKind.poison
              : item.kind != EnemyHazardKind.poison,
        )
        .toList();
    final cap = hazard.kind == EnemyHazardKind.poison ? 12 : 24;
    if (candidates.length >= cap) candidates.first.removeFromParent();
    add(hazard);
  }

  void _applyDamageEvents(Iterable<DamageEvent> events) {
    for (final event in events) {
      if (event.target.isDead) continue;
      final healthBefore = event.target.currentHealth;
      event.target.takeDamage(event.damage);
      final effectiveDamage = healthBefore - event.target.currentHealth;
      final weaponId = event.weaponId;
      if (weaponId != null && effectiveDamage > 0) {
        runStats.recordWeaponDamage(
          weaponId: weaponId,
          amount: effectiveDamage,
        );
        _lastWeaponHitByEnemy[event.target] = weaponId;
      }
      event.target.registerHit(knockback: event.direction * event.knockback);
      _spawnDamageNumber(event);
      _spawnCombatEffect(
        event.isCritical ? CombatEffectKind.critical : CombatEffectKind.hit,
        event.target.position,
        size: event.isCritical ? 48 : 32,
      );
      if (event.isCritical) _emitAudio(AudioCue.criticalHit);
    }
  }

  void _spawnDamageNumber(DamageEvent event) {
    if (!damageNumbersEnabled) return;
    if (_damageNumberCount >= performanceBudget.maxDamageNumbers) {
      _rejectPopulation(GamePopulationKind.damageNumber, 1);
      return;
    }
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

  void _spawnCombatEffect(
    CombatEffectKind kind,
    Vector2 position, {
    double size = 36,
  }) {
    if (_combatEffectCount >= performanceBudget.maxCombatEffects) {
      _rejectPopulation(GamePopulationKind.combatEffect, 1);
      return;
    }
    _combatEffectCount += 1;
    add(
      CombatEffectComponent(
        kind: kind,
        position: position.clone(),
        size: Vector2.all(size),
        onExpired: () {
          _combatEffectCount = max(0, _combatEffectCount - 1);
        },
      ),
    );
  }

  void _startScreenShake(double magnitude) {
    if (!screenShakeEnabled) return;
    _screenShakeRemaining = CombatFeedbackTuning.screenShakeDurationSeconds;
    _screenShakeMagnitude = magnitude
        .clamp(0, CombatFeedbackTuning.maxScreenShakeMagnitude)
        .toDouble();
  }

  void _updateScreenShake(double dt) {
    camera.viewfinder.position.sub(_screenShakeOffset);
    _screenShakeOffset.setZero();
    if (!screenShakeEnabled) {
      _screenShakeRemaining = 0;
      return;
    }
    if (_screenShakeRemaining <= 0) return;

    _screenShakeRemaining = max(0.0, _screenShakeRemaining - dt);
    if (_screenShakeRemaining <= 0) return;
    _screenShakePhase += dt * 90;
    _screenShakeOffset.setValues(
      sin(_screenShakePhase) * _screenShakeMagnitude,
      cos(_screenShakePhase * 1.3) * _screenShakeMagnitude,
    );
    if (_screenShakeOffset.length >
        CombatFeedbackTuning.maxScreenShakeMagnitude) {
      _screenShakeOffset.normalize();
      _screenShakeOffset.scale(CombatFeedbackTuning.maxScreenShakeMagnitude);
    }
    camera.viewfinder.position.add(_screenShakeOffset);
  }

  void _clearScreenShake() {
    camera.viewfinder.position.sub(_screenShakeOffset);
    _screenShakeOffset.setZero();
    _screenShakeRemaining = 0;
    _screenShakeMagnitude = 0;
  }

  void _dropExperienceForDeadEnemies() {
    final deadEnemies = children.whereType<EnemyComponent>().where(
      (enemy) => enemy.deathVisualComplete,
    );
    for (final enemy in deadEnemies.toList()) {
      _recordEnemyDefeat(enemy);
      _spawnPendingSpiritJade(enemy);
      _recordedEnemyDefeats.remove(enemy);
      _spawnCombatEffect(
        CombatEffectKind.death,
        enemy.position,
        size: enemy is BossComponent ? 72 : 44,
      );
      _addExperienceGem(enemy);
      enemy.removeFromParent();
    }
  }

  void _addExperienceGem(EnemyComponent enemy) {
    final gems = children
        .whereType<ExperienceGemComponent>()
        .where((gem) => !gem.isRemoving)
        .toList(growable: false);
    if (gems.length >= maxExperienceGemComponents) {
      gems.first.absorbExperience(enemy.experienceValue);
      return;
    }
    add(
      ExperienceGemComponent(
        experienceValue: enemy.experienceValue,
        position: enemy.position.clone(),
      ),
    );
  }

  void _recordNewEnemyDefeats() {
    for (final enemy in children.whereType<EnemyComponent>().where(
      (enemy) => enemy.isDead,
    )) {
      if (enemy.consumeDeathZone()) {
        _addCappedHazard(
          EnemyHazardComponent.poison(
            position: enemy.position.clone(),
            damage: enemy.damage * enemy.behaviorProfile.effectMultiplier,
            sourceId: enemy.enemyId,
          ),
        );
      }
      _recordEnemyDefeat(enemy);
    }
  }

  void _recordEnemyDefeat(EnemyComponent enemy) {
    if (!_recordedEnemyDefeats.add(enemy)) return;
    final enemyDefinition = _enemyDefinitionFor(enemy.enemyId);
    runStats.recordEnemyDefeat(
      isBoss: enemyDefinition.isBoss,
      isElite: enemy.isElite,
      weaponId: _lastWeaponHitByEnemy.remove(enemy),
    );
    final firstBossReward = enemyDefinition.isBoss && firstBossRewardAvailable;
    if (persistSpiritJade != null &&
        _metaRewardPolicy.shouldDropSpiritJade(
          isElite: enemy.isElite,
          isBoss: enemyDefinition.isBoss,
          firstBossRewardAvailable: firstBossReward,
          roll: _rewardRoll(),
        )) {
      _pendingSpiritJadeDrops[enemy] = firstBossReward;
    }
    combatSystem.forget(enemy);
    if (!enemyDefinition.isBoss) _emitAudio(AudioCue.enemyDeath);
  }

  void _spawnPendingSpiritJade(EnemyComponent enemy) {
    final claimsFirstBossReward = _pendingSpiritJadeDrops.remove(enemy);
    final persistence = persistSpiritJade;
    if (claimsFirstBossReward == null || persistence == null) return;

    final pickupId =
        '$pickupIdPrefix-${enemy.enemyId}-${(_elapsedSeconds * 1000).round()}-'
        '${_spiritJadeDropSequence++}';
    final isBossDrop = _enemyDefinitionFor(enemy.enemyId).isBoss;
    if (claimsFirstBossReward) firstBossRewardAvailable = false;
    if (isBossDrop) _pendingBossSpiritJade += 1;
    add(
      SpiritJadeComponent(
        pickup: SpiritJadePickup(
          pickupId: pickupId,
          claimsFirstBossReward: claimsFirstBossReward,
        ),
        persistPickup: persistence,
        onCollected: () {
          runStats.recordSpiritJadeCollected();
          if (isBossDrop) _pendingBossSpiritJade -= 1;
        },
        isBossDrop: isBossDrop,
        position: enemy.position.clone(),
      ),
    );
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
        final healthBefore = player.currentHealth;
        combatSystem.applyContactDamage(
          player: player,
          enemy: enemy,
          now: _elapsedSeconds,
          incomingDamageMultiplier: incomingContactDamageMultiplier,
        );
        if (player.currentHealth < healthBefore) {
          _emitAudio(AudioCue.playerHit);
          _recordPlayerDamage(
            player: player,
            healthBefore: healthBefore,
            sourceId: enemy.enemyId,
          );
        }
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
    if (boss != null && boss.isDead) _recordEnemyDefeat(boss);
    if (runStats.bossDefeated) {
      if (boss != null && _pendingSpiritJadeDrops.containsKey(boss)) {
        _spawnPendingSpiritJade(boss);
      }
      if (_pendingBossSpiritJade > 0) {
        _startRewardCollection();
      } else {
        _finishRun(RunOutcome.victory);
      }
    }
  }

  void _startRewardCollection() {
    if (_rewardCollectionSecondsRemaining != null) return;
    _rewardCollectionSecondsRemaining =
        MetaRewardBalance.bossRewardCollectionSeconds;
    for (final component in children.toList()) {
      if (component is EnemyComponent ||
          component is ProjectileComponent ||
          component is AreaAttackComponent) {
        component.removeFromParent();
      }
    }
    _boss = null;
    movementInput = VectorInput.zero;
  }

  void _updateRewardCollection(double dt) {
    _updatePlayerMovement(dt);
    _collectSpiritJade();
    final remaining = _rewardCollectionSecondsRemaining!;
    _rewardCollectionSecondsRemaining = max(0, remaining - dt);
    if (_rewardCollectionSecondsRemaining! > 0) return;

    for (final jade in children.whereType<SpiritJadeComponent>().where(
      (jade) => jade.isBossDrop && jade.canRetry,
    )) {
      unawaited(jade.tryCollect());
    }
    if (_pendingBossSpiritJade == 0) {
      _rewardCollectionSecondsRemaining = null;
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
        _emitAudio(AudioCue.experiencePickup);
        gainExperience(gem.experienceValue);
        gem.removeFromParent();
      }
    }
  }

  void _collectSpiritJade() {
    final alivePlayers = _activePlayers
        .where((player) => player.isMounted && player.isAlive)
        .toList(growable: false);
    if (alivePlayers.isEmpty) return;

    for (final jade in children.whereType<SpiritJadeComponent>().toList()) {
      if (!jade.canRetry) continue;
      final canPickup = alivePlayers.any(
        (player) => jade.canBePickedUpBy(
          player,
          additionalRadius: experiencePickupRadiusBonus,
        ),
      );
      if (canPickup) unawaited(jade.tryCollect());
    }
  }

  void _recordPlayerDamage({
    required PlayerComponent player,
    required double healthBefore,
    required String sourceId,
  }) {
    runStats.recordPlayerDamage(
      amount: healthBefore - player.currentHealth,
      sourceId: sourceId,
      atSeconds: _elapsedSeconds.floor(),
      isLethal: !player.isAlive,
    );
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
      contentPolicy.resolveWeaponIds(
        weaponDefinitions
            .where((definition) => definition.startsUnlocked)
            .map((definition) => definition.id),
      ),
    );
    _addStartingAugments();
  }

  void _queueLevelUpChoices() {
    final choices = levelUpChoices();
    if (choices.isEmpty) {
      return;
    }

    _pendingLevelUpChoices = choices;
    _emitAudio(AudioCue.levelUp);
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

  void _applyImmediateAugmentEffects(AugmentDefinition definition) {
    for (final player in _activePlayers.where((player) => player.isAlive)) {
      for (final effect in definition.effects.where(
        (effect) => effect.application == AugmentEffectApplication.onAcquire,
      )) {
        switch (effect.stat) {
          case AugmentStat.maxHealth:
            player.increaseMaxHealth(effect.valuePerLevel);
          case AugmentStat.healing:
            player.heal(effect.valuePerLevel);
          case AugmentStat.weaponDamage:
          case AugmentStat.fireDamage:
          case AugmentStat.attackSpeed:
          case AugmentStat.criticalChance:
          case AugmentStat.weaponSize:
          case AugmentStat.moveSpeed:
          case AugmentStat.incomingContactDamage:
          case AugmentStat.experienceGain:
          case AugmentStat.pickupRadius:
          case AugmentStat.experienceRequirement:
            break;
        }
      }
    }
  }

  void _finishRun(RunOutcome outcome) {
    if (_runOutcome != RunOutcome.inProgress) {
      return;
    }

    _runOutcome = outcome;
    _emitAudio(
      outcome == RunOutcome.victory
          ? AudioCue.victoryMusic
          : AudioCue.defeatMusic,
    );
    _pendingLevelUpChoices = const [];
    if (isMounted) {
      overlays.remove(levelUpOverlayId);
      pauseEngine();
    }
    onRunEnded?.call(currentRunResult());
  }

  @visibleForTesting
  EnemyComponent debugSpawnEnemy(EnemyId enemyId, {required Vector2 position}) {
    final enemy = _createEnemy(enemyId, position);
    add(enemy);
    return enemy;
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
      _emitAudio(AudioCue.bossWarning);
      _emitAudio(AudioCue.bossMusic);
      _requestBossSpawn();
    }
  }

  @visibleForTesting
  void debugApplyDamageEvent(DamageEvent event) {
    _applyDamageEvents([event]);
  }

  @visibleForTesting
  void debugStartScreenShake(double magnitude) {
    _startScreenShake(magnitude);
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
  void debugDefeatBoss() {
    final boss = _boss;
    if (boss == null) return;
    boss.takeDamage(boss.currentHealth);
    _resolveBossVictoryBeforePlayerDefeat();
  }

  @visibleForTesting
  void debugKillPlayer() {
    for (final player in _activePlayers) {
      player.takeDamage(player.currentHealth);
    }
  }

  void _rejectPopulation(GamePopulationKind kind, int count) {
    if (count <= 0) return;
    final total = (_rejectedPopulations[kind] ?? 0) + count;
    _rejectedPopulations[kind] = total;
    try {
      onPerformanceDiagnostic?.call(
        GamePerformanceDiagnostic(
          kind: kind,
          rejectedCount: count,
          rejectedTotal: total,
          limit: performanceBudget.limitFor(kind),
        ),
      );
    } catch (_) {
      // Diagnostics cannot turn a deliberate population drop into a crash.
    }
  }

  int get _enemyComponentCount => children
      .whereType<EnemyComponent>()
      .where((enemy) => !enemy.isRemoving)
      .length;

  int get _projectileComponentCount => children
      .whereType<ProjectileComponent>()
      .where((projectile) => !projectile.isRemoving)
      .length;

  AudioCue _attackCueFor(WeaponId weaponId) => switch (weaponId) {
    hwandoSlash => AudioCue.hwandoAttack,
    gakgungShot => AudioCue.bowAttack,
    talismanThrow => AudioCue.talismanAttack,
    thunderCrashBomb => AudioCue.bombAttack,
    jangseungWard => AudioCue.talismanAttack,
    singijeonVolley => AudioCue.bowAttack,
    frostFlask => AudioCue.talismanAttack,
    windThunderFan => AudioCue.bombAttack,
    _ => AudioCue.hwandoAttack,
  };

  void _emitAudio(AudioCue cue) => onAudioCue?.call(cue);

  CharacterDefinition _characterDefinitionFor(CharacterId characterId) {
    return characterDefinitions.firstWhere(
      (definition) => definition.id == characterId,
      orElse: () => characterDefinitions.first,
    );
  }

  CharacterPassiveModifiers get _passiveModifiers =>
      CharacterPassiveModifiers.forPassive(
        _characterDefinitionFor(playerSlot.characterId).passive,
      );

  AugmentModifiers get _resolvedAugmentModifiers {
    final player = _activePlayers
        .where((player) => player.isMounted && player.isAlive)
        .firstOrNull;
    return _augmentEffectResolver.resolve(
      levels: augmentLevels,
      healthFraction: player?.healthFraction ?? 1,
    );
  }

  EnemyDefinition _enemyDefinitionFor(EnemyId enemyId) {
    final boss = bossDefinitionForId(enemyId);
    if (boss != null) return boss.enemy;
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
