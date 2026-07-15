# Currency and Rare Drop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 전투 결과에 엽전을 정산하고 정예·보스가 드롭한 혼옥을 월드에서 수거해 즉시 저장하며 결과 화면과 로비에 반영한다.

**Architecture:** 모든 조정값은 `MetaRewardBalance`에 모으고, 순수 계산은 `MetaRewardPolicy`, 저장 직렬화와 중복 방지는 `MetaProgressionService`가 담당한다. Flame 게임은 혼옥 컴포넌트와 보스 사망 후 3초 수거 상태만 관리하며, Flutter 화면은 서비스가 돌려준 `RunSettlement`만 표시한다.

**Tech Stack:** Dart 3, Flutter, Flame, SharedPreferences, flutter_test

## Global Constraints

- 엽전 목표 범위는 일반 패배 평균 80~150개, 보스 승리 평균 180~260개다.
- 혼옥 드롭률은 정예 `0.01`, 보스 `0.25`, 최초 보스 처치는 1개 보장한다.
- 보스 혼옥이 드롭되면 3초간 직접 수거할 수 있고 종료 시 자동 수거한다.
- 혼옥은 저장 성공 후에만 월드에서 제거하며 실패 시 1초 뒤 재시도할 수 있다.
- 밸런스 숫자는 `lib/game/balance/meta_reward_balance.dart`에서만 수정한다.
- 저장 스키마는 미출시 버전 `2`를 유지하고 누락 필드는 안전한 기본값으로 복구한다.
- 로컬 `flutter_tester.exe`의 Windows `0xc0000409` 충돌이 지속되면 정적 분석과 Web/Android 빌드를 필수 검증으로 사용하고 런타임 테스트 미실행을 기록한다.

---

### Task 1: 보상 계산과 런 통계 모델

**Files:**
- Create: `lib/game/balance/meta_reward_balance.dart`
- Create: `lib/game/systems/meta_reward_policy.dart`
- Modify: `lib/game/models/run_result.dart`
- Modify: `lib/game/systems/run_stats_tracker.dart`
- Test: `test/game/meta_reward_policy_test.dart`
- Test: `test/game/run_stats_tracker_test.dart`

**Interfaces:**
- Consumes: `RunResult`
- Produces: `MetaRewardBalance`, `MetaRewardPolicy.coinForRun(RunResult)`, `MetaRewardPolicy.shouldDropSpiritJade(...)`, `RunResult.eliteKills`, `RunResult.spiritJadeCollected`

- [ ] **Step 1: Write the failing policy and tracker tests**

```dart
test('coin formula uses only centralized balance inputs', () {
  final result = runResult(
    survivalSeconds: 100,
    kills: 100,
    eliteKills: 5,
    bossDefeated: true,
  );
  expect(const MetaRewardPolicy().coinForRun(result), 175);
});

test('first boss reward is guaranteed and normal rolls use thresholds', () {
  const policy = MetaRewardPolicy();
  expect(policy.shouldDropSpiritJade(
    isElite: false, isBoss: true,
    firstBossRewardAvailable: true, roll: .99,
  ), isTrue);
  expect(policy.shouldDropSpiritJade(
    isElite: true, isBoss: false,
    firstBossRewardAvailable: false, roll: .009,
  ), isTrue);
  expect(policy.shouldDropSpiritJade(
    isElite: true, isBoss: false,
    firstBossRewardAvailable: false, roll: .01,
  ), isFalse);
});

test('tracks elite kills and collected spirit jade', () {
  final tracker = RunStatsTracker();
  tracker.recordEnemyDefeat(isBoss: false, isElite: true);
  tracker.recordSpiritJadeCollected();
  final result = tracker.toRunResult(
    outcome: RunOutcome.defeat,
    survivalSeconds: 30,
    level: 2,
    wonWithLowHealth: false,
    weaponLevels: const {},
  );
  expect(result.eliteKills, 1);
  expect(result.spiritJadeCollected, 1);
});
```

- [ ] **Step 2: Verify the new tests fail at compile time**

Run: `dart analyze test/game/meta_reward_policy_test.dart test/game/run_stats_tracker_test.dart`

