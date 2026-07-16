# Enemy and Elite Roster Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 출시용 일반 적 8종과 고유 엘리트 3종을 데이터 기반 행동, 명확한 경고, 안전한 생성·효과 상한, 기존 보상 호환까지 포함해 구현한다.

**Architecture:** 기존 `EnemyDefinition`에 진영·등급·행동 프로필 참조를 추가하고, 수치가 담긴 중앙 프로필과 순수 Dart 상태 머신을 분리한다. `EnemyComponent`는 이동과 경고 상태를 표현하고 공격 요청을 내보내며, `PixelSurvivorGame`은 플레이어 피해·독장판·오라·보상처럼 월드 소유 상태를 처리한다. `WaveDirector`는 일반 풀과 고유 엘리트 풀을 별도로 선택한다.

**Tech Stack:** Dart 3, Flutter, Flame, `flutter_test`, 기존 고정 시드 회귀 시뮬레이터

## Global Constraints

- 일반 적은 정확히 8종, `EnemyRank.elite`인 고유 엘리트는 정확히 3종이어야 한다.
- 보스는 `EnemyRank.boss`로 유지하고 일반·엘리트 웨이브 풀에서 제외한다.
- 적 원거리 투사체를 추가하지 않는다.
- 돌진·찌르기·충격파·비명은 경고 후 방향 또는 범위를 고정해야 한다.
- 같은 유형의 감속·가속 오라는 중첩하지 않고 가장 강한 값 하나만 적용한다.
- 프레임당 생성 요청 상한은 8, 독장판 동시 상한은 12, 공격 경고·파동 동시 상한은 24로 고정한다.
- 새 스프라이트가 없을 때 `SafeAssetLoader` 및 기존 도형 폴백으로 정상 플레이되어야 한다.
- 기존 저장 스키마, `eliteKills`, 엽전 보상, 혼옥 드롭 정책을 유지한다.
- 정확한 두 번째 스테이지 웨이브 구성은 이 계획에 포함하지 않는다.

---

### Task 1: Typed Enemy Roster and Behavior Profiles

**Files:**
- Modify: `lib/game/content/ids.dart`
- Create: `lib/game/content/enemy_behavior_definitions.dart`
- Modify: `lib/game/content/enemy_definitions.dart`
- Modify: `test/game/content_definitions_test.dart`
- Create: `test/game/enemy_behavior_definitions_test.dart`

**Interfaces:**
- Consumes: 기존 `EnemyId = String`, `EnemyBehaviorType`, `EnemyDefinition` 생성자.
- Produces: `EnemyFaction`, `EnemyRank`, `EnemyBehaviorKind`, `EnemyBehaviorPhase`, `EnemyBehaviorProfile`, `enemyBehaviorProfiles`, `enemyBehaviorProfileFor(String)`, `enemyDefinitionFor(EnemyId)`, `validateEnemyContent()`.

- [ ] **Step 1: Write failing roster and validation tests**

```dart
test('roster contains eight normal enemies, three unique elites, and a boss', () {
  expect(enemyDefinitions.where((e) => e.rank == EnemyRank.normal), hasLength(8));
  expect(enemyDefinitions.where((e) => e.rank == EnemyRank.elite), hasLength(3));
  expect(enemyDefinitions.where((e) => e.rank == EnemyRank.boss), isNotEmpty);
  expect(enemyDefinitions.map((e) => e.id).toSet(), hasLength(enemyDefinitions.length));
  expect(enemyDefinitions.map((e) => e.name).toSet(), hasLength(enemyDefinitions.length));
  expect(validateEnemyContent(), isEmpty);
});

test('every profile has non-negative finite timing range and multiplier values', () {
  for (final profile in enemyBehaviorProfiles.values) {
    expect(profile.warningSeconds.isFinite && profile.warningSeconds >= 0, isTrue);
    expect(profile.activeSeconds.isFinite && profile.activeSeconds >= 0, isTrue);
    expect(profile.recoverySeconds.isFinite && profile.recoverySeconds >= 0, isTrue);
    expect(profile.cooldownSeconds.isFinite && profile.cooldownSeconds >= 0, isTrue);
    expect(profile.range.isFinite && profile.range >= 0, isTrue);
    expect(profile.movementMultiplier.isFinite && profile.movementMultiplier >= 0, isTrue);
  }
});
```

- [ ] **Step 2: Run tests and confirm missing types fail**

Run: `flutter test test/game/content_definitions_test.dart test/game/enemy_behavior_definitions_test.dart`

Expected: FAIL because `EnemyRank`, `enemyBehaviorProfiles`, and the seven new enemy IDs do not exist.

- [ ] **Step 3: Add the typed contract and exact roster data**

Add to `ids.dart` and retain `EnemyBehaviorType` as the legacy fallback contract:

