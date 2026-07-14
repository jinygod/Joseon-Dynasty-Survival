# 조선시대 서바이벌 5분 1인 전투 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 한 명의 순라군이 5분 동안 성장해 타락한 관군 대장을 쓰러뜨리는 완전한 1인 플레이 스테이지를 만든다.

**Architecture:** `PixelSurvivorGame`은 런 상태와 Flame 컴포넌트를 조율하고, 시간 기반 생성은 `WaveDirector`, 공격 계산은 `WeaponSystem`과 `CombatSystem`, 보스 패턴은 `BossController`가 담당한다. 각 시스템은 고정 난수와 순수 데이터 입력으로 단위 테스트할 수 있게 만들며 UI에는 읽기 전용 상태만 노출한다.

**Tech Stack:** Flutter 3.44.4, Dart 3.12.2, Flame 1.18 계열, flutter_test, flame_test, shared_preferences

## Global Constraints

- 게임은 1인 전용이며 활성 플레이어는 정확히 한 명만 허용한다.
- 첫 스테이지는 4분 30초에 보스가 한 번 등장하고 5분 전후에 끝나며 5분 30초에 보스가 광폭화한다.
- 첫 플레이 목표 승률은 약 70%이고 일반적인 한 판에서 8~12회 레벨업한다.
- 첫 스테이지에서 환도 베기, 각궁 사격, 부적 투척, 벽력진천뢰 네 무기를 사용한다.
- 도트 그래픽, 음향, 무기 진화, 다중 캐릭터, 모든 2인 및 다인 플레이는 이 계획의 범위에 포함하지 않는다.
- 모든 동작 변경은 실패 테스트 작성, 실패 확인, 최소 구현, 통과 확인 순서로 진행한다.
- 각 작업 커밋 후 `git push origin codex/pixel-survivor-mvp`를 실행한다.
- Windows에서 Flutter 명령은 `F:`에 Flutter SDK, `P:`에 작업 트리를 매핑한 안정 실행 환경을 사용한다.

---

## File Structure

### 새 파일

- `lib/game/models/run_outcome.dart`: 진행 중, 승리, 패배 런 상태
- `lib/game/models/damage_event.dart`: 무기 피해, 치명타, 넉백 전달 값
- `lib/game/content/wave_definitions.dart`: 5분 스테이지 구간별 생성 데이터
- `lib/game/content/weapon_level_definitions.dart`: 네 무기의 1~5레벨 동작 수치
- `lib/game/systems/wave_director.dart`: 스폰 예산, 정예 확률, 보스 단일 생성
- `lib/game/systems/combat_system.dart`: 피해, 치명타, 접촉 피해 간격, 넉백 계산
- `lib/game/systems/boss_controller.dart`: 보스 패턴과 광폭화 상태 전환
- `lib/game/components/melee_arc_component.dart`: 환도 공격 범위 표시
- `lib/game/components/area_attack_component.dart`: 벽력진천뢰와 보스 경고 영역
- `lib/game/components/damage_number_component.dart`: 수명이 제한된 피해 숫자
- `lib/game/components/boss_component.dart`: 타락한 관군 대장 실행 컴포넌트
- `lib/app/game_hud_source.dart`: HUD가 읽는 게임 상태 인터페이스
- `test/game/wave_director_test.dart`: 웨이브와 보스 생성 테스트
- `test/game/combat_system_test.dart`: 피해와 접촉 피해 간격 테스트
- `test/game/boss_controller_test.dart`: 보스 상태 전환 테스트
- `test/game/five_minute_run_simulation_test.dart`: 고정 시드 5분 시뮬레이션
- `test/app/game_hud_test.dart`: 보스 체력바와 무기 목록 위젯 테스트

### 주요 수정 파일

- `lib/game/pixel_survivor_game.dart`: 시스템 조율, 1인 제약, 승패 우선순위
- `lib/game/systems/weapon_system.dart`: 네 무기의 서로 다른 공격 결과 생성
- `lib/game/systems/level_up_system.dart`: 혼합 선택과 효과 설명
- `lib/game/systems/run_progression_system.dart`: 8~12회 레벨업 경험치 곡선
- `lib/game/components/enemy_component.dart`: 적 행동, 피격 점멸, 넉백, 정예 표시
- `lib/game/components/projectile_component.dart`: 관통과 중복 타격 방지
- `lib/game/components/player_component.dart`: 체력 증가와 회복
- `lib/game/content/enemy_definitions.dart`: 적 행동 종류와 한국어 이름
- `lib/game/content/augment_definitions.dart`: 여덟 증강 효과 데이터
- `lib/game/models/run_result.dart`: 승패와 최종 무기 레벨
- `lib/app/game_screen.dart`: 한 명 플레이어로 게임 생성
- `lib/app/game_hud.dart`: 무기 목록과 보스 체력바
- `lib/app/level_up_overlay.dart`: 한국어 효과 설명
- `lib/app/run_summary_screen.dart`: 승리·패배와 최종 빌드
- `docs/testing/manual-qa-test-cases.txt`: 5분 완주 수동 검증

---

### Task 1: 1인 런 계약과 승패 모델

**Files:**
- Create: `lib/game/models/run_outcome.dart`
- Modify: `lib/game/models/run_result.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `lib/game/systems/run_stats_tracker.dart`
- Modify: `lib/app/game_screen.dart`
- Modify: `test/game/pixel_survivor_game_loop_test.dart`
- Modify: `test/game/run_stats_tracker_test.dart`
- Modify: `test/game/run_summary_progression_test.dart`

**Interfaces:**
- Produces: `enum RunOutcome { inProgress, victory, defeat }`
- Produces: `PixelSurvivorGame({required PlayerSlot playerSlot, required void Function(RunResult)? onRunEnded, Random? random})`
- Produces: `RunResult.outcome`과 `RunResult.weaponLevels`
- Produces: `RunStatsTracker.toRunResult({required RunOutcome outcome, required int survivalSeconds, required int level, required bool wonWithLowHealth, required Map<String, int> weaponLevels})`

- [ ] **Step 1: 한 명만 받는 생성자와 결과 상태의 실패 테스트 작성**

```dart
test('game accepts exactly one player slot', () {
  final game = PixelSurvivorGame(
    playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
  );
  expect(game.playerSlot.index, 0);
  expect(game.activePlayers, isEmpty);
});