Expected: FAIL because `MetaRewardPolicy`, `eliteKills`, and `recordSpiritJadeCollected` do not exist.

- [ ] **Step 3: Add centralized constants, pure policy, and compatible model fields**

```dart
abstract final class MetaRewardBalance {
  static const participationCoin = 20;
  static const coinPerSurvivalSecond = 0.35;
  static const coinPerKill = 0.4;
  static const coinPerEliteKill = 4;
  static const bossDefeatCoin = 60;
  static const eliteSpiritJadeDropChance = 0.01;
  static const bossSpiritJadeDropChance = 0.25;
  static const spiritJadePerDrop = 1;
  static const bossRewardCollectionSeconds = 3.0;
  static const failedPickupRetrySeconds = 1.0;
}

class MetaRewardPolicy {
  const MetaRewardPolicy();
  int coinForRun(RunResult result) => (
    MetaRewardBalance.participationCoin +
    result.survivalSeconds * MetaRewardBalance.coinPerSurvivalSecond +
    result.kills * MetaRewardBalance.coinPerKill +
    result.eliteKills * MetaRewardBalance.coinPerEliteKill +
    (result.bossDefeated ? MetaRewardBalance.bossDefeatCoin : 0)
  ).floor();

  bool shouldDropSpiritJade({
    required bool isElite,
    required bool isBoss,
    required bool firstBossRewardAvailable,
    required double roll,
  }) {
    if (isBoss && firstBossRewardAvailable) return true;
    if (isBoss) return roll < MetaRewardBalance.bossSpiritJadeDropChance;
    return isElite && roll < MetaRewardBalance.eliteSpiritJadeDropChance;
  }
}
```

Add optional `eliteKills = 0` and `spiritJadeCollected = 0` to `RunResult`; increment both in `RunStatsTracker`, and pass `isElite` into `recordEnemyDefeat` with default `false` for source compatibility.

- [ ] **Step 4: Run focused static verification**

Run: `dart analyze lib/game/balance/meta_reward_balance.dart lib/game/systems/meta_reward_policy.dart lib/game/models/run_result.dart lib/game/systems/run_stats_tracker.dart test/game/meta_reward_policy_test.dart test/game/run_stats_tracker_test.dart`

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/game/balance/meta_reward_balance.dart lib/game/systems/meta_reward_policy.dart lib/game/models/run_result.dart lib/game/systems/run_stats_tracker.dart test/game/meta_reward_policy_test.dart test/game/run_stats_tracker_test.dart
git commit -m "feat: add centralized meta reward policy"
```

### Task 2: 저장 가능한 보상 수령 이력과 직렬화 서비스

**Files:**
- Modify: `lib/game/systems/save_system.dart`
- Create: `lib/game/systems/meta_progression_service.dart`
- Test: `test/game/save_system_test.dart`
- Test: `test/game/meta_progression_service_test.dart`

**Interfaces:**
- Consumes: `SaveStore`, `ProgressionSystem.applyRunResult`, `MetaRewardPolicy.coinForRun`
- Produces: `SaveState.claimedRewardIds`, `MetaProgressionService.firstBossRewardId`, `loadFirstBossRewardAvailability()`, `collectSpiritJade(...)`, `settleRun(...)`, `RunSettlement`

- [ ] **Step 1: Write failing migration, duplicate pickup, and settlement tests**

```dart
test('missing claimed reward ids recover as empty without schema bump', () {
  final state = SaveState.fromJson({'schemaVersion': 2});
  expect(state.schemaVersion, 2);
  expect(state.claimedRewardIds, isEmpty);
});

test('same pickup id is persisted only once', () async {
  final store = MemorySaveStore(SaveState.defaults());
  final service = MetaProgressionService(saveStore: store);
  expect(await service.collectSpiritJade(pickupId: 'drop-1'), isTrue);
  expect(await service.collectSpiritJade(pickupId: 'drop-1'), isFalse);
  expect((await store.load()).wallet.spiritJade, 1);
});