```dart
typedef EnemyBehaviorProfileId = String;

enum EnemyFaction { plague, bandit, spirit, anomaly }
enum EnemyRank { normal, elite, boss }
enum EnemyBehaviorKind {
  chase, swarm, dash, tank, dive, thrust, deathZone, hasteAura,
  doubleDash, shockwave, scream,
}
enum EnemyBehaviorPhase { tracking, warning, active, recovery, cooldown }

class EnemyDefinition {
  const EnemyDefinition({
    required this.id,
    required this.name,
    required this.maxHealth,
    required this.moveSpeed,
    required this.damage,
    required this.experience,
    required this.faction,
    required this.rank,
    required this.behaviorProfileId,
    this.behaviorType = EnemyBehaviorType.chase,
  });

  final EnemyId id;
  final String name;
  final double maxHealth;
  final double moveSpeed;
  final double damage;
  final int experience;
  final EnemyFaction faction;
  final EnemyRank rank;
  final EnemyBehaviorProfileId behaviorProfileId;
  final EnemyBehaviorType behaviorType;
  bool get isBoss => rank == EnemyRank.boss;
  bool get isElite => rank == EnemyRank.elite;
}
```

Create `enemy_behavior_definitions.dart` with one immutable profile per behavior:

```dart
class EnemyBehaviorProfile {
  const EnemyBehaviorProfile({
    required this.id,
    required this.kind,
    this.warningSeconds = 0,
    this.activeSeconds = 0,
    this.recoverySeconds = 0,
    this.cooldownSeconds = 0,
    this.movementMultiplier = 1,
    this.range = 0,
    this.effectMultiplier = 1,
    this.maxOwnedEffects = 0,
  });
  final EnemyBehaviorProfileId id;
  final EnemyBehaviorKind kind;
  final double warningSeconds;
  final double activeSeconds;
  final double recoverySeconds;
  final double cooldownSeconds;
  final double movementMultiplier;
  final double range;
  final double effectMultiplier;
  final int maxOwnedEffects;
}

const enemyBehaviorProfiles = <EnemyBehaviorProfileId, EnemyBehaviorProfile>{
  'chase': EnemyBehaviorProfile(id: 'chase', kind: EnemyBehaviorKind.chase),
  'swarm': EnemyBehaviorProfile(id: 'swarm', kind: EnemyBehaviorKind.swarm),
  'dash': EnemyBehaviorProfile(id: 'dash', kind: EnemyBehaviorKind.dash, warningSeconds: .22, activeSeconds: .35, recoverySeconds: .18, cooldownSeconds: 2.4, movementMultiplier: 3.2),
  'tank': EnemyBehaviorProfile(id: 'tank', kind: EnemyBehaviorKind.tank),
  'crow_dive': EnemyBehaviorProfile(id: 'crow_dive', kind: EnemyBehaviorKind.dive, warningSeconds: .45, activeSeconds: .42, recoverySeconds: .3, cooldownSeconds: 2.8, movementMultiplier: 3.6, range: 22),
  'spear_thrust': EnemyBehaviorProfile(id: 'spear_thrust', kind: EnemyBehaviorKind.thrust, warningSeconds: .55, activeSeconds: .18, recoverySeconds: .45, cooldownSeconds: 2.2, movementMultiplier: 1.8, range: 54),
  'poison_death_zone': EnemyBehaviorProfile(id: 'poison_death_zone', kind: EnemyBehaviorKind.deathZone, activeSeconds: 4, range: 38, effectMultiplier: .35, maxOwnedEffects: 1),
  'grave_haste_aura': EnemyBehaviorProfile(id: 'grave_haste_aura', kind: EnemyBehaviorKind.hasteAura, activeSeconds: .2, range: 96, effectMultiplier: .2),
  'assassin_double_dash': EnemyBehaviorProfile(id: 'assassin_double_dash', kind: EnemyBehaviorKind.doubleDash, warningSeconds: .55, activeSeconds: .28, recoverySeconds: .16, cooldownSeconds: 3.2, movementMultiplier: 4, range: 24),
  'jangseung_shockwave': EnemyBehaviorProfile(id: 'jangseung_shockwave', kind: EnemyBehaviorKind.shockwave, warningSeconds: .8, activeSeconds: .12, recoverySeconds: .55, cooldownSeconds: 3.8, range: 88, effectMultiplier: 1),
  'maiden_scream': EnemyBehaviorProfile(id: 'maiden_scream', kind: EnemyBehaviorKind.scream, warningSeconds: .9, activeSeconds: .15, recoverySeconds: .5, cooldownSeconds: 4.2, range: 120, effectMultiplier: .75),
};

EnemyBehaviorProfile enemyBehaviorProfileFor(EnemyBehaviorProfileId id) =>
    enemyBehaviorProfiles[id] ?? enemyBehaviorProfiles['chase']!;
```

In `enemy_definitions.dart`, preserve the existing five IDs and add `plagueCrow`, `spearBandit`, `rottenHerbalist`, `graveEmber`, `blackHatAssassin`, `brokenJangseungSpirit`, and `sorrowfulMaidenGhost`. Use these exact base tuples `(health, speed, damage, xp)`: crow `(16,58,8,2)`, spear `(26,48,11,2)`, herbalist `(24,38,7,3)`, ember `(18,42,6,2)`, assassin `(160,65,16,12)`, jangseung `(280,28,18,18)`, maiden `(210,34,14,16)`. Assign the profile IDs shown above; assign `fallenGeneral` rank `boss`; keep `behaviorType: EnemyBehaviorType.tank` on both `dokkaebi` and `brokenJangseungSpirit`. Add the lookup exactly as follows, then add a validator that returns one message for each duplicate ID/name, non-positive health, negative speed/damage/experience, and missing profile reference.