test('run result exposes explicit victory outcome and weapon levels', () {
  const result = RunResult(
    outcome: RunOutcome.victory,
    survivalSeconds: 300,
    kills: 100,
    level: 10,
    bossDefeated: true,
    wonWithLowHealth: false,
    weaponKillCounts: {},
    weaponLevels: {hwandoSlash: 5},
  );
  expect(result.outcome, RunOutcome.victory);
  expect(result.weaponLevels[hwandoSlash], 5);
});
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/game/pixel_survivor_game_loop_test.dart test/game/run_summary_progression_test.dart`

Expected: `playerSlot`, `RunOutcome`, `weaponLevels`가 정의되지 않아 FAIL

- [ ] **Step 3: 런 모델과 단일 플레이어 생성자 구현**

```dart
enum RunOutcome { inProgress, victory, defeat }

class RunResult {
  const RunResult({
    required this.outcome,
    required this.survivalSeconds,
    required this.kills,
    required this.level,
    required this.bossDefeated,
    required this.wonWithLowHealth,
    required this.weaponKillCounts,
    required this.weaponLevels,
  });

  final RunOutcome outcome;
  final int survivalSeconds;
  final int kills;
  final int level;
  final bool bossDefeated;
  final bool wonWithLowHealth;
  final Map<String, int> weaponKillCounts;
  final Map<String, int> weaponLevels;
}
```

`PixelSurvivorGame`의 `List<PlayerSlot>` 입력과 반복 생성을 `PlayerSlot playerSlot` 하나로 교체한다. `GameScreen`과 모든 테스트 픽스처도 새 생성자를 사용한다.

`RunStatsTracker.toRunResult`는 호출자가 전달한 `outcome`과 `weaponLevels`를 `RunResult`에 그대로 복사한다. 기존 통계 테스트는 패배 결과와 빈 무기 레벨을 명시하고, 게임의 `currentRunResult`는 현재 런 상태와 `weaponSystem.levels`를 전달한다.

- [ ] **Step 4: 관련 테스트와 전체 회귀 테스트 통과 확인**

Run: `flutter test test/game/pixel_survivor_game_loop_test.dart test/game/run_summary_progression_test.dart`

Run: `flutter test`

Expected: 전체 테스트 PASS

- [ ] **Step 5: 커밋과 푸시**

```powershell
git add lib/game/models/run_outcome.dart lib/game/models/run_result.dart lib/game/pixel_survivor_game.dart lib/game/systems/run_stats_tracker.dart lib/app/game_screen.dart test
git commit -m "refactor: enforce single-player run contract"
git push origin codex/pixel-survivor-mvp
```

---

### Task 2: 무기 레벨 및 증강 데이터

**Files:**
- Create: `lib/game/content/weapon_level_definitions.dart`
- Modify: `lib/game/content/weapon_definitions.dart`
- Modify: `lib/game/content/augment_definitions.dart`
- Modify: `lib/game/content/ids.dart`
- Create: `test/game/content_definitions_test.dart`
- Modify: `test/game/level_up_system_test.dart`
- Modify: `test/game/pixel_survivor_game_loop_test.dart`

**Interfaces:**
- Produces: `WeaponLevelDefinition weaponLevelFor(WeaponId id, int level)`
- Produces: `AugmentDefinition.effectDescriptionForLevel(int nextLevel)`
- Consumes: 기존 `WeaponId`, `AugmentId`, `ElementType`

- [ ] **Step 1: 네 무기 5레벨과 여덟 증강 데이터 실패 테스트 작성**

```dart
test('first stage has four weapons with five complete levels', () {
  const ids = [hwandoSlash, gakgungShot, talismanThrow, thunderCrashBomb];
  for (final id in ids) {
    expect(weaponLevels[id], hasLength(5));
    expect(weaponLevelFor(id, 1).damage, greaterThan(0));
    expect(weaponLevelFor(id, 5).displayEffect, isNotEmpty);
  }
});

test('first stage exposes exactly eight functional augments', () {
  expect(firstStageAugmentIds, hasLength(8));
  for (final id in firstStageAugmentIds) {
    final definition = augmentDefinitions.singleWhere((item) => item.id == id);
    expect(definition.effectDescriptionForLevel(1), isNotEmpty);
  }
});
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/game/content_definitions_test.dart`

Expected: 레벨 데이터와 설명 API가 없어 FAIL

- [ ] **Step 3: 명시적인 레벨 데이터 구현**

```dart
class WeaponLevelDefinition {
  const WeaponLevelDefinition({
    required this.damage,
    required this.cooldownSeconds,
    required this.range,
    required this.projectileCount,
    required this.pierce,
    required this.chainCount,
    required this.knockback,
    required this.displayEffect,
  });