test('settlement adds coin while preserving collected jade', () async {
  final store = MemorySaveStore(SaveState.defaults().copyWith(
    wallet: const Wallet(coin: 10, spiritJade: 2),
  ));
  final service = MetaProgressionService(saveStore: store);
  final settlement = await service.settleRun(runResult());
  expect(settlement.after.wallet.coin, 10 + settlement.coinEarned);
  expect(settlement.after.wallet.spiritJade, 2);
});
```

- [ ] **Step 2: Verify tests fail at compile time**

Run: `dart analyze test/game/save_system_test.dart test/game/meta_progression_service_test.dart`

Expected: FAIL because reward receipt storage and the service do not exist.

- [ ] **Step 3: Add the save field and serialized service**

```dart
class RunSettlement {
  const RunSettlement({
    required this.before,
    required this.after,
    required this.coinEarned,
  });
  final SaveState before;
  final SaveState after;
  final int coinEarned;
  int get spiritJadeEarned =>
      after.wallet.spiritJade - before.wallet.spiritJade;
}

class MetaProgressionService {
  MetaProgressionService({
    required this.saveStore,
    this.policy = const MetaRewardPolicy(),
    this.progression = const ProgressionSystem(),
  });
  static const firstBossRewardId = 'first_boss_spirit_jade';
  final SaveStore saveStore;
  final MetaRewardPolicy policy;
  final ProgressionSystem progression;
  Future<void> _tail = Future.value();

  Future<T> _serialize<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (_, __) {});
    return result;
  }
}
```

Implement each operation inside `_serialize`: load the latest state, reject an existing pickup ID, add one jade and optional first-boss ID, save, then return success. Settlement loads latest state, applies progression, adds `coinForRun`, saves once, and returns before/after snapshots. Include `claimedRewardIds` in constructor, defaults, JSON, and `copyWith` while keeping schema 2.

- [ ] **Step 4: Run focused static verification**

Run: `dart analyze lib/game/systems/save_system.dart lib/game/systems/meta_progression_service.dart test/game/save_system_test.dart test/game/meta_progression_service_test.dart`

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/game/systems/save_system.dart lib/game/systems/meta_progression_service.dart test/game/save_system_test.dart test/game/meta_progression_service_test.dart
git commit -m "feat: persist serialized meta rewards"
```

### Task 3: 월드 혼옥 드롭과 저장 후 제거

**Files:**
- Modify: `lib/game/content/asset_catalog.dart`
- Create: `lib/game/components/spirit_jade_component.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Test: `test/game/spirit_jade_component_test.dart`
- Test: `test/game/pixel_survivor_game_loop_test.dart`

**Interfaces:**
- Consumes: `MetaRewardPolicy.shouldDropSpiritJade`, `MetaProgressionService.collectSpiritJade`, player pickup radius
- Produces: `AssetCatalog.effects['spirit_jade']`, `SpiritJadeComponent`, enemy-death drop creation, `RunStatsTracker.recordSpiritJadeCollected()`

- [ ] **Step 1: Write failing component and game drop tests**

```dart
test('pickup remains pending until persistence succeeds', () async {
  var attempts = 0;
  final jade = SpiritJadeComponent(
    pickupId: 'jade-1',
    position: Vector2.zero(),
    persistPickup: (_) async => ++attempts > 1,
  );
  expect(await jade.tryCollect(), isFalse);
  expect(jade.isRemoving, isFalse);
  jade.makeRetryAvailableForTest();
  expect(await jade.tryCollect(), isTrue);
  expect(attempts, 2);
});

test('elite defeat passes elite flag and can spawn a jade drop', () async {
  final game = createGame(rewardRoll: () => 0);
  final elite = await addDefeatedElite(game);
  game.processDefeatedEnemiesForTest();
  expect(game.children.whereType<SpiritJadeComponent>(), isNotEmpty);
  expect(game.runStats.eliteKills, 1);
});
```

- [ ] **Step 2: Verify tests fail at compile time**

Run: `dart analyze test/game/spirit_jade_component_test.dart test/game/pixel_survivor_game_loop_test.dart`

Expected: FAIL because the jade component and injectable reward roll do not exist.

- [ ] **Step 3: Implement the jade component and death drop hook**

```dart
typedef SpiritJadePersistence = Future<bool> Function(
  SpiritJadePickup pickup,
);