Use this exact faction/rank/profile mapping:

| ID | faction | rank | profile |
| --- | --- | --- | --- |
| `plagueRatSwarm` | `plague` | `normal` | `swarm` |
| `bandit` | `bandit` | `normal` | `chase` |
| `dokkaebi` | `anomaly` | `normal` | `tank` |
| `vengefulSpirit` | `spirit` | `normal` | `dash` |
| `plagueCrow` | `plague` | `normal` | `crow_dive` |
| `spearBandit` | `bandit` | `normal` | `spear_thrust` |
| `rottenHerbalist` | `plague` | `normal` | `poison_death_zone` |
| `graveEmber` | `spirit` | `normal` | `grave_haste_aura` |
| `blackHatAssassin` | `bandit` | `elite` | `assassin_double_dash` |
| `brokenJangseungSpirit` | `anomaly` | `elite` | `jangseung_shockwave` |
| `sorrowfulMaidenGhost` | `spirit` | `elite` | `maiden_scream` |
| `fallenGeneral` | `anomaly` | `boss` | `tank` |

```dart
EnemyDefinition? enemyDefinitionFor(EnemyId id) {
  for (final definition in enemyDefinitions) {
    if (definition.id == id) return definition;
  }
  return null;
}
```

- [ ] **Step 4: Format and run focused tests**

Run: `dart format lib/game/content/ids.dart lib/game/content/enemy_behavior_definitions.dart lib/game/content/enemy_definitions.dart test/game/content_definitions_test.dart test/game/enemy_behavior_definitions_test.dart && flutter test test/game/content_definitions_test.dart test/game/enemy_behavior_definitions_test.dart`

Expected: both test files PASS and the roster validator returns no errors.

- [ ] **Step 5: Commit the content contract**

```powershell
git add lib/game/content/ids.dart lib/game/content/enemy_behavior_definitions.dart lib/game/content/enemy_definitions.dart test/game/content_definitions_test.dart test/game/enemy_behavior_definitions_test.dart
git commit -m "feat: define enemy and elite roster data"
```

### Task 2: Explicit Elite Wave Selection

**Files:**
- Modify: `lib/game/content/wave_definitions.dart`
- Modify: `lib/game/systems/wave_director.dart`
- Modify: `lib/game/balance/wave_regression_simulator.dart`
- Modify: `lib/game/balance/experience_balance_baseline.dart`
- Modify: `test/game/wave_director_test.dart`
- Modify: `test/game/multi_seed_run_regression_test.dart`

**Interfaces:**
- Consumes: `EnemyDefinition.rank`, elite IDs from Task 1.
- Produces: `WaveDefinition.eliteWeights`, rank-derived `SpawnRequest.isElite`, `validateWaveContent()`, normal-pool fallback for an empty elite map.

- [ ] **Step 1: Write failing elite-pool tests**

```dart
test('elite rolls select only explicit elite definitions', () {
  final definition = WaveDefinition(
    startSecond: 0, endSecond: 60,
    enemyWeights: const {bandit: 1},
    eliteWeights: const {blackHatAssassin: 1},
    startSpawnsPerSecond: 8, endSpawnsPerSecond: 8, groupSize: 8,
    startEliteChance: 1, endEliteChance: 1,
    startMaxActiveEnemies: 8, endMaxActiveEnemies: 8,
  );
  final director = WaveDirector(random: Random(1), definitions: [definition]);
  final requests = director.tick(elapsedSeconds: 1, dt: 1, activeEnemyCount: 0).spawnRequests;
  expect(requests.map((r) => r.enemyId), everyElement(blackHatAssassin));
  expect(requests.map((r) => r.isElite), everyElement(isTrue));
});

test('empty elite pool falls back to unscaled normal requests', () {
  final definition = WaveDefinition(
    startSecond: 0, endSecond: 60,
    enemyWeights: const {bandit: 1}, eliteWeights: const {},
    startSpawnsPerSecond: 1, endSpawnsPerSecond: 1, groupSize: 1,
    startEliteChance: 1, endEliteChance: 1,
    startMaxActiveEnemies: 1, endMaxActiveEnemies: 1,
  );
  final request = WaveDirector(random: Random(2), definitions: [definition])
      .tick(elapsedSeconds: 1, dt: 1, activeEnemyCount: 0).spawnRequests.single;
  expect(request.enemyId, bandit);
  expect(request.isElite, isFalse);
});
```

- [ ] **Step 2: Run the wave tests and confirm constructor failures**

Run: `flutter test test/game/wave_director_test.dart test/game/multi_seed_run_regression_test.dart`

Expected: FAIL because `eliteWeights` and the injectable `definitions` argument are absent.

- [ ] **Step 3: Separate normal and elite selection**