  final double damage;
  final double cooldownSeconds;
  final double range;
  final int projectileCount;
  final int pierce;
  final int chainCount;
  final double knockback;
  final String displayEffect;
}
```

각 무기에 5개 값을 직접 정의한다. 한국어 이름은 `환도 베기`, `각궁 사격`, `부적 투척`, `벽력진천뢰`를 사용한다. 첫 스테이지 증강은 무예 단련, 빠른 발놀림, 빠른 장전, 내공 호흡, 매의 눈, 약초 주머니, 장승의 가호, 화약 조제 여덟 종으로 제한한다.

무기 레벨 값은 다음 표를 그대로 사용한다. `count`는 환도의 베기 수, 각궁과 부적의 투사체 수, 벽력진천뢰의 폭발 수를 뜻한다.

| 무기 | Lv | damage | cooldown | range | count | pierce | chain | knockback | displayEffect |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| 환도 베기 | 1 | 8 | 0.72 | 58 | 1 | 0 | 0 | 45 | 피해 8, 범위 58 |
| 환도 베기 | 2 | 10 | 0.72 | 68 | 1 | 0 | 0 | 50 | 피해 10, 범위 +10 |
| 환도 베기 | 3 | 12 | 0.60 | 68 | 1 | 0 | 0 | 55 | 재사용 시간 0.60초 |
| 환도 베기 | 4 | 15 | 0.60 | 82 | 1 | 0 | 0 | 65 | 피해 15, 범위 +14 |
| 환도 베기 | 5 | 18 | 0.52 | 88 | 2 | 0 | 0 | 75 | 좌우 연속 베기 2회 |
| 각궁 사격 | 1 | 7 | 1.05 | 420 | 1 | 0 | 0 | 10 | 화살 1발, 피해 7 |
| 각궁 사격 | 2 | 9 | 0.95 | 420 | 1 | 0 | 0 | 10 | 피해 9, 재사용 시간 0.95초 |
| 각궁 사격 | 3 | 10 | 0.95 | 440 | 1 | 1 | 0 | 12 | 관통 +1 |
| 각궁 사격 | 4 | 12 | 0.82 | 460 | 2 | 1 | 0 | 12 | 화살 +1 |
| 각궁 사격 | 5 | 15 | 0.72 | 480 | 2 | 2 | 0 | 15 | 관통 +1, 첫 대상 추가 피해 |
| 부적 투척 | 1 | 8 | 1.40 | 220 | 1 | 0 | 1 | 8 | 연쇄 1회, 원혼 추가 피해 |
| 부적 투척 | 2 | 10 | 1.30 | 230 | 1 | 0 | 2 | 8 | 연쇄 +1 |
| 부적 투척 | 3 | 12 | 1.20 | 240 | 1 | 0 | 3 | 10 | 연쇄 +1, 피해 12 |
| 부적 투척 | 4 | 14 | 1.10 | 255 | 1 | 0 | 4 | 10 | 연쇄 +1, 탐색 범위 +15 |
| 부적 투척 | 5 | 17 | 1.00 | 270 | 2 | 0 | 5 | 12 | 부적 +1, 연쇄 +1 |
| 벽력진천뢰 | 1 | 14 | 2.60 | 70 | 1 | 0 | 0 | 35 | 폭발 범위 70, 피해 14 |
| 벽력진천뢰 | 2 | 18 | 2.40 | 82 | 1 | 0 | 0 | 45 | 폭발 범위 +12 |
| 벽력진천뢰 | 3 | 22 | 2.20 | 94 | 1 | 0 | 0 | 55 | 피해 22, 재사용 시간 2.20초 |
| 벽력진천뢰 | 4 | 26 | 2.00 | 106 | 2 | 0 | 0 | 65 | 폭발 +1 |
| 벽력진천뢰 | 5 | 32 | 1.80 | 120 | 2 | 0 | 0 | 80 | 피해 32, 폭발 범위 120 |

증강은 레벨당 다음 효과를 누적한다. `effectDescriptionForLevel`은 표의 문구를 반환한다.

| 증강 | maxLevel | 레벨당 효과 | 표시 문구 |
| --- | ---: | --- | --- |
| 무예 단련 | 5 | 모든 무기 피해 +12% | 모든 무기 피해 +12% |
| 빠른 발놀림 | 5 | 이동 속도 +8% | 이동 속도 +8% |
| 빠른 장전 | 5 | 공격 재사용 시간 -10% | 공격 재사용 시간 -10% |
| 내공 호흡 | 5 | 최대 체력 +10, 현재 체력 +10 | 최대 체력 +10, 체력 10 회복 |
| 매의 눈 | 5 | 치명타 확률 +5%p | 치명타 확률 +5% |
| 약초 주머니 | 5 | 선택 즉시 체력 12 회복 | 체력 12 회복 |
| 장승의 가호 | 5 | 경험치 획득 반경 +16 | 경험치 획득 반경 +16 |
| 화약 조제 | 5 | 폭발 범위와 투사체 크기 +10% | 폭발 범위와 투사체 크기 +10% |

기존 영구 해금 흐름을 유지하기 위해 빠른 장전과 화약 조제는 `startsUnlocked: false`, 나머지 여섯 종은 `startsUnlocked: true`로 둔다. `firstStageAugmentIds`에는 여덟 종을 모두 포함하되 런의 실제 후보 여부는 기존 영구 해금 집합이 결정한다.

기존 테스트에서 `LevelUpChoice.displayName`을 영어 문자열로 직접 작성한 경우 동일 ID의 새 한국어 이름으로 기대값만 갱신한다. 테스트의 동작 범위나 검증 의미는 바꾸지 않는다.

- [ ] **Step 4: 데이터 테스트 통과 확인**

Run: `flutter test test/game/content_definitions_test.dart`

Expected: PASS

- [ ] **Step 5: 커밋과 푸시**

```powershell
git add lib/game/content test/game/content_definitions_test.dart test/game/level_up_system_test.dart test/game/pixel_survivor_game_loop_test.dart
git commit -m "feat: define first-stage weapon and augment levels"
git push origin codex/pixel-survivor-mvp
```

---

### Task 3: 시간 기반 웨이브 디렉터

**Files:**
- Create: `lib/game/content/wave_definitions.dart`
- Create: `lib/game/systems/wave_director.dart`
- Create: `test/game/wave_director_test.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Delete: `lib/game/systems/spawn_system.dart`
- Delete: `test/game/spawn_system_test.dart`

**Interfaces:**
- Produces: `WaveDirector.tick({required double elapsedSeconds, required double dt, required int activeEnemyCount})`
- Produces: `WaveTickResult.spawnRequests`, `spawnBoss`, `maxActiveEnemies`
- Consumes: `Random` 주입과 `EnemyId`

- [ ] **Step 1: 시간 구간, 상한, 보스 단일 생성 실패 테스트 작성**

