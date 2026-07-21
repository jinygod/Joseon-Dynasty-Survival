# Actor Render Sizing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enlarge player and enemy artwork to the approved mobile-readable sizes while preserving every collision and gameplay value.

**Architecture:** Add one `ActorRenderSizes` policy that owns collision and visual sizes. Keep component sizes and `Anchor.center` unchanged, then render only each body around a bottom-center pivot so artwork grows upward without moving feet or scaling attack warnings.

**Tech Stack:** Flutter 3.44.4, Dart 3.12.2, Flame 1.37.0, flutter_test

## Global Constraints

- Player visual size is 54 and collision/component size remains 24.
- Normal enemy visual size is 27 and collision/component size remains 18.
- Elite visual size is 40.5 and collision/component size remains 40.
- Boss visual size is 63 and collision/component size remains 42.
- Do not modify source PNGs, camera zoom, movement, damage, health, spawn counts, AI, collision rules, or animation timing.
- Keep `Anchor.center`; enlarge artwork around the component's bottom-center point.
- Use uniform scaling and `FilterQuality.none` for crisp, undistorted sprites.
- Do not commit implementation changes because the working tree already contains approved uncommitted static-player-art work.

---

### Task 1: Central actor sizing policy

**Files:**
- Create: `lib/game/content/actor_render_sizes.dart`
- Create: `test/game/actor_render_sizes_test.dart`

**Interfaces:**
- Consumes: `EnemyRank` from `lib/game/content/ids.dart`.
- Produces: `ActorRenderSizes.playerCollision`, `playerVisual`, `normalEnemyCollision`, `normalEnemyVisual`, `eliteEnemyCollision`, `eliteEnemyVisual`, `bossCollision`, `bossVisual`, `enemyCollisionSize(EnemyRank)`, `enemyVisualSize(EnemyRank)`, and `enemyVisualScale(EnemyRank)`.

- [ ] **Step 1: Write the failing sizing-policy test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/actor_render_sizes.dart';
import 'package:pixel_survivor/game/content/ids.dart';

void main() {
  test('approved actor visual sizes preserve collision sizes and hierarchy', () {
    expect(ActorRenderSizes.playerCollision, 24);
    expect(ActorRenderSizes.playerVisual, 54);
    expect(ActorRenderSizes.enemyCollisionSize(EnemyRank.normal), 18);
    expect(ActorRenderSizes.enemyVisualSize(EnemyRank.normal), 27);
    expect(ActorRenderSizes.enemyCollisionSize(EnemyRank.elite), 40);
    expect(ActorRenderSizes.enemyVisualSize(EnemyRank.elite), 40.5);
    expect(ActorRenderSizes.enemyCollisionSize(EnemyRank.boss), 42);
    expect(ActorRenderSizes.enemyVisualSize(EnemyRank.boss), 63);
    expect(ActorRenderSizes.eliteEnemyVisual / ActorRenderSizes.normalEnemyVisual, 1.5);
    expect(ActorRenderSizes.bossVisual / ActorRenderSizes.normalEnemyVisual, closeTo(2.333333, 0.00001));
  });
}
```

- [ ] **Step 2: Run the test and verify RED**

Run: `flutter test --no-pub test/game/actor_render_sizes_test.dart`

Expected: compilation fails because `actor_render_sizes.dart` does not exist.

- [ ] **Step 3: Implement the policy**

```dart
import 'ids.dart';

abstract final class ActorRenderSizes {
  static const playerCollision = 24.0;
  static const playerVisual = 54.0;
  static const normalEnemyCollision = 18.0;
  static const normalEnemyVisual = 27.0;
  static const eliteEnemyCollision = 40.0;
  static const eliteEnemyVisual = 40.5;
  static const bossCollision = 42.0;
  static const bossVisual = 63.0;

  static double enemyCollisionSize(EnemyRank rank) => switch (rank) {
    EnemyRank.normal => normalEnemyCollision,
    EnemyRank.elite => eliteEnemyCollision,
    EnemyRank.boss => bossCollision,
  };

  static double enemyVisualSize(EnemyRank rank) => switch (rank) {
    EnemyRank.normal => normalEnemyVisual,
    EnemyRank.elite => eliteEnemyVisual,
    EnemyRank.boss => bossVisual,
  };