Add `required Map<EnemyId,int> eliteWeights` to `WaveDefinition`. Add optional named `List<WaveDefinition> definitions = waveDefinitions` to `waveDefinitionForSecond`, `wavePressureForSecond`, and `WaveDirector`; have the director call `wavePressureForSecond(elapsedSeconds, definitions: _definitions)`. Replace each request roll with:

```dart
final rolledElite = definition.eliteWeights.isNotEmpty &&
    _random.nextDouble() < pressure.eliteChance;
final pool = rolledElite ? definition.eliteWeights : definition.enemyWeights;
final selectedId = _selectEnemyId(pool, exclude: rolledElite ? null : excludedNormalId);
requests.add(SpawnRequest(enemyId: selectedId, isElite: rolledElite));
```

Use `{brokenJangseungSpirit: 1}` from 60–179 seconds and `{brokenJangseungSpirit: 1, sorrowfulMaidenGhost: 1}` from 180 seconds onward. Keep first-wave `eliteWeights` empty so the opening cannot create an elite. Add `List<String> validateWaveContent()` that reports unknown IDs, normal-pool entries whose rank is not `normal`, elite-pool entries whose rank is not `elite`, and weights less than one; assert it is empty in `wave_director_test.dart`. Update the simulator's invalid-pool check to select `enemyWeights` or `eliteWeights` based on `request.isElite`; remove the old `isElite ? 1.5 : 1` lifetime multiplier because elites now have their own health. In `ExperienceBalanceBaseline`, replace the generic elite multiplier with `(1 - eliteChance) * weightedNormalXp + eliteChance * weightedEliteXp`; when `eliteWeights` is empty, use `weightedNormalXp` for both terms.

- [ ] **Step 4: Run wave and balance regressions**

Run: `dart format lib/game/content/wave_definitions.dart lib/game/systems/wave_director.dart lib/game/balance/wave_regression_simulator.dart lib/game/balance/experience_balance_baseline.dart test/game/wave_director_test.dart test/game/multi_seed_run_regression_test.dart && flutter test test/game/wave_director_test.dart test/game/multi_seed_run_regression_test.dart test/game/experience_balance_baseline_test.dart`

Expected: PASS; all 20 seeds have zero invalid-pool and active-cap violations, with at least one pressure-phase elite across the sample.

- [ ] **Step 5: Commit explicit elite spawning**

```powershell
git add lib/game/content/wave_definitions.dart lib/game/systems/wave_director.dart lib/game/balance/wave_regression_simulator.dart lib/game/balance/experience_balance_baseline.dart test/game/wave_director_test.dart test/game/multi_seed_run_regression_test.dart
git commit -m "feat: spawn unique elites from dedicated pools"
```

### Task 3: Deterministic Telegraph State Machine

**Files:**
- Create: `lib/game/systems/enemy_behavior_controller.dart`
- Create: `test/game/enemy_behavior_controller_test.dart`

**Interfaces:**
- Consumes: `EnemyBehaviorProfile`, `EnemyBehaviorPhase`.
- Produces: `EnemyBehaviorController`, `EnemyBehaviorTick`, `EnemyAttackRequest`, and `EnemyAttackKind`.

- [ ] **Step 1: Write failing phase, direction-lock, and double-dash tests**

```dart
test('warning locks target and active emits one attack', () {
  final controller = EnemyBehaviorController(profile: enemyBehaviorProfiles['spear_thrust']!);
  EnemyBehaviorTick warning = controller.tick(dt: 0, origin: Vector2.zero(), target: Vector2(10, 0));
  for (var i = 0; i < 45; i++) {
    warning = controller.tick(dt: .05, origin: Vector2.zero(), target: Vector2(10, 0));
  }
  expect(warning.phase, EnemyBehaviorPhase.warning);
  EnemyBehaviorTick active = warning;
  for (var i = 0; i < 12 && active.attack == null; i++) {
    active = controller.tick(dt: .05, origin: Vector2.zero(), target: Vector2(0, 10));
  }
  expect(active.attack!.direction.x, closeTo(1, .001));
  expect(active.attack!.direction.y, closeTo(0, .001));
});

test('assassin emits exactly two dashes before recovery', () {
  final controller = EnemyBehaviorController(profile: enemyBehaviorProfiles['assassin_double_dash']!);
  final attacks = <EnemyAttackRequest>[];
  for (var i = 0; i < 500; i++) {
    final result = controller.tick(dt: .02, origin: Vector2.zero(), target: Vector2(100, 0));
    if (result.attack != null) attacks.add(result.attack!);
    if (result.phase == EnemyBehaviorPhase.cooldown) break;
  }
  expect(attacks.where((a) => a.kind == EnemyAttackKind.dash), hasLength(2));
});
```

- [ ] **Step 2: Run the new test and confirm missing controller types fail**

Run: `flutter test test/game/enemy_behavior_controller_test.dart`

Expected: FAIL because the controller and request types do not exist.

- [ ] **Step 3: Implement a pure, bounded state machine**