```dart
test('wave changes enemy pool and respects active cap', () {
  final director = WaveDirector(random: Random(7));
  final early = director.tick(elapsedSeconds: 30, dt: 1, activeEnemyCount: 0);
  final late = director.tick(elapsedSeconds: 210, dt: 1, activeEnemyCount: 0);
  expect(early.spawnRequests.every((item) => item.enemyId == plagueRatSwarm), isTrue);
  expect(late.spawnRequests.map((item) => item.enemyId), contains(dokkaebi));
  expect(late.spawnRequests.length, lessThanOrEqualTo(late.maxActiveEnemies));
});

test('boss request occurs once at 270 seconds', () {
  final director = WaveDirector(random: Random(1));
  expect(director.tick(elapsedSeconds: 269.9, dt: 0.1, activeEnemyCount: 0).spawnBoss, isFalse);
  expect(director.tick(elapsedSeconds: 270, dt: 0.1, activeEnemyCount: 0).spawnBoss, isTrue);
  expect(director.tick(elapsedSeconds: 271, dt: 1, activeEnemyCount: 0).spawnBoss, isFalse);
});
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/game/wave_director_test.dart`

Expected: `WaveDirector`가 없어 FAIL

- [ ] **Step 3: 웨이브 데이터와 누적 예산 구현**

```dart
class WaveDefinition {
  const WaveDefinition({
    required this.startSecond,
    required this.endSecond,
    required this.enemyWeights,
    required this.spawnsPerSecond,
    required this.groupSize,
    required this.eliteChance,
    required this.maxActiveEnemies,
  });

  final int startSecond;
  final int endSecond;
  final Map<EnemyId, int> enemyWeights;
  final double spawnsPerSecond;
  final int groupSize;
  final double eliteChance;
  final int maxActiveEnemies;
}

class SpawnRequest {
  const SpawnRequest({required this.enemyId, required this.isElite});
  final EnemyId enemyId;
  final bool isElite;
}
```

`WaveDirector`는 `spawnBudget += dt * spawnsPerSecond`를 누적하고, 프레임당 최대 8개와 현재 구간의 동시 적 상한 중 작은 수만 반환한다. 270초를 처음 통과하는 호출에서만 `spawnBoss`를 반환한다.

같은 변경에서 `PixelSurvivorGame`의 `_spawnTimer`, `_spawnCursor`, `_addDebugEnemy`를 제거하고 `WaveDirector.tick`이 반환한 `SpawnRequest`를 기존 `EnemyComponent` 생성으로 연결한다. 보스 요청은 이 단계에서는 횟수만 기록하며 실제 보스 컴포넌트 생성은 Task 8에서 연결한다. 이 임시 연결로 Task 3 커밋 자체가 분석과 전체 테스트를 통과하게 한다.

- [ ] **Step 4: 웨이브 테스트 통과 및 기존 SpawnSystem 참조 제거 확인**

Run: `flutter test test/game/wave_director_test.dart`

Run: `rg "SpawnSystem" lib test`

Run: `flutter test`

Expected: 웨이브와 전체 테스트 PASS, `rg` 결과 없음

- [ ] **Step 5: 커밋과 푸시**

```powershell
git add lib/game/content/wave_definitions.dart lib/game/systems lib/game/pixel_survivor_game.dart test/game
git commit -m "feat: add deterministic five-minute wave director"
git push origin codex/pixel-survivor-mvp
```

---

### Task 4: 적 행동과 접촉 피해 간격

**Files:**
- Create: `lib/game/models/damage_event.dart`
- Create: `lib/game/systems/combat_system.dart`
- Modify: `lib/game/content/ids.dart`
- Modify: `lib/game/content/enemy_definitions.dart`
- Modify: `lib/game/components/enemy_component.dart`
- Modify: `lib/game/components/player_component.dart`
- Create: `test/game/combat_system_test.dart`
- Modify: `test/game/enemy_component_test.dart`

**Interfaces:**
- Produces: `EnemyBehaviorType { chase, swarm, dash, tank }`
- Produces: `CombatSystem.applyContactDamage(...)`
- Produces: `EnemyComponent.applyKnockback(Vector2 impulse)`와 `isElite`

- [ ] **Step 1: 접촉 무적 시간, 돌진, 정예 배율 실패 테스트 작성**

```dart
test('same enemy cannot deal contact damage during cooldown', () {
  final combat = CombatSystem();
  final player = PlayerComponent(
    slotIndex: 0,
    maxHealth: 100,
    moveSpeed: 80,
    position: Vector2.zero(),
  );
  final enemy = EnemyComponent(
    enemyId: bandit,
    maxHealth: 18,
    moveSpeed: 0,
    damage: 8,
    position: Vector2.zero(),
  );
  expect(combat.applyContactDamage(player: player, enemy: enemy, now: 1), isTrue);
  expect(combat.applyContactDamage(player: player, enemy: enemy, now: 1.2), isFalse);
  expect(combat.applyContactDamage(player: player, enemy: enemy, now: 1.6), isTrue);
});

test('elite enemy scales health damage size and experience', () {
  final definition = enemyDefinitions.singleWhere((item) => item.id == bandit);
  final enemy = EnemyComponent.fromDefinition(definition, isElite: true);
  expect(enemy.maxHealth, definition.maxHealth * 2.5);
  expect(enemy.damage, definition.damage * 1.4);
  expect(enemy.experienceValue, definition.experience * 3);
  expect(enemy.size.x, greaterThan(18));
});
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/game/combat_system_test.dart test/game/enemy_component_test.dart`

Expected: 접촉 피해 게이트와 적 행동 API가 없어 FAIL

- [ ] **Step 3: 적 행동과 전투 게이트 구현**

```dart
class CombatSystem {
  static const contactCooldownSeconds = 0.5;
  final Map<EnemyComponent, double> _nextContactAt = {};

  bool applyContactDamage({
    required PlayerComponent player,
    required EnemyComponent enemy,
    required double now,
  }) {
    if (now < (_nextContactAt[enemy] ?? 0) || !enemy.overlapsPlayer(player)) {
      return false;
    }
    player.takeDamage(enemy.damage);
    _nextContactAt[enemy] = now + contactCooldownSeconds;
    return true;
  }

  void forget(EnemyComponent enemy) => _nextContactAt.remove(enemy);
  void reset() => _nextContactAt.clear();
}
```