  static double enemyVisualScale(EnemyRank rank) =>
      enemyVisualSize(rank) / enemyCollisionSize(rank);
}
```

- [ ] **Step 4: Format and verify GREEN**

Run: `dart format lib/game/content/actor_render_sizes.dart test/game/actor_render_sizes_test.dart && flutter test --no-pub test/game/actor_render_sizes_test.dart`

Expected: the sizing-policy test passes.

### Task 2: Player bottom-centered 54-pixel rendering

**Files:**
- Modify: `lib/game/components/player_component.dart`
- Modify: `test/game/player_component_test.dart`

**Interfaces:**
- Consumes: `ActorRenderSizes.playerCollision` and `ActorRenderSizes.playerVisual`.
- Produces: unchanged 24-pixel `PlayerComponent.size`, 54-pixel `PlayerSpriteSheet.displaySize`, `Anchor.center`, and nearest-neighbor sprite paint.

- [ ] **Step 1: Change the existing player size expectations to RED**

```dart
expect(PlayerSpriteSheet.displaySize, Vector2.all(54));
final player = PlayerComponent(...);
expect(player.size, Vector2.all(24));
expect(player.anchor, Anchor.center);
expect(player.paint.filterQuality, FilterQuality.none);
```

- [ ] **Step 2: Run the focused player test and verify RED**

Run: `flutter test --no-pub test/game/player_component_test.dart`

Expected: fails because the visual size is still 36.

- [ ] **Step 3: Implement player sizing and foot alignment**

Import `actor_render_sizes.dart`, use `ActorRenderSizes.playerCollision` for the default component, use `ActorRenderSizes.playerVisual` for `displaySize`, set `paint.filterQuality = FilterQuality.none`, pass `overridePaint: paint`, and render at:

```dart
position: Vector2(
  (size.x - PlayerSpriteSheet.displaySize.x) / 2,
  size.y - PlayerSpriteSheet.displaySize.y,
),
```

- [ ] **Step 4: Format and verify GREEN**

Run: `dart format lib/game/components/player_component.dart test/game/player_component_test.dart && flutter test --no-pub test/game/player_component_test.dart`

Expected: all player tests pass without changing movement or boundary assertions.

### Task 3: Rank-aware enemy and boss body scaling

**Files:**
- Modify: `lib/game/components/enemy_component.dart`
- Modify: `lib/game/components/boss_component.dart`
- Modify: `test/game/enemy_component_test.dart`
- Modify: `test/game/boss_component_visual_test.dart`

**Interfaces:**
- Consumes: `ActorRenderSizes.enemyCollisionSize`, `enemyVisualSize`, and `enemyVisualScale`.
- Produces: `EnemyComponent.visualSize`, `visualScale`, unchanged component sizes, and bottom-centered body rendering that leaves warnings unscaled.

- [ ] **Step 1: Write failing normal, elite, boss, anchor, and collision assertions**

```dart
expect(normal.size, Vector2.all(18));
expect(normal.visualSize, 27);
expect(normal.visualScale, 1.5);
expect(normal.anchor, Anchor.center);
expect(elite.size, Vector2.all(40));
expect(elite.visualSize, 40.5);
expect(boss.size, Vector2.all(42));
expect(boss.visualSize, 63);
expect(boss.visualScale, 1.5);
```

Keep the existing player-overlap threshold test unchanged to prove the enlarged visuals do not alter contact behavior.

- [ ] **Step 2: Run focused tests and verify RED**

Run: `flutter test --no-pub test/game/enemy_component_test.dart test/game/boss_component_visual_test.dart`

Expected: compilation fails because `visualSize` and `visualScale` do not exist, and the boss still hardcodes its size.

- [ ] **Step 3: Implement rank-aware collision defaults and visual transforms**

Import `actor_render_sizes.dart`. Default `EnemyComponent.size` to `ActorRenderSizes.enemyCollisionSize(rank)`, remove duplicated factory and boss size literals, set `paint.filterQuality = FilterQuality.none`, and expose:

```dart
double get visualSize => ActorRenderSizes.enemyVisualSize(rank);
double get visualScale => visualSize / size.x;
```

In `render`, draw warnings first, then save the canvas, translate to `(size.x / 2, size.y)`, scale uniformly by `visualScale`, translate back, render the animation or fallback body, and restore the canvas. Boss-specific warnings render afterward in `BossComponent.render`, outside the scaled body transform.

- [ ] **Step 4: Format and verify GREEN**

Run: `dart format lib/game/components/enemy_component.dart lib/game/components/boss_component.dart test/game/enemy_component_test.dart test/game/boss_component_visual_test.dart && flutter test --no-pub test/game/actor_render_sizes_test.dart test/game/player_component_test.dart test/game/enemy_component_test.dart test/game/boss_component_visual_test.dart`

Expected: all focused sizing and behavior tests pass.

### Task 4: Full verification and rendered QA

**Files:**
- Verify only; do not modify PNG files or gameplay definitions.

**Interfaces:**
- Consumes: completed render changes.
- Produces: analyzer, test, web-build, Android-debug-build, and mobile visual evidence.

- [ ] **Step 1: Inspect the diff and prove scope**

Run: `git diff --check && git diff --stat && git diff -- lib/game/components lib/game/content/actor_render_sizes.dart`

Expected: only sizing, rendering, and corresponding tests/docs change; no balance definitions or PNG bytes change.

- [ ] **Step 2: Run analysis and the full test suite**

Run through temporary ASCII junctions if needed:

```text
flutter analyze --no-pub
flutter test --no-pub --concurrency=1
```

Expected: no analyzer issues and all tests pass.

- [ ] **Step 3: Build web and Android debug artifacts**

```text
flutter build web --no-pub
flutter build apk --debug --no-pub
```

Expected: both commands exit 0.

- [ ] **Step 4: Run mobile viewport QA**

Launch the web build or web-server, enter combat, and capture the player and representative normal enemies. Exercise movement, then advance or use a test surface that renders an elite and boss. Confirm the visual hierarchy, bottom alignment, crisp aspect ratio, unchanged camera zoom, acceptable dense-wave overlap, and no new console errors.

- [ ] **Step 5: Remove temporary verification resources**

Stop the local server and remove only the verified temporary ASCII junctions and QA logs. Preserve build artifacts requested by the user and every pre-existing working-tree change.