```dart
enum EnemyAttackKind { dive, thrust, dash, shockwave, scream }

class EnemyAttackRequest {
  EnemyAttackRequest({required this.kind, required Vector2 origin, required Vector2 direction, required this.range})
      : origin = origin.clone(), direction = direction.clone();
  final EnemyAttackKind kind;
  final Vector2 origin;
  final Vector2 direction;
  final double range;
}

class EnemyBehaviorTick {
  const EnemyBehaviorTick({required this.phase, required this.movementMultiplier, this.attack});
  final EnemyBehaviorPhase phase;
  final double movementMultiplier;
  final EnemyAttackRequest? attack;
}
```

`EnemyBehaviorController.tick({required double dt, required Vector2 origin, required Vector2 target})` must treat negative or non-finite `dt` as zero, clamp positive `dt` to `0.05`, capture `(target-origin).normalized()` only when entering `warning`, emit at most one request per tick, and traverse `tracking → warning → active → recovery → cooldown → tracking`. The initial tracking duration is the profile cooldown. Chase, swarm, tank, death-zone, and haste-aura profiles remain in tracking and emit no attack. Double dash emits at the first active entry and once more halfway through active time, retaining the locked direction. Expose `phase`, `lockedDirection`, and `warningRange` for rendering tests.

Map attack-producing profiles with this exhaustive switch:

```dart
EnemyAttackKind? attackKindFor(EnemyBehaviorKind kind) => switch (kind) {
  EnemyBehaviorKind.dive => EnemyAttackKind.dive,
  EnemyBehaviorKind.thrust => EnemyAttackKind.thrust,
  EnemyBehaviorKind.dash || EnemyBehaviorKind.doubleDash => EnemyAttackKind.dash,
  EnemyBehaviorKind.shockwave => EnemyAttackKind.shockwave,
  EnemyBehaviorKind.scream => EnemyAttackKind.scream,
  EnemyBehaviorKind.chase || EnemyBehaviorKind.swarm ||
  EnemyBehaviorKind.tank || EnemyBehaviorKind.deathZone ||
  EnemyBehaviorKind.hasteAura => null,
};
```

- [ ] **Step 4: Run deterministic controller tests**

Run: `dart format lib/game/systems/enemy_behavior_controller.dart test/game/enemy_behavior_controller_test.dart && flutter test test/game/enemy_behavior_controller_test.dart`

Expected: PASS for phase boundaries, target locking, zero-distance target fallback `(1,0)`, large/negative/non-finite `dt`, and exactly two assassin dashes.

- [ ] **Step 5: Commit the behavior engine**

```powershell
git add lib/game/systems/enemy_behavior_controller.dart test/game/enemy_behavior_controller_test.dart
git commit -m "feat: add telegraphed enemy behavior controller"
```

### Task 4: Enemy Hazards and Non-stacking Auras

**Files:**
- Create: `lib/game/components/enemy_hazard_component.dart`
- Create: `lib/game/systems/enemy_aura_resolver.dart`
- Create: `test/game/enemy_hazard_component_test.dart`
- Create: `test/game/enemy_aura_resolver_test.dart`

**Interfaces:**
- Consumes: `PlayerComponent`, `EnemyComponent`, Flame `PositionComponent`.
- Produces: `EnemyHazardComponent`, `EnemyHazardKind`, `EnemyAuraResolver.resolve({required Iterable<double> hasteFractions, required Iterable<double> slowFractions})`.

- [ ] **Step 1: Write failing hazard lifecycle and strongest-aura tests**

```dart
test('poison damages at most once per interval and expires', () {
  final hazard = EnemyHazardComponent.poison(position: Vector2.zero(), damage: 4);
  final player = PlayerComponent(slotIndex: 0, maxHealth: 100, moveSpeed: 100, position: Vector2.zero());
  expect(hazard.damageFor(player), 4);
  expect(hazard.damageFor(player), 0);
  hazard.update(.5);
  expect(hazard.damageFor(player), 4);
  hazard.update(3.5);
  expect(hazard.isExpired, isTrue);
});

test('haste and slow use strongest value without stacking', () {
  final result = const EnemyAuraResolver().resolve(hasteFractions: [.2, .2], slowFractions: [.15, .35]);
  expect(result.hasteFraction, .2);
  expect(result.slowFraction, .35);
});
```

- [ ] **Step 2: Run focused tests and confirm missing component failures**

Run: `flutter test test/game/enemy_hazard_component_test.dart test/game/enemy_aura_resolver_test.dart`

Expected: FAIL because hazard and aura resolver types do not exist.

- [ ] **Step 3: Implement bounded effects**

Define `EnemyHazardKind { poison, warning, shockwave, scream }`. `EnemyHazardComponent` stores `kind`, `radius`, `damage`, `durationSeconds`, `tickIntervalSeconds`, `sourceId`, elapsed time, and a per-player next-hit map. Its factory values are poison `(radius 38, duration 4, interval .5)`, warning `(damage 0)`, shockwave `(duration .12, one hit)`, and scream `(duration .15, one hit)`. `containsPlayer` uses center distance plus half player width; `damageFor` returns zero outside the radius, after expiry, or before that player's next interval.

Implement the resolver as:

```dart
class EnemyAuraResult {
  const EnemyAuraResult({required this.hasteFraction, required this.slowFraction});
  final double hasteFraction;
  final double slowFraction;
}

class EnemyAuraResolver {
  const EnemyAuraResolver();
  EnemyAuraResult resolve({required Iterable<double> hasteFractions, required Iterable<double> slowFractions}) => EnemyAuraResult(
    hasteFraction: hasteFractions.fold<double>(0, (strongest, value) => math.max(strongest, value)).clamp(0, .6).toDouble(),
    slowFraction: slowFractions.fold<double>(0, (strongest, value) => math.max(strongest, value)).clamp(0, .8).toDouble(),
  );
}
```

- [ ] **Step 4: Run hazard and aura tests**

Run: `dart format lib/game/components/enemy_hazard_component.dart lib/game/systems/enemy_aura_resolver.dart test/game/enemy_hazard_component_test.dart test/game/enemy_aura_resolver_test.dart && flutter test test/game/enemy_hazard_component_test.dart test/game/enemy_aura_resolver_test.dart`

Expected: PASS, including outside-radius no-damage, per-player tick isolation, expiry, and non-stacking values.

- [ ] **Step 5: Commit world-effect primitives**

```powershell
git add lib/game/components/enemy_hazard_component.dart lib/game/systems/enemy_aura_resolver.dart test/game/enemy_hazard_component_test.dart test/game/enemy_aura_resolver_test.dart
git commit -m "feat: add bounded enemy hazards and auras"
```

### Task 5: Wire Profiles into Enemy Components

**Files:**
- Modify: `lib/game/components/enemy_component.dart`
- Modify: `lib/game/components/boss_component.dart`
- Modify: `test/game/enemy_component_test.dart`
- Modify: `test/game/boss_component_visual_test.dart`

**Interfaces:**
- Consumes: Task 1 profiles and ranks, Task 3 controller and attack requests.
- Produces: `EnemyComponent.rank`, `EnemyComponent.drainAttackRequests()`, `deathZonePending`, `consumeDeathZone()`, `hasteAuraFraction`, `slowAuraFraction`, `attackPhase`, rank-derived `isElite`.

- [ ] **Step 1: Replace the scaled-elite test with rank and behavior tests**

```dart
test('unique elite uses authored stats without generic scaling', () {
  final definition = enemyDefinitionFor(blackHatAssassin)!;
  final enemy = EnemyComponent.fromDefinition(definition);
  expect(enemy.isElite, isTrue);
  expect(enemy.maxHealth, 160);
  expect(enemy.damage, 16);
  expect(enemy.experienceValue, 12);
  expect(enemy.size.x, 40);
  expect(enemy.size.y, 40);
});

test('herbalist exposes one death zone after lethal damage', () {
  final enemy = EnemyComponent.fromDefinition(enemyDefinitionFor(rottenHerbalist)!);
  enemy.takeDamage(enemy.maxHealth);
  expect(enemy.consumeDeathZone(), isTrue);
  expect(enemy.consumeDeathZone(), isFalse);
});

test('spear warning locks before its thrust request', () {
  var target = Vector2(100, 0);
  final enemy = EnemyComponent.fromDefinition(enemyDefinitionFor(spearBandit)!, targetPositionProvider: (_) => target);
  enemy.update(2.2);
  enemy.update(.05);
  target = Vector2(0, 100);
  for (var i = 0; i < 20; i++) enemy.update(.05);
  final request = enemy.drainAttackRequests().single;
  expect(request.kind, EnemyAttackKind.thrust);
  expect(request.direction.x, greaterThan(.99));
});
```

- [ ] **Step 2: Run the component test and confirm legacy elite assumptions fail**

Run: `flutter test test/game/enemy_component_test.dart`

Expected: FAIL because the factory still accepts generic `isElite` scaling and behavior outputs are absent.

- [ ] **Step 3: Integrate the controller and rank-derived presentation**

Remove the `isElite` factory parameter and all `2.5/1.4/3/1.35` scaling. Add `EnemyRank rank` to the direct constructor with default `normal`; set it from the definition in the factory and derive `isElite` from `rank == EnemyRank.elite`. Use size `40` for elites and `18` for normal factory instances. Pass `rank: EnemyRank.boss` from `BossComponent` while preserving its authored size. Resolve the profile once in the factory, store an `EnemyBehaviorController`, and append every non-null tick attack to a private queue capped at two entries. `drainAttackRequests()` returns an unmodifiable copy and clears the queue. Mark a death-zone profile pending exactly once when health crosses from positive to zero. Return `.2` only from grave ember's `hasteAuraFraction`; return `.25` only from maiden's `slowAuraFraction`.

During `warning`, do not apply chase movement for thrust, shockwave, or scream. During active dive/dash, move only along `lockedDirection` using the profile multiplier. Preserve swarm separation and tank knockback behavior. Render warnings before the body as a stroked line for dive/thrust/dash and a stroked circle for shockwave/scream; keep the existing rectangle fallback and orange elite outline.