원혼은 2.4초 추적 후 0.35초 돌진, 도깨비는 넉백 70% 감소, 역병쥐는 같은 종류끼리 약간 퍼지는 이동을 적용한다. `EnemyComponent`는 피격 점멸 시간과 감쇠되는 넉백 속도를 관리한다.

- [ ] **Step 4: 전투 및 적 컴포넌트 테스트 통과 확인**

Run: `flutter test test/game/combat_system_test.dart test/game/enemy_component_test.dart`

Expected: PASS

- [ ] **Step 5: 커밋과 푸시**

```powershell
git add lib/game/models/damage_event.dart lib/game/systems/combat_system.dart lib/game/content lib/game/components test/game
git commit -m "feat: add distinct enemy behaviors and contact damage gating"
git push origin codex/pixel-survivor-mvp
```

---

### Task 5: 네 무기의 구별되는 공격

**Files:**
- Create: `lib/game/components/melee_arc_component.dart`
- Create: `lib/game/components/area_attack_component.dart`
- Modify: `lib/game/components/projectile_component.dart`
- Modify: `lib/game/systems/weapon_system.dart`
- Modify: `test/game/weapon_system_test.dart`

**Interfaces:**
- Produces: `WeaponTickResult.damageEvents`, `projectiles`, `meleeArcs`, `areaAttacks`
- Produces: `ProjectileComponent.remainingPierces`와 `registerHit(EnemyComponent)`
- Consumes: `weaponLevelFor`, `DamageEvent`, 적 목록, 공격 속도·치명타·크기 배율

- [ ] **Step 1: 무기별 행동 실패 테스트 작성**

```dart
test('level five hwando creates two arc attacks with knockback', () {
  final enemy = EnemyComponent(
    enemyId: bandit,
    maxHealth: 100,
    moveSpeed: 0,
    damage: 1,
    position: Vector2(20, 0),
  );
  final result = WeaponSystem(
    initialLevels: const {hwandoSlash: 5},
    random: Random(1),
  ).tick(dt: 1, origin: Vector2.zero(), enemies: [enemy]);
  expect(result.meleeArcs, hasLength(2));
  expect(result.damageEvents.every((event) => event.knockback > 0), isTrue);
});

test('gakgung projectile pierces configured targets once each', () {
  final projectile = ProjectileComponent(
    weaponId: gakgungShot,
    damage: 10,
    position: Vector2.zero(),
    velocity: Vector2(100, 0),
    pierce: 2,
  );
  final enemyA = EnemyComponent(enemyId: bandit, maxHealth: 10, moveSpeed: 0, damage: 1);
  final enemyB = EnemyComponent(enemyId: bandit, maxHealth: 10, moveSpeed: 0, damage: 1);
  final enemyC = EnemyComponent(enemyId: bandit, maxHealth: 10, moveSpeed: 0, damage: 1);
  expect(projectile.registerHit(enemyA), isTrue);
  expect(projectile.registerHit(enemyA), isFalse);
  expect(projectile.registerHit(enemyB), isTrue);
  expect(projectile.isSpent, isFalse);
  expect(projectile.registerHit(enemyC), isTrue);
  expect(projectile.isSpent, isTrue);
});

test('talisman chains to unique nearby targets', () {
  final enemies = List.generate(
    3,
    (index) => EnemyComponent(
      enemyId: vengefulSpirit,
      maxHealth: 20,
      moveSpeed: 0,
      damage: 1,
      position: Vector2(20.0 + index * 15, 0),
    ),
  );
  final result = WeaponSystem(
    initialLevels: const {talismanThrow: 3},
    random: Random(1),
  ).tick(dt: 2, origin: Vector2.zero(), enemies: enemies);
  expect(result.damageEvents.map((event) => event.target).toSet(), hasLength(3));
});

test('bomb creates delayed area attack instead of immediate damage', () {
  final enemy = EnemyComponent(
    enemyId: bandit,
    maxHealth: 20,
    moveSpeed: 0,
    damage: 1,
    position: Vector2(20, 0),
  );
  final result = WeaponSystem(
    initialLevels: const {thunderCrashBomb: 1},
    random: Random(1),
  ).tick(dt: 3, origin: Vector2.zero(), enemies: [enemy]);
  expect(result.areaAttacks.single.delaySeconds, greaterThan(0));
  expect(result.damageEvents, isEmpty);
});
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/game/weapon_system_test.dart`

Expected: 새 공격 결과와 관통 API가 없어 FAIL

- [ ] **Step 3: 공격 결과와 컴포넌트 구현**

```dart
class WeaponTickResult {
  const WeaponTickResult({
    this.damageEvents = const [],
    this.projectiles = const [],
    this.meleeArcs = const [],
    this.areaAttacks = const [],
  });

  final List<DamageEvent> damageEvents;
  final List<ProjectileComponent> projectiles;
  final List<MeleeArcComponent> meleeArcs;
  final List<AreaAttackComponent> areaAttacks;
}
```

환도는 부채꼴 각도 안의 적을 판정하고, 각궁은 투사체마다 관통 횟수와 이미 맞은 적 집합을 관리한다. 부적은 거리순으로 고유 대상을 연쇄한다. 벽력진천뢰는 0.65초 경고 뒤 한 번 피해를 주고 제거되는 `AreaAttackComponent`를 만든다.

- [ ] **Step 4: 무기 및 투사체 테스트 통과 확인**

Run: `flutter test test/game/weapon_system_test.dart`

Expected: PASS

- [ ] **Step 5: 커밋과 푸시**

```powershell
git add lib/game/components lib/game/systems/weapon_system.dart test/game/weapon_system_test.dart
git commit -m "feat: implement four distinct Joseon weapons"
git push origin codex/pixel-survivor-mvp
```

---

### Task 6: 증강 효과와 레벨업 선택