class SpiritJadePickup {
  const SpiritJadePickup({
    required this.pickupId,
    required this.claimsFirstBossReward,
  });
  final String pickupId;
  final bool claimsFirstBossReward;
}
```

`SpiritJadeComponent` loads `effects/spirit_jade`, checks distance against the player's effective pickup radius, sets a pending pulse while awaiting persistence, removes itself only on `true`, and re-enables collection after `MetaRewardBalance.failedPickupRetrySeconds` on failure. Register `spirit_jade` in `AssetCatalog` using the current experience gem image. In `_recordEnemyDefeat`, pass `enemy.isElite`, make one injected reward roll, and spawn one uniquely identified component when the policy says to drop. On successful collection call `runStats.recordSpiritJadeCollected()`.

- [ ] **Step 4: Run focused static verification**

Run: `dart analyze lib/game/content/asset_catalog.dart lib/game/components/spirit_jade_component.dart lib/game/pixel_survivor_game.dart test/game/spirit_jade_component_test.dart test/game/pixel_survivor_game_loop_test.dart`

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/game/content/asset_catalog.dart lib/game/components/spirit_jade_component.dart lib/game/pixel_survivor_game.dart test/game/spirit_jade_component_test.dart test/game/pixel_survivor_game_loop_test.dart
git commit -m "feat: drop and persist collectible spirit jade"
```

### Task 4: 보스 처치 후 3초 보상 수거 상태

**Files:**
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `lib/app/game_hud_source.dart`
- Modify: `lib/app/game_hud.dart`
- Test: `test/game/pixel_survivor_game_loop_test.dart`
- Test: `test/app/game_hud_test.dart`

**Interfaces:**
- Consumes: boss jade components and `MetaRewardBalance.bossRewardCollectionSeconds`
- Produces: `rewardCollectionSecondsRemaining`, hazard clearing, damage suppression, automatic boss-jade collection before victory

- [ ] **Step 1: Write failing state transition and HUD tests**

```dart
test('boss jade delays victory, disables danger, and auto-collects', () async {
  final game = createGameWithBossJade();
  game.killBossForTest();
  expect(game.rewardCollectionSecondsRemaining, 3);
  expect(game.runEnded, isFalse);
  expect(game.enemyCount, 0);
  await game.advanceRewardCollectionForTest(3);
  expect(game.runStats.spiritJadeCollected, 1);
  expect(game.runEnded, isTrue);
});

testWidgets('shows reward collection countdown', (tester) async {
  await tester.pumpWidget(hudWithRewardCollection(seconds: 2));
  expect(find.text('혼옥 수거 2초'), findsOneWidget);
});
```

- [ ] **Step 2: Verify tests fail at compile time**

Run: `dart analyze test/game/pixel_survivor_game_loop_test.dart test/app/game_hud_test.dart`

Expected: FAIL because reward-collection state is not exposed.

- [ ] **Step 3: Implement reward collection state**

Add a nullable countdown to `PixelSurvivorGame`. When the boss dies and a boss jade exists, remove living enemies, hostile projectiles, and boss attacks; stop spawning and player damage while retaining player movement. Decrement the timer in `update`, call `tryCollect()` on remaining boss jade at zero, retry failed persistence every configured second, and call `_finishRun(RunOutcome.victory)` only after all boss jade saves succeed. Expose the rounded-up countdown through `GameHudSource` and render `혼옥 수거 N초` plus `혼옥 저장 재시도 중` when applicable.

- [ ] **Step 4: Run focused static verification**