During crow tracking, blend a normalized perpendicular vector at `0.55` with the normalized player direction at `0.45` so it approaches while circling instead of running straight in. The spear uses normal chase outside warning/active/recovery. If a definition contains an unknown profile ID, record one `debugPrint` per unknown ID and use the `chase` profile; add a test asserting the fallback moves toward the target without throwing. Do not add new IDs to `EnemySpriteSheet.specs`; their missing sheets deliberately exercise the existing shape fallback.

- [ ] **Step 4: Run component and visual-contract tests**

Run: `dart format lib/game/components/enemy_component.dart lib/game/components/boss_component.dart test/game/enemy_component_test.dart test/game/boss_component_visual_test.dart && flutter test test/game/enemy_component_test.dart test/game/boss_component_visual_test.dart test/game/art_style_guide_test.dart`

Expected: PASS; legacy chase/swarm/dash/tank tests remain green and the three new tests pass.

- [ ] **Step 5: Commit component behaviors**

```powershell
git add lib/game/components/enemy_component.dart lib/game/components/boss_component.dart test/game/enemy_component_test.dart test/game/boss_component_visual_test.dart
git commit -m "feat: connect enemy profiles to combat components"
```

### Task 6: World Combat, Death Zones, and Aura Integration

**Files:**
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `lib/game/components/player_component.dart`
- Modify: `test/game/pixel_survivor_game_loop_test.dart`
- Modify: `test/game/player_component_test.dart`

**Interfaces:**
- Consumes: Task 4 hazards/resolver and Task 5 attack/death/aura outputs.
- Produces: capped hazard spawning, player damage attribution by enemy ID, per-frame aura resolution.

- [ ] **Step 1: Write failing game-loop integration tests**

```dart
Future<PixelSurvivorGame> mountedTestGame() async {
  final game = newGame();
  game.onGameResize(Vector2(960, 540));
  await game.onLoad();
  return game;
}

test('herbalist death creates one capped poison zone', () async {
  final game = await mountedTestGame();
  final herbalist = game.debugSpawnEnemy(rottenHerbalist, position: Vector2.zero());
  herbalist.takeDamage(herbalist.maxHealth);
  game.update(EnemySpriteSheet.deathDurationSeconds);
  expect(game.children.whereType<EnemyHazardComponent>().where((h) => h.kind == EnemyHazardKind.poison), hasLength(1));
  game.update(.1);
  expect(game.children.whereType<EnemyHazardComponent>().where((h) => h.kind == EnemyHazardKind.poison), hasLength(1));
});

test('grave ember haste is strongest-only and maiden slow resets out of range', () async {
  final game = await mountedTestGame();
  final target = game.debugSpawnEnemy(bandit, position: Vector2.zero());
  game.debugSpawnEnemy(graveEmber, position: Vector2(10, 0));
  game.debugSpawnEnemy(graveEmber, position: Vector2(20, 0));
  game.update(.05);
  expect(target.environmentalHasteFraction, .2);
  game.debugSpawnEnemy(sorrowfulMaidenGhost, position: game.debugPlayer.position.clone());
  game.update(.05);
  expect(game.debugPlayer.environmentalSlowFraction, .25);
});
```

- [ ] **Step 2: Run the loop tests and confirm missing debug/integration APIs fail**

Run: `flutter test test/game/pixel_survivor_game_loop_test.dart`

Expected: FAIL because hazard creation, enemy haste, player environmental slow, and `debugSpawnEnemy` are absent.

- [ ] **Step 3: Integrate effects in the game update order**

After `_resolveFrostFields()` and before defeat recording, call `_resolveEnemyActions()`, `_resolveEnemyHazards()`, and `_resolveEnemyAuras()`. For dive/thrust/dash requests, test a finite line segment against each alive player and apply source enemy damage once. For shockwave/scream, spawn a one-hit circular hazard at the locked origin. After each successful hit, call `_recordPlayerDamage(player: player, healthBefore: healthBefore, sourceId: enemy.enemyId)`.

When `_recordNewEnemyDefeats()` sees `consumeDeathZone() == true`, add one poison hazard at the death position with damage `enemy.damage * enemy.behaviorProfile.effectMultiplier`. Shockwave and scream damage use the same profile multiplier. Add helpers with exact caps:

```dart
static const maxPoisonZones = 12;
static const maxEnemyAttackEffects = 24;

void _addCappedHazard(EnemyHazardComponent hazard) {
  final candidates = children.whereType<EnemyHazardComponent>()
      .where((item) => hazard.kind == EnemyHazardKind.poison
          ? item.kind == EnemyHazardKind.poison
          : item.kind != EnemyHazardKind.poison)
      .toList();
  final cap = hazard.kind == EnemyHazardKind.poison
      ? maxPoisonZones : maxEnemyAttackEffects;
  if (candidates.length >= cap) candidates.first.removeFromParent();
  add(hazard);
}
```