**Files:**
- Modify: `lib/game/systems/level_up_system.dart`
- Modify: `lib/game/systems/run_progression_system.dart`
- Modify: `lib/game/components/player_component.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `test/game/level_up_system_test.dart`
- Modify: `test/game/run_progression_system_test.dart`
- Modify: `test/game/player_component_test.dart`

**Interfaces:**
- Produces: `LevelUpChoice.effectDescription`
- Produces: `LevelUpSystem({Random? random})`의 무기·증강 혼합 선택
- Produces: 최대 체력 증가, 회복, 획득 반경, 치명타, 공격 속도 배율

- [ ] **Step 1: 혼합 선택, 설명, 5분 경험치 곡선 실패 테스트 작성**

```dart
test('choices mix weapon and augment when both are available', () {
  final choices = LevelUpSystem(random: Random(2)).choices(
    unlockedWeaponIds: {hwandoSlash, gakgungShot},
    unlockedAugmentIds: {martialTraining, quickStep},
    currentWeaponLevels: {hwandoSlash: 1},
    currentAugmentLevels: const {},
  );
  expect(choices, hasLength(3));
  expect(choices.map((choice) => choice.type).toSet(), hasLength(2));
  expect(choices.every((choice) => choice.effectDescription.isNotEmpty), isTrue);
});

test('representative five-minute experience reaches 8 to 12 upgrades', () {
  final system = RunProgressionSystem();
  var upgrades = 0;
  for (var i = 0; i < 85; i += 1) {
    if (system.addExperience(1)) upgrades += 1;
  }
  expect(system.experienceRequiredForLevel(1), 5);
  expect(system.experienceRequiredForLevel(10), 14);
  expect(upgrades, 9);
});
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/game/level_up_system_test.dart test/game/run_progression_system_test.dart test/game/player_component_test.dart`

Expected: 설명, 난수 혼합, 새 증강 효과가 없어 FAIL

- [ ] **Step 3: 선택 알고리즘과 여덟 효과 구현**

```dart
class LevelUpChoice {
  const LevelUpChoice({
    required this.id,
    required this.displayName,
    required this.effectDescription,
    required this.type,
    required this.currentLevel,
    required this.nextLevel,
  });

  final String id;
  final String displayName;
  final String effectDescription;
  final LevelUpChoiceType type;
  final int currentLevel;
  final int nextLevel;
}
```

후보를 무기와 증강으로 나눈 뒤 각각 섞고, 두 종류가 모두 있으면 최소 한 장씩 포함한 후 세 장을 채운다. 증강 적용 결과는 `PixelSurvivorGame`의 읽기 전용 배율 getter로 모으고 체력 증가와 즉시 회복은 선택 순간 한 번만 적용한다.

경험치 요구량은 `4 + level`로 정의한다. 레벨 1에서 5 경험치로 시작하고 레벨 10에서 14 경험치를 요구해 대표적인 85 경험치 획득 시 정확히 9회 성장한다.

- [ ] **Step 4: 레벨업과 플레이어 효과 테스트 통과 확인**

Run: `flutter test test/game/level_up_system_test.dart test/game/run_progression_system_test.dart test/game/player_component_test.dart`

Expected: PASS

- [ ] **Step 5: 커밋과 푸시**

```powershell
git add lib/game/systems lib/game/components/player_component.dart lib/game/pixel_survivor_game.dart test/game
git commit -m "feat: complete first-stage augments and level-up choices"
git push origin codex/pixel-survivor-mvp
```

---

### Task 7: 보스 상태와 패턴

**Files:**
- Create: `lib/game/systems/boss_controller.dart`
- Create: `lib/game/components/boss_component.dart`
- Modify: `lib/game/components/area_attack_component.dart`
- Create: `test/game/boss_controller_test.dart`

**Interfaces:**
- Produces: `BossPhase { approach, charge, coneSlash, summon, enraged, defeated }`
- Produces: `BossController.tick({required double dt, required double healthFraction})`
- Produces: `BossAction` 값으로 이동, 경고, 소환 요청

- [ ] **Step 1: 패턴 순서, 체력 전환, 광폭화 실패 테스트 작성**

```dart
test('boss cycles charge and cone slash with telegraphs', () {
  final controller = BossController();
  final actions = <BossAction>[];
  for (var i = 0; i < 80; i += 1) {
    actions.addAll(controller.tick(dt: 0.1, healthFraction: 1));
  }
  expect(actions.any((action) => action.type == BossActionType.chargeWarning), isTrue);
  expect(actions.any((action) => action.type == BossActionType.coneWarning), isTrue);
});

test('boss summons below forty percent and enrages after sixty seconds', () {
  final controller = BossController();
  expect(controller.tick(dt: 0.1, healthFraction: 0.39).any((a) => a.type == BossActionType.summon), isTrue);
  controller.tick(dt: 60, healthFraction: 0.39);
  expect(controller.isEnraged, isTrue);
});
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/game/boss_controller_test.dart`

Expected: 보스 제어기가 없어 FAIL

- [ ] **Step 3: 순수 상태 제어기와 실행 컴포넌트 구현**

```dart
enum BossActionType { chargeWarning, charge, coneWarning, coneDamage, summon }