Run: `dart analyze lib/game/pixel_survivor_game.dart lib/app/game_hud_source.dart lib/app/game_hud.dart test/game/pixel_survivor_game_loop_test.dart test/app/game_hud_test.dart`

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/game/pixel_survivor_game.dart lib/app/game_hud_source.dart lib/app/game_hud.dart test/game/pixel_survivor_game_loop_test.dart test/app/game_hud_test.dart
git commit -m "feat: add boss reward collection phase"
```

### Task 5: 결과 정산 UI와 로비 새로고침

**Files:**
- Modify: `lib/app/game_screen.dart`
- Modify: `lib/app/run_summary_screen.dart`
- Modify: `lib/app/lobby_screen.dart`
- Test: `test/game/run_summary_progression_test.dart`
- Test: `test/app/lobby_screen_test.dart`

**Interfaces:**
- Consumes: `MetaProgressionService.settleRun`, `RunSettlement`
- Produces: result reward section, settlement retry state, post-run `LobbyController.load()`

- [ ] **Step 1: Write failing summary and lobby reload tests**

```dart
testWidgets('summary displays earned coin and jade', (tester) async {
  await tester.pumpWidget(summary(
    settlement: settlement(coinEarned: 123, spiritJadeEarned: 1),
  ));
  expect(find.text('이번 판 보상'), findsOneWidget);
  expect(find.text('엽전 +123'), findsOneWidget);
  expect(find.text('혼옥 +1'), findsOneWidget);
});

testWidgets('return from game reloads lobby wallet', (tester) async {
  final store = CountingSaveStore();
  await tester.pumpWidget(lobby(store: store));
  await enterAndReturnFromGame(tester);
  expect(store.loadCount, greaterThanOrEqualTo(2));
});
```

- [ ] **Step 2: Verify tests fail at compile time or assertion time**

Run: `dart analyze test/game/run_summary_progression_test.dart test/app/lobby_screen_test.dart`

Expected: FAIL because `RunSummaryScreen` does not accept a settlement and `_deploy` does not reload.

- [ ] **Step 3: Replace direct save logic with the service and render rewards**

Inject or create one shared `MetaProgressionService` for the game run. Pass its collection callback into `PixelSurvivorGame`; in `_handleRunEnded`, await `settleRun`, then navigate with the returned settlement. While a settlement save fails, keep the game screen, show `보상 저장에 실패했습니다` and a `다시 시도` action using the same result. `RunSummaryScreen` renders the reward section and uses the settlement snapshots for unlock comparisons. After the game route returns, call `await widget.controller.load()` before clearing `_launching` so the header wallet is current.

- [ ] **Step 4: Run focused static verification**

Run: `dart analyze lib/app/game_screen.dart lib/app/run_summary_screen.dart lib/app/lobby_screen.dart test/game/run_summary_progression_test.dart test/app/lobby_screen_test.dart`

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/app/game_screen.dart lib/app/run_summary_screen.dart lib/app/lobby_screen.dart test/game/run_summary_progression_test.dart test/app/lobby_screen_test.dart
git commit -m "feat: settle and display run rewards"
```

### Task 6: 전체 정적·빌드 검증과 기록

**Files:**
- Create: `docs/superpowers/verification/2026-07-16-currency-rare-drop.md`

**Interfaces:**
- Consumes: completed reward feature
- Produces: reproducible verification record

- [ ] **Step 1: Run formatting and diff checks**

Run: `dart format lib test && git diff --check`

Expected: formatter succeeds and `git diff --check` prints nothing.

- [ ] **Step 2: Attempt the smallest relevant runtime tests once**

Run: `flutter test test/game/meta_reward_policy_test.dart test/game/meta_progression_service_test.dart test/game/spirit_jade_component_test.dart test/game/run_summary_progression_test.dart`

Expected: PASS, or the known Windows process termination `0xc0000409`; do not repeatedly rerun the crashing runner.

- [ ] **Step 3: Run mandatory analysis and builds**

Run: `dart analyze`

Expected: `No issues found!`

Run: `flutter build web`

Expected: exits 0 and creates `build/web`.

Run: `$env:PUB_CACHE='C:\codex-pub-cache'; flutter build apk --debug`

Expected: exits 0 and creates `build/app/outputs/flutter-apk/app-debug.apk`.

- [ ] **Step 4: Record exact commands and outcomes**

Create `docs/superpowers/verification/2026-07-16-currency-rare-drop.md` with the branch name, commit range, successful analysis/build results, and either passing focused tests or the exact `flutter_tester.exe` crash limitation.

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/verification/2026-07-16-currency-rare-drop.md
git commit -m "docs: record currency reward verification"
```