Resolve enemy haste by scanning alive grave embers no more than once per `0.1` seconds and applying only the strongest in-range fraction to alive `EnemyRank.normal` targets through new `EnemyComponent.setEnvironmentalHaste(double)`. Do not haste the source itself. Compute enemy effective speed as `moveSpeed * (1 + haste) * (1 - slow)`. Resolve player slow from alive maidens the same way through `PlayerComponent.setEnvironmentalSlow(double)` and multiply its existing movement result by `(1 - environmentalSlowFraction)`. Validate both setters in the range `0 <= value < .8`; reset them to zero when no source is in range. Add a setter reset test to `player_component_test.dart`. Add `@visibleForTesting EnemyComponent debugSpawnEnemy(EnemyId id,{required Vector2 position})` and `@visibleForTesting PlayerComponent get debugPlayer` for loop tests.

- [ ] **Step 4: Run combat, loop, and reward-focused tests**

Run: `dart format lib/game/pixel_survivor_game.dart lib/game/components/player_component.dart test/game/pixel_survivor_game_loop_test.dart test/game/player_component_test.dart && flutter test test/game/pixel_survivor_game_loop_test.dart test/game/player_component_test.dart test/game/combat_system_test.dart test/game/run_stats_tracker_test.dart test/game/meta_reward_policy_test.dart`

Expected: PASS; poison appears once per herbalist, caps evict oldest effects, attacks do no damage outside their warned geometry, and aura values reset after leaving range.

- [ ] **Step 5: Commit game-world integration**

```powershell
git add lib/game/pixel_survivor_game.dart lib/game/components/player_component.dart test/game/pixel_survivor_game_loop_test.dart test/game/player_component_test.dart
git commit -m "feat: integrate enemy attacks hazards and auras"
```

### Task 7: Rewards, Balance Baselines, and Release Verification

**Files:**
- Modify: `lib/game/balance/enemy_balance_baseline.dart`
- Modify: `test/game/enemy_balance_baseline_test.dart`
- Modify: `test/game/run_stats_tracker_test.dart`
- Modify: `test/game/meta_reward_policy_test.dart`
- Modify: `test/game/five_minute_run_simulation_test.dart`
- Modify: `docs/TODO.md`

**Interfaces:**
- Consumes: all prior tasks and existing `RunStatsTracker`, `MetaRewardPolicy`, fixed-seed simulators.
- Produces: rank-aware balance report, explicit elite reward regression, completed `CNT-007` and `CNT-008` evidence.

- [ ] **Step 1: Add failing rank-aware balance and reward tests**

```dart
test('normal balance rows exclude elites and boss', () {
  final report = const EnemyBalanceAnalyzer().analyze();
  expect(report.rows.map((row) => row.enemyId).toSet(), {
    plagueRatSwarm, bandit, dokkaebi, vengefulSpirit,
    plagueCrow, spearBandit, rottenHerbalist, graveEmber,
  });
});

test('a unique elite defeat counts and rewards exactly once', () {
  final tracker = RunStatsTracker()..recordEnemyDefeat(isBoss: false, isElite: true);
  final result = tracker.toRunResult(
    outcome: RunOutcome.defeat,
    survivalSeconds: 60,
    level: 5,
    wonWithLowHealth: false,
    weaponLevels: const {},
  );
  expect(result.eliteKills, 1);
  expect(
    const MetaRewardPolicy().coinForRun(result),
    (MetaRewardBalance.participationCoin +
      60 * MetaRewardBalance.coinPerSurvivalSecond +
      MetaRewardBalance.coinPerKill +
      MetaRewardBalance.coinPerEliteKill).floor(),
  );
});
```

- [ ] **Step 2: Run balance and reward tests and confirm roster assumptions fail**

Run: `flutter test test/game/enemy_balance_baseline_test.dart test/game/run_stats_tracker_test.dart test/game/meta_reward_policy_test.dart test/game/five_minute_run_simulation_test.dart`

Expected: FAIL where analyzers still treat every non-boss definition as a normal balance row or expected rosters contain four enemies.

- [ ] **Step 3: Make analyzers and playtest data rank-aware**

Filter normal balance rows with `enemy.rank == EnemyRank.normal`, add a separate `eliteRows` list filtered by `EnemyRank.elite`, and assert all elite rows have higher health than `bandit` while remaining slower than the starter player except the assassin. Preserve the existing experience target of 9–12 level-ups in five minutes. Mark `CNT-007` and `CNT-008` complete in `docs/TODO.md` with the focused test files and final gate commit as evidence; leave `CNT-009` as the next queue item.

- [ ] **Step 4: Run the minimum full release gate**

Run these commands in order:

```powershell
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```

Expected: formatting reports no changes, analysis reports no issues, all Flutter tests PASS, and both builds exit with code 0. Also confirm `test/game/multi_seed_run_regression_test.dart` reports all 20 seeds with `maxFrameSpawns <= 8`, zero cap violations, exactly one boss request, and no invalid pool requests.

- [ ] **Step 5: Commit verification evidence**

```powershell
git add lib/game/balance/enemy_balance_baseline.dart test/game/enemy_balance_baseline_test.dart test/game/run_stats_tracker_test.dart test/game/meta_reward_policy_test.dart test/game/five_minute_run_simulation_test.dart docs/TODO.md
git commit -m "test: verify complete enemy and elite roster"
```

After the commit, run `git status --short` and expect no output.