class BossAction {
  const BossAction({required this.type});
  final BossActionType type;
}
```

`BossController`는 경고와 실제 공격을 별도 액션으로 반환한다. `BossComponent`는 액션을 받아 돌진 속도, 부채꼴 `AreaAttackComponent`, 원혼 소환 요청을 실행한다. 40% 이하 소환은 한 번만 발생하고 60초 광폭화는 이동 및 패턴 시간 배율 1.35를 적용한다.

- [ ] **Step 4: 보스 제어 테스트 통과 확인**

Run: `flutter test test/game/boss_controller_test.dart`

Expected: PASS

- [ ] **Step 5: 커밋과 푸시**

```powershell
git add lib/game/systems/boss_controller.dart lib/game/components/boss_component.dart lib/game/components/area_attack_component.dart test/game/boss_controller_test.dart
git commit -m "feat: add fallen captain boss encounter"
git push origin codex/pixel-survivor-mvp
```

---

### Task 8: 게임 루프 통합과 승패 우선순위

**Files:**
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `lib/game/systems/run_stats_tracker.dart`
- Modify: `test/game/pixel_survivor_game_loop_test.dart`
- Create: `test/game/five_minute_run_simulation_test.dart`

**Interfaces:**
- Consumes: `WaveDirector`, `CombatSystem`, `WeaponSystem`, `BossComponent`, `RunOutcome`
- Produces: `bossHealthFraction`, `bossName`, `weaponLevelLabels`, `runOutcome`
- Produces: 승리·패배 콜백 단일 호출

- [ ] **Step 1: 보스 단일 생성, 동시 사망 우선순위, 콜백 단일 호출 실패 테스트 작성**

```dart
test('boss spawns once and its defeat wins the run', () async {
  RunResult? ended;
  final game = PixelSurvivorGame(
    playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
    random: Random(1),
    onRunEnded: (result) => ended = result,
  );
  game.onGameResize(Vector2(960, 540));
  await game.onLoad();
  game.debugAdvanceTo(270);
  expect(game.bossSpawnCount, 1);
  game.debugDefeatBossAndPlayerSameFrame();
  expect(ended?.outcome, RunOutcome.victory);
  expect(ended?.bossDefeated, isTrue);
});

test('run end callback fires once', () async {
  var calls = 0;
  final game = PixelSurvivorGame(
    playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
    random: Random(1),
    onRunEnded: (_) => calls += 1,
  );
  game.onGameResize(Vector2(960, 540));
  await game.onLoad();
  game.debugKillPlayer();
  game.update(0.016);
  game.update(0.016);
  expect(calls, 1);
});
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/game/pixel_survivor_game_loop_test.dart test/game/five_minute_run_simulation_test.dart`

Expected: 웨이브, 보스, 명시적 결과 통합이 없어 FAIL

- [ ] **Step 3: 프레임 단계와 런 종료 순서 구현**

```dart
void update(double dt) {
  final safeDt = dt.clamp(0, 0.05).toDouble();
  super.update(safeDt);
  if (runOutcome != RunOutcome.inProgress || isLevelUpPending) return;

  _advanceTime(safeDt);
  _spawnWave(safeDt);
  _updateMovement(safeDt);
  _updateWeapons(safeDt);
  _resolveWeaponHits();
  _resolveDeathsAndDrops();
  _resolveBossVictoryBeforePlayerDefeat();
  _resolveContactDamage();
  _collectExperience();
}
```

`_resolveBossVictoryBeforePlayerDefeat`에서 보스 사망을 먼저 확인한다. 런 종료는 `_finishRun(RunOutcome outcome)` 하나만 통과하며 이미 종료된 경우 즉시 반환한다. 디버그 메서드는 `@visibleForTesting`으로 제한한다.

- [ ] **Step 4: 통합 테스트와 고정 시드 시뮬레이션 통과 확인**

Run: `flutter test test/game/pixel_survivor_game_loop_test.dart test/game/five_minute_run_simulation_test.dart`

Expected: 보스 1회, 적 상한 준수, 콜백 1회, 승리 우선순위 모두 PASS

- [ ] **Step 5: 커밋과 푸시**

```powershell
git add lib/game/pixel_survivor_game.dart lib/game/systems/run_stats_tracker.dart test/game
git commit -m "feat: integrate five-minute single-player run loop"
git push origin codex/pixel-survivor-mvp
```

---

### Task 9: 전투 피드백과 HUD

**Files:**
- Create: `lib/app/game_hud_source.dart`
- Create: `lib/game/components/damage_number_component.dart`
- Modify: `lib/game/components/enemy_component.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `lib/app/game_hud.dart`
- Modify: `lib/app/level_up_overlay.dart`
- Create: `test/app/game_hud_test.dart`
- Modify: `test/game/enemy_component_test.dart`

**Interfaces:**
- Consumes: 게임의 보스 상태, 무기 레벨 목록, `LevelUpChoice.effectDescription`
- Produces: `abstract interface class GameHudSource`
- Produces: 보스 체력바, 네 무기 목록, 피격 점멸, 피해 숫자, 제한된 화면 흔들림

- [ ] **Step 1: HUD와 피드백 실패 테스트 작성**

```dart
testWidgets('hud shows boss bar and all equipped weapons', (tester) async {
  final source = FakeGameHudSource(
    bossName: '타락한 관군 대장',
    bossHealthFraction: 0.5,
    weaponLevelLabels: const ['환도 베기 Lv 3', '각궁 사격 Lv 2'],
  );
  await tester.pumpWidget(MaterialApp(home: GameHud(source: source)));
  expect(find.text('타락한 관군 대장'), findsOneWidget);
  expect(find.text('환도 베기 Lv 3'), findsOneWidget);
  expect(find.text('각궁 사격 Lv 2'), findsOneWidget);
  expect(find.byType(LinearProgressIndicator), findsOneWidget);
});

class FakeGameHudSource implements GameHudSource {
  FakeGameHudSource({
    required this.bossName,
    required this.bossHealthFraction,
    required this.weaponLevelLabels,
  });

  @override final String? bossName;
  @override final double? bossHealthFraction;
  @override final List<String> weaponLevelLabels;
  @override double get elapsedSeconds => 275;
  @override String get playerHealthLabel => '80/100';
  @override int get playerLevel => 9;
  @override int get currentExperience => 4;
  @override int get experienceToNextLevel => 12;
  @override int get enemyCount => 20;
  @override int get kills => 88;
  @override void updateMovementInput(VectorInput input) {}
}

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
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/app/game_hud_test.dart test/game/enemy_component_test.dart`

Expected: 보스 HUD와 피드백 상태가 없어 FAIL

- [ ] **Step 3: 가로 화면 HUD와 제한된 효과 구현**

```dart
abstract interface class GameHudSource {
  double get elapsedSeconds;
  String get playerHealthLabel;
  int get playerLevel;
  int get currentExperience;
  int get experienceToNextLevel;
  int get enemyCount;
  int get kills;
  String? get bossName;
  double? get bossHealthFraction;
  List<String> get weaponLevelLabels;
  void updateMovementInput(VectorInput input);
}

if (source.bossHealthFraction case final health?)
  Positioned(
    top: 8,
    left: 160,
    right: 160,
    child: BossHealthBar(name: source.bossName!, healthFraction: health),
  );
```

피해 숫자는 화면에 최대 40개만 유지하고 0.55초 후 제거한다. 화면 흔들림은 폭발과 보스 강공격에만 0.12초 이하, 4픽셀 이하로 적용한다. 레벨업 카드는 이름, 레벨 변화, 효과 설명을 모두 표시하고 긴 한국어 문구는 두 줄에서 말줄임 처리한다.

- [ ] **Step 4: 위젯, 컴포넌트, 전체 회귀 테스트 통과 확인**

Run: `flutter test test/app/game_hud_test.dart test/game/enemy_component_test.dart`

Run: `flutter test`

Expected: 전체 테스트 PASS

- [ ] **Step 5: 커밋과 푸시**

```powershell
git add lib/game/components lib/game/pixel_survivor_game.dart lib/app test
git commit -m "feat: add combat feedback and boss HUD"
git push origin codex/pixel-survivor-mvp
```

---

### Task 10: 결과 화면, QA 문서, 웹·Android 검증

**Files:**
- Modify: `lib/app/run_summary_screen.dart`
- Modify: `test/game/run_summary_progression_test.dart`
- Modify: `docs/testing/manual-qa-test-cases.txt`
- Modify: `docs/testing/local-playtest.md`

**Interfaces:**
- Consumes: `RunResult.outcome`, `bossDefeated`, `weaponLevels`
- Produces: 한국어 승리·패배 결과와 재도전 검증 절차

- [ ] **Step 1: 결과 화면 실패 테스트 작성**

```dart
testWidgets('victory summary shows boss result and final build', (tester) async {
  const result = RunResult(
      outcome: RunOutcome.victory,
      survivalSeconds: 301,
      kills: 96,
      level: 11,
      bossDefeated: true,
      wonWithLowHealth: false,
      weaponKillCounts: {},
      weaponLevels: {hwandoSlash: 5, gakgungShot: 3},
  );
  await tester.pumpWidget(MaterialApp(
    home: RunSummaryScreen(
      result: result,
      unlocks: const ProgressionUnlocks(),
      onStart: () {},
      onMenu: () {},
    ),
  ));
  expect(find.text('승리'), findsOneWidget);
  expect(find.text('보스 처치'), findsOneWidget);
  expect(find.text('환도 베기 Lv 5'), findsOneWidget);
  expect(find.text('각궁 사격 Lv 3'), findsOneWidget);
});
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/game/run_summary_progression_test.dart`

Expected: 한국어 결과와 최종 빌드가 없어 FAIL

- [ ] **Step 3: 결과 화면과 수동 QA 항목 구현**

결과 화면 제목은 `승리` 또는 `패배`로 표시하고 생존 시간, 처치 수, 도달 레벨, 보스 처치, 최종 무기 레벨, 새 해금을 보여준다. 수동 QA 문서에는 30초 단위 웨이브, 네 무기의 각 레벨 변화, 정예, 보스 세 패턴, 270초 단일 등장, 330초 광폭화, 승패 동시 프레임, 재도전 초기화를 별도 사례로 추가한다.

- [ ] **Step 4: 전체 자동 검증 실행**

```powershell
dart analyze
flutter test
flutter build web
flutter build apk --debug
```

Expected: 분석 오류 0개, 모든 테스트 PASS, `build/web` 생성, `build/app/outputs/flutter-apk/app-debug.apk` 생성

- [ ] **Step 5: 브라우저 수동 검증**

Run: `python -m http.server 8765 --bind 127.0.0.1 --directory build/web`

브라우저에서 시작 → 이동 → 네 무기 중 하나 추가 → 레벨업 설명 확인 → 정예 처치 → 4분 30초 보스 등장 → 보스 패턴 세 종류 → 승리 → 재도전까지 확인한다. 브라우저 콘솔 오류가 없어야 한다.

- [ ] **Step 6: 실제 Android 기기 또는 에뮬레이터 검증**

Run:

```powershell
$devices = flutter devices --machine | ConvertFrom-Json
$androidDevice = $devices | Where-Object { $_.targetPlatform -like 'android-*' } | Select-Object -First 1
if ($null -eq $androidDevice) { throw '연결된 Android 기기 또는 실행 중인 에뮬레이터가 없습니다.' }
flutter run -d $androidDevice.id --debug
```

가로 고정, 터치 이동, 레벨업 카드 터치, 5분 플레이, 앱 일시 정지와 복귀를 확인한다. Android SDK 약관이 미동의 상태라면 사용자가 `flutter doctor --android-licenses`에서 직접 동의한 후 실행한다.

- [ ] **Step 7: 최종 커밋과 푸시**

```powershell
git add lib/app/run_summary_screen.dart test/game/run_summary_progression_test.dart docs/testing
git commit -m "docs: complete five-minute run verification"
git push origin codex/pixel-survivor-mvp
git status --short --branch
```

Expected: 작업 트리가 깨끗하고 로컬 브랜치가 `origin/codex/pixel-survivor-mvp`와 동기화됨

---

## Execution Notes

각 Task는 구현 담당 에이전트 한 명과 요구사항 검토, 코드 품질 검토를 분리한다. 같은 파일을 수정하는 Task는 번호 순서대로 실행하고, 독립적인 순수 시스템 테스트는 선행 인터페이스가 커밋된 뒤 병렬 검토할 수 있다. 리뷰에서 발견된 문제는 해당 Task 커밋 위에 수정 커밋을 만들고 푸시한 뒤 다음 Task로 넘어간다.

전체 구현 중 그래픽 에셋은 추가하지 않는다. 도형 기반 시각 피드백으로 5분 전투의 재미와 안정성을 먼저 검증한다.
