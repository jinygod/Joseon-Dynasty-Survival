# Balanced Casual Art Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 퇴마 검객 1종, 핵심 적 4종, 밝은 조선 전장, 축소 HUD, 환도·부적·봉마참 표현을 완성해 모바일에서 읽히는 균형형 캐주얼 전투 화면을 만든다.

**Architecture:** 콘텐츠 ID와 저장 데이터는 유지하고, 새 아트 규격은 `ActorVisualSpec`과 4×4 아틀라스 계약으로 분리한다. 게임 상태가 애니메이션 상태를 결정하고 `AttackSpec`·`AttackGeometry`가 피해와 이펙트의 단일 기하 데이터가 된다. 배경·HUD·경고·공격 프레젠테이션은 피해 로직을 소유하지 않는 독립 렌더 계층으로 유지한다.

**Tech Stack:** Flutter 3.44, Dart 3.12, Flame, `flutter_test`, Flame component tests, golden tests, OpenAI image generation, PNG RGBA sprite atlases.

## Global Constraints

- 기준 화면은 390×844 세로 화면이다.
- 플레이어 시각 크기 56, 쥐떼 32, 원혼·삿갓 망령 40, 도깨비 44를 사용한다.
- 플레이어 충돌 크기 24와 일반 적 충돌 크기 18은 변경하지 않는다.
- 대표 아틀라스는 128×128 프레임, 4열×4행, 전체 512×512 RGBA PNG다.
- 프레임 0~3 이동, 4~7 공격, 8~9 피격, 10~15 사망 순서를 공통 사용한다.
- 후반 화면 평균 30~55마리, 순간 최대 약 60마리를 목표로 하고 전역 적 상한 96을 유지한다.
- 아트나 UI가 `AttackSpec`·`AttackGeometry`와 별도의 피해 범위를 소유하면 안 된다.
- `exorcist_dosa`, 적 4종과 무기 ID를 변경하지 않고 기존 저장 데이터를 삭제하지 않는다.
- 특정 상용 게임의 캐릭터, UI, 아이콘, 이펙트, 팔레트를 복제하지 않는다.
- 대표 세트 검증 전 나머지 플레이어 2종과 적 9종을 제작하지 않는다.

---

### Task 1: 대표 아트 브리프와 권리 기록

**Files:**
- Create: `docs/assets/prompts/balanced-casual-representative-set.md`
- Create: `source_assets/representative_set/exorcist_dosa_lineup.png`
- Create: `source_assets/representative_set/enemy_role_lineup.png`
- Modify: `docs/assets/asset-rights-ledger.csv`
- Test: `test/game/art_style_guide_test.dart`

**Interfaces:**
- Consumes: `docs/superpowers/specs/2026-07-22-balanced-casual-art-overhaul-design.md`
- Produces: 승인 기준이 되는 플레이어·적 라인업 이미지와 재사용 가능한 정확한 생성 프롬프트.

- [ ] **Step 1: 브리프 계약의 실패 테스트 작성**

```dart
test('representative art brief locks the approved lineup', () {
  final brief = File(
    'docs/assets/prompts/balanced-casual-representative-set.md',
  ).readAsStringSync();
  for (final token in [
    'exorcist_dosa',
    'plague_rat_swarm',
    'vengeful_spirit',
    'sakkat_specter',
    'dokkaebi',
    '128x128',
    '4x4',
    'bold clean outline',
    'Joseon',
  ]) {
    expect(brief, contains(token));
  }
});
```

- [ ] **Step 2: 테스트가 문서 누락으로 실패하는지 확인**

Run: `flutter test test/game/art_style_guide_test.dart`

Expected: FAIL with missing `balanced-casual-representative-set.md`.

- [ ] **Step 3: 대표 라인업 프롬프트 작성**

문서에 다음 고정 프롬프트 블록을 포함한다.

```text
Original mobile action-game character lineup for a Joseon folk-fantasy project.
Friendly 3-to-4-head proportions, bold clean dark outline, two-to-three-step
cel shading, bright flat colors, readable facial expression, centered neutral
pose, consistent upper-left light, transparent or plain review background.
No samurai armor, no wuxia robes, no copied commercial-game character, no UI.
```

플레이어와 적마다 실루엣, 의상, 장비, 금지 요소와 공통 발 기준점을 별도 항목으로 작성한다.

- [ ] **Step 4: `imagegen`으로 두 라인업 제작 및 검수**

`imagegen` 스킬을 읽고 플레이어 단독 라인업과 적 4종 한 장 라인업을 생성한다. `view_image`로 원본 해상도에서 다음을 확인한다.

- 작은 갓·망건, 철릭, 환도, 허리 부적이 일본·중국풍 없이 보인다.
- 네 적은 흑백 실루엣만으로 서로 구분된다.
- 외곽선 두께와 빛 방향이 모든 캐릭터에서 일치한다.
- 텍스트, 워터마크, 배경 소품과 잘린 신체가 없다.

- [ ] **Step 5: 권리 원장 갱신**

각 파일에 프로젝트 전용 생성물, 생성일 `2026-07-22`, 생성 도구, 프롬프트 문서 경로, 상태 `temporary`를 기록한다.

- [ ] **Step 6: 테스트와 diff 검증**

Run: `flutter test test/game/art_style_guide_test.dart && git diff --check`

Expected: PASS and no whitespace errors.

- [ ] **Step 7: 커밋**

```bash
git add docs/assets/prompts/balanced-casual-representative-set.md \
  docs/assets/asset-rights-ledger.csv source_assets/representative_set \
  test/game/art_style_guide_test.dart
git commit -m "art: lock balanced casual representative lineup"
```

### Task 2: 액터 시각 규격과 아틀라스 계약

**Files:**
- Create: `lib/game/content/actor_visual_spec.dart`
- Modify: `lib/game/content/sprite_atlas_contract.dart`
- Modify: `lib/game/content/actor_render_sizes.dart`
- Test: `test/game/actor_visual_spec_test.dart`
- Test: `test/game/sprite_atlas_contract_test.dart`

**Interfaces:**
- Consumes: 안정적인 `CharacterId`, `EnemyId`.
- Produces: `ActorVisualSpec`, `playerVisualSpecFor(CharacterId)`, `enemyVisualSpecFor(EnemyId)`, 5개 512×512 아틀라스 계약.

- [ ] **Step 1: ID별 시각 규격 실패 테스트 작성**

```dart
test('representative actor sizes preserve compact casual proportions', () {
  expect(playerVisualSpecFor(exorcistDosa).visualSize, 56);
  expect(enemyVisualSpecFor(plagueRatSwarm).visualSize, 32);
  expect(enemyVisualSpecFor(vengefulSpirit).visualSize, 40);
  expect(enemyVisualSpecFor(sakkatSpecter).visualSize, 40);
  expect(enemyVisualSpecFor(dokkaebi).visualSize, 44);
  expect(ActorRenderSizes.playerCollision, 24);
  expect(ActorRenderSizes.normalEnemyCollision, 18);
});
```

- [ ] **Step 2: 타입 부재로 실패 확인**

Run: `flutter test test/game/actor_visual_spec_test.dart`

Expected: compile FAIL for undefined `ActorVisualSpec`.

- [ ] **Step 3: 시각 규격 구현**

```dart
class ActorVisualSpec {
  const ActorVisualSpec({
    required this.visualSize,
    required this.groundOffsetY,
    required this.shadowWidth,
  });

  final double visualSize;
  final double groundOffsetY;
  final double shadowWidth;
}
```

`playerVisualSpecFor`와 `enemyVisualSpecFor`는 대표 ID에 승인값을 반환하고 나머지 ID에는 기존 rank 기반 크기를 사용하는 명시적 폴백을 반환한다.

- [ ] **Step 4: 아틀라스 계약 실패 테스트 작성**

```dart
for (final id in [
  'exorcist_dosa_balanced_casual',
  'plague_rat_swarm_balanced_casual',
  'vengeful_spirit_balanced_casual',
  'sakkat_specter_balanced_casual',
  'dokkaebi_balanced_casual',
]) {
  final atlas = ReplaceableArtCatalog.byId(id);
  expect(atlas.frameWidth, 128);
  expect(atlas.frameHeight, 128);
  expect(atlas.columns, 4);
  expect(atlas.rows, 4);
  expect(atlas.pixelWidth, 512);
  expect(atlas.pixelHeight, 512);
}
```

- [ ] **Step 5: 5개 계약 추가**

런타임 경로를 `assets/images/player/exorcist_dosa_128.png`와 `assets/images/monsters/<enemy_id>_128.png` 형식으로 고정하고 초기 상태는 `temporary`로 둔다.

- [ ] **Step 6: 집중 테스트 통과**

Run: `flutter test test/game/actor_visual_spec_test.dart test/game/sprite_atlas_contract_test.dart`

Expected: PASS.

- [ ] **Step 7: 커밋**

```bash
git add lib/game/content/actor_visual_spec.dart \
  lib/game/content/actor_render_sizes.dart \
  lib/game/content/sprite_atlas_contract.dart \
  test/game/actor_visual_spec_test.dart \
  test/game/sprite_atlas_contract_test.dart
git commit -m "feat: define representative actor visual contracts"
```

### Task 3: 퇴마 검객 16프레임 아틀라스와 런타임 애니메이션

**Files:**
- Create: `assets/images/player/exorcist_dosa_128.png`
- Create: `source_assets/representative_set/exorcist_dosa_atlas_source.png`
- Modify: `lib/game/components/player_component.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `lib/game/content/asset_catalog.dart`
- Modify: `pubspec.yaml`
- Test: `test/game/player_component_test.dart`
- Test: `test/game/content_integrity_test.dart`

**Interfaces:**
- Consumes: `playerVisualSpecFor(exorcistDosa)`, 4×4 frame ordering.
- Produces: `PlayerAnimationState.attacking`, `PlayerSpriteSheet.animations`, exorcist-only animated art with legacy fallback.

- [ ] **Step 1: 공격 상태와 아틀라스 로딩 실패 테스트 작성**

```dart
test('exorcist uses authored attack frames and keeps collision size', () async {
  final player = PlayerComponent(
    slotIndex: 0,
    characterId: exorcistDosa,
    maxHealth: 100,
    moveSpeed: 120,
  );
  expect(player.size, Vector2.all(24));
  expect(player.displaySize, Vector2.all(56));
  player.playAttack(Vector2(1, 0));
  expect(player.visualState, PlayerAnimationState.attacking);
});
```

- [ ] **Step 2: 새 상태 부재로 실패 확인**

Run: `flutter test test/game/player_component_test.dart`

Expected: compile FAIL for `attacking` or constructor `characterId`.

- [ ] **Step 3: 플레이어 아틀라스 생성**

Task 1의 승인된 정지 포즈를 참조 이미지로 사용해 `imagegen`으로 정확한 4×4 시트를 생성한다. 각 행은 이동, 공격, 피격+사망 시작, 사망 마무리 순서를 지킨다. `view_image(detail: original)`로 셀 경계, 동일 캐릭터, 발 기준점, 투명 배경을 확인하고 PNG 계약 테스트로 512×512 RGBA를 검증한다.

- [ ] **Step 4: 런타임 애니메이션 구현**

```dart
enum PlayerAnimationState { idle, walking, attacking, hit, death }

static const moveFrames = [0, 1, 2, 3];
static const attackFrames = [4, 5, 6, 7];
static const hitFrames = [8, 9];
static const deathFrames = [10, 11, 12, 13, 14, 15];
```

`PlayerComponent`에 `characterId`를 전달하고 `exorcistDosa`만 새 아틀라스를 사용한다. 다른 캐릭터는 기존 정적 스프라이트 폴백을 유지한다. 공격 종료 후 이동 입력에 따라 `walking` 또는 `idle`로 복귀한다.

```dart
final CharacterId characterId;

Vector2 get displaySize => Vector2.all(
  playerVisualSpecFor(characterId).visualSize,
);
```

기존 정적 `PlayerSpriteSheet.displaySize` 참조는 인스턴스 `displaySize`로 교체해 캐릭터별 크기가 렌더 오프셋에도 적용되게 한다.

- [ ] **Step 5: 게임 생성 경로 연결**

`PixelSurvivorGame._addActivePlayers`에서 `playerSlot.characterId`를 전달하고 시각 크기는 `playerVisualSpecFor`에서 읽는다.

- [ ] **Step 6: 집중 테스트 통과**

Run: `flutter test test/game/player_component_test.dart test/game/content_integrity_test.dart test/game/pixel_survivor_game_loop_test.dart`

Expected: PASS with collision behavior unchanged.

- [ ] **Step 7: 커밋**

```bash
git add assets/images/player/exorcist_dosa_128.png \
  source_assets/representative_set/exorcist_dosa_atlas_source.png \
  lib/game/components/player_component.dart lib/game/pixel_survivor_game.dart \
  lib/game/content/asset_catalog.dart pubspec.yaml \
  test/game/player_component_test.dart test/game/content_integrity_test.dart
git commit -m "feat: animate the representative exorcist"
```

### Task 4: 핵심 적 4종 아틀라스와 행동 동기화

**Files:**
- Create: `assets/images/monsters/plague_rat_swarm_128.png`
- Create: `assets/images/monsters/vengeful_spirit_128.png`
- Create: `assets/images/monsters/sakkat_specter_128.png`
- Create: `assets/images/monsters/dokkaebi_128.png`
- Create: `source_assets/representative_set/enemy_atlases/`
- Modify: `lib/game/components/enemy_component.dart`
- Modify: `lib/game/content/asset_catalog.dart`
- Modify: `pubspec.yaml`
- Test: `test/game/enemy_component_test.dart`
- Test: `test/game/content_integrity_test.dart`

**Interfaces:**
- Consumes: `enemyVisualSpecFor`, `EnemyAnimationState`, `EnemyBehaviorPhase`.
- Produces: 대표 4종의 이동·공격·피격·사망 애니메이션과 행동 예고 포즈.

- [ ] **Step 1: 대표 ID별 아트·크기 실패 테스트 작성**

```dart
for (final entry in {
  plagueRatSwarm: 32.0,
  vengefulSpirit: 40.0,
  sakkatSpecter: 40.0,
  dokkaebi: 44.0,
}.entries) {
  final enemy = EnemyComponent.fromDefinition(enemyDefinitionFor(entry.key)!);
  expect(enemy.visualSize, entry.value);
  expect(EnemySpriteSheet.specs[entry.key]!.frameSize, 128);
}
```

- [ ] **Step 2: 기존 24·32 프레임 규격으로 실패 확인**

Run: `flutter test test/game/enemy_component_test.dart`

Expected: FAIL with old size or missing `sakkat_specter` spec.

- [ ] **Step 3: 4개 아틀라스 제작**

Task 1 라인업을 참조해 적별 4×4 시트를 생성한다. 공격 행은 실제 역할과 일치해야 한다: 쥐떼 압축 후 돌진, 원혼 몸 접기 후 돌진, 삿갓 망령 부적불 발사, 도깨비 정면 방어·방망이 공격. PNG 계약과 육안 검수에 실패한 시트는 런타임에 넣지 않는다.

- [ ] **Step 4: 스펙과 행동 상태 연결**

`EnemySpriteSheet.specs`의 대표 4종을 128 프레임 경로로 교체한다. `warning` 단계에서는 공격 첫 프레임을 정지 표시하고, `active`에서 공격 애니메이션을 재생한다. 피격은 공격 예고를 취소하지 않되 색 플래시만 중첩한다.

- [ ] **Step 5: 집중 테스트 통과**

Run: `flutter test test/game/enemy_component_test.dart test/game/enemy_behavior_controller_test.dart test/game/content_integrity_test.dart`

Expected: PASS; behavior timing remains unchanged.

- [ ] **Step 6: 커밋**

```bash
git add assets/images/monsters source_assets/representative_set/enemy_atlases \
  lib/game/components/enemy_component.dart lib/game/content/asset_catalog.dart \
  pubspec.yaml test/game/enemy_component_test.dart \
  test/game/content_integrity_test.dart
git commit -m "feat: animate four representative enemy roles"
```

### Task 5: 밝은 조선 전장과 캐릭터 그림자

**Files:**
- Create: `lib/game/components/stage_backdrop_component.dart`
- Create: `lib/game/components/actor_shadow_component.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Test: `test/game/stage_backdrop_component_test.dart`
- Test: `test/game/pixel_survivor_game_loop_test.dart`

**Interfaces:**
- Consumes: game canvas size, `ActorVisualSpec.shadowWidth`.
- Produces: `StageBackdropComponent`, 저비용 `ActorShadowComponent`, 밝은 배경색.

- [ ] **Step 1: 렌더 우선순위와 색 계약 실패 테스트 작성**

```dart
test('bright stage stays behind every combat actor', () {
  final backdrop = StageBackdropComponent();
  expect(backdrop.priority, -100);
  expect(backdrop.baseColor.computeLuminance(), greaterThan(.45));
  expect(backdrop.ownsCollision, isFalse);
});
```

- [ ] **Step 2: 컴포넌트 부재로 실패 확인**

Run: `flutter test test/game/stage_backdrop_component_test.dart`

Expected: compile FAIL.

- [ ] **Step 3: 저비용 배경 구현**

`StageBackdropComponent.render`는 한지 베이지 바탕, 저채도 옥색 풀 패치, 흐린 돌길 선과 작은 기와 파편만 그린다. 같은 화면에 최대 40개 장식만 배치하고 게임 RNG와 분리된 고정 시드를 사용한다. 충돌과 업데이트 로직은 소유하지 않는다.

- [ ] **Step 4: 그림자 구현**

캐릭터 발 아래에 불투명도 0.18의 남청색 타원을 그린다. 그림자 폭은 `ActorVisualSpec.shadowWidth`, 높이는 폭의 0.28로 고정하고 공격·피격 상태와 무관하게 바닥 기준점을 유지한다.

- [ ] **Step 5: 배경 연결과 검증**

`PixelSurvivorGame.backgroundColor`를 밝은 한지색 폴백으로 바꾸고 `onLoad`에서 배경을 먼저 추가한다.

Run: `flutter test test/game/stage_backdrop_component_test.dart test/game/pixel_survivor_game_loop_test.dart`

Expected: PASS.

- [ ] **Step 6: 커밋**

```bash
git add lib/game/components/stage_backdrop_component.dart \
  lib/game/components/actor_shadow_component.dart lib/game/pixel_survivor_game.dart \
  test/game/stage_backdrop_component_test.dart test/game/pixel_survivor_game_loop_test.dart
git commit -m "feat: add a bright Joseon combat stage"
```

### Task 6: 모바일 전투 HUD 축소

**Files:**
- Modify: `lib/app/game_hud.dart`
- Modify: `lib/app/game_hud_source.dart`
- Test: `test/app/game_hud_test.dart`
- Test: `test/app/accessibility_surfaces_test.dart`
- Test: `test/app/responsive_layout_test.dart`
- Update: `test/app/goldens/game_hud_16_9.png`

**Interfaces:**
- Consumes: 기존 `GameHudSource` 값.
- Produces: 얇은 상단 상태 행, 체력·경험치 바, 작은 무기 슬롯, 104 조이스틱.

- [ ] **Step 1: 면적·터치 계약 실패 테스트 작성**

```dart
await tester.pumpWidget(buildHud(size: const Size(390, 844)));
expect(tester.getSize(find.byKey(const Key('hud-pause'))),
    const Size(48, 48));
expect(tester.getSize(find.byKey(const Key('hud-status'))).height,
    lessThanOrEqualTo(92));
expect(find.byKey(const Key('hud-health-bar')), findsOneWidget);
expect(find.byKey(const Key('hud-xp-bar')), findsOneWidget);
expect(tester.getSize(find.byType(VirtualJoystick)).width, 104);
```

- [ ] **Step 2: 현재 큰 패널로 실패 확인**

Run: `flutter test test/app/game_hud_test.dart test/app/responsive_layout_test.dart`

Expected: FAIL for absent bars or size mismatch.

- [ ] **Step 3: HUD 재구성**

상단 행을 일시정지·시간·레벨·처치 수로 제한한다. 체력과 경험치는 8~10 높이의 별도 바를 사용한다. 텍스트 무기 목록은 최대 3개의 32 아이콘 슬롯과 레벨 숫자로 교체하고 상세 이름은 기존 일시정지 화면에서만 표시한다.

- [ ] **Step 4: 조이스틱과 접근성 보존**

조이스틱 크기를 104로 줄이고 불투명도는 idle 0.35, active 0.55로 변경한다. 시스템 글자 배율 2.0에서 HUD가 전투 화면 12%를 넘지 않도록 숫자에 `FittedBox`와 의미 라벨을 사용한다.

- [ ] **Step 5: 골든과 테스트 갱신**

Run: `flutter test test/app/game_hud_test.dart test/app/accessibility_surfaces_test.dart test/app/responsive_layout_test.dart test/app/release_surface_golden_test.dart`

Expected: PASS after reviewed golden update.

- [ ] **Step 6: 커밋**

```bash
git add lib/app/game_hud.dart lib/app/game_hud_source.dart \
  test/app/game_hud_test.dart test/app/accessibility_surfaces_test.dart \
  test/app/responsive_layout_test.dart test/app/goldens/game_hud_16_9.png
git commit -m "feat: compact the mobile combat HUD"
```

### Task 7: 적 경고·방어 표시와 피해 숫자 정리

**Files:**
- Modify: `lib/game/components/enemy_combat_overlay_component.dart`
- Modify: `lib/game/components/enemy_component.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Test: `test/game/enemy_combat_overlay_component_test.dart`
- Test: `test/game/enemy_component_test.dart`

**Interfaces:**
- Consumes: `EnemyWarningSnapshot`, `shieldDirection`, 렌더 우선순위.
- Produces: 경고 불투명도 상한 0.32, 90도 방패 호, 거리 기반 경고 강조.

- [ ] **Step 1: 방패 호·불투명도 실패 테스트 작성**

```dart
expect(EnemyCombatOverlayStyle.warningAlpha, lessThanOrEqualTo(.32));
expect(EnemyCombatOverlayStyle.shieldSweepRadians, closeTo(pi / 2, 1e-9));
expect(EnemyCombatOverlayStyle.usesFullBodyRectangle, isFalse);
```

렌더 우선순위 테스트는 production 소스 문자열을 읽지 않고 실제 컴포넌트 인스턴스의 `priority`를 비교한다.

- [ ] **Step 2: 기존 거대 표시로 실패 확인**

Run: `flutter test test/game/enemy_combat_overlay_component_test.dart`

Expected: FAIL for missing style or rectangle behavior.

- [ ] **Step 3: 역할별 경고 구현**

돌진은 얇은 방향 띠, 원거리는 작은 목표 원, 방어는 적 전방의 낮은 90도 호를 사용한다. 같은 경고가 겹치면 플레이어에 가장 가까운 8개만 기본 불투명도로 그리고 나머지는 절반 불투명도로 줄인다.

- [ ] **Step 4: 피해 숫자 예산 보존**

일반 피해는 같은 적·0.12초 창에서 합산하고 치명타·방어 파괴·마스터만 큰 글자 스타일을 요청한다. `GamePerformanceBudget.maxDamageNumbers == 24`는 유지한다.

- [ ] **Step 5: 집중 테스트 통과**

Run: `flutter test test/game/enemy_combat_overlay_component_test.dart test/game/enemy_component_test.dart test/game/game_performance_budget_test.dart`

Expected: PASS.

- [ ] **Step 6: 커밋**

```bash
git add lib/game/components/enemy_combat_overlay_component.dart \
  lib/game/components/enemy_component.dart lib/game/pixel_survivor_game.dart \
  test/game/enemy_combat_overlay_component_test.dart \
  test/game/enemy_component_test.dart
git commit -m "feat: clarify enemy warnings and defense"
```

### Task 8: 환도·부적·봉마참 공통 비주얼 테마

**Files:**
- Create: `lib/game/combat/combat_visual_theme.dart`
- Modify: `lib/game/components/attack_effect_component.dart`
- Modify: `lib/game/components/five_color_ward_component.dart`
- Modify: `lib/game/components/talisman_presentation_component.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Test: `test/game/combat_visual_theme_test.dart`
- Test: `test/game/attack_geometry_test.dart`
- Test: `test/game/five_color_ward_component_test.dart`
- Test: `test/game/weapon_synergy_resolver_test.dart`

**Interfaces:**
- Consumes: `AttackInstance`, `AttackSpec`, `AttackGeometry`, `AttackPresentation`.
- Produces: `CombatVisualTheme.forAttack(AttackInstance)`와 무기별 색·선 굵기·잔상 수명.

- [ ] **Step 1: 색상·피드백 계약 실패 테스트 작성**

```dart
final slash = CombatVisualTheme.forAttack(hwandoAttack);
expect(slash.coreColor, const Color(0xffeafcff));
expect(slash.edgeColor, const Color(0xff7bdff2));

final seal = CombatVisualTheme.forAttack(talismanAttack);
expect(seal.coreColor, const Color(0xffffd166));
expect(seal.edgeColor, const Color(0xffd1495b));

final synergy = CombatVisualTheme.forAttack(sealingSlashAttack);
expect(synergy.isSynergy, isTrue);
expect(synergy.maxAlpha, lessThanOrEqualTo(.88));
```

- [ ] **Step 2: 테마 부재로 실패 확인**

Run: `flutter test test/game/combat_visual_theme_test.dart`

Expected: compile FAIL.

- [ ] **Step 3: 단일 테마 매핑 구현**

```dart
class CombatVisualTheme {
  const CombatVisualTheme({
    required this.coreColor,
    required this.edgeColor,
    required this.strokeWidth,
    required this.maxAlpha,
    required this.isSynergy,
  });

  static CombatVisualTheme forAttack(AttackInstance attack) {
    final id = attack.spec.id;
    if (id == sealingSlash ||
        attack.spec.presentation == AttackPresentation.synergy) {
      return const CombatVisualTheme(
        coreColor: Color(0xffffd166),
        edgeColor: Color(0xff7bdff2),
        strokeWidth: 8,
        maxAlpha: .88,
        isSynergy: true,
      );
    }
    if (id.startsWith('hwando_')) {
      return CombatVisualTheme(
        coreColor: const Color(0xffeafcff),
        edgeColor: attack.spec.presentation == AttackPresentation.master
            ? const Color(0xffffd166)
            : const Color(0xff7bdff2),
        strokeWidth: attack.spec.presentation == AttackPresentation.master
            ? 12
            : 7,
        maxAlpha: .86,
        isSynergy: false,
      );
    }
    if (id.startsWith('talisman_')) {
      return const CombatVisualTheme(
        coreColor: Color(0xffffd166),
        edgeColor: Color(0xffd1495b),
        strokeWidth: 7,
        maxAlpha: .84,
        isSynergy: false,
      );
    }
    return const CombatVisualTheme(
      coreColor: Color(0xfff4ead2),
      edgeColor: Color(0xff9fb3c8),
      strokeWidth: 5,
      maxAlpha: .78,
      isSynergy: false,
    );
  }
}
```

매핑은 안정적인 공격 ID와 presentation을 사용한다. 렌더 컴포넌트는 `AttackInstance.geometry`의 방향·반경·호각을 그대로 사용한다.

- [ ] **Step 4: 환도 마스터 연출 교체**

기본 청백 원호, 금색 강타 외곽선, 마스터 첫 반원과 점차 커지는 원호, 금색 테두리의 마무리 폭풍을 구현한다. 히트스톱 규칙은 strong 20ms, 마스터 시작·마무리 35ms만 유지한다.

- [ ] **Step 5: 부적·봉마참 연출 교체**

비행 부적, 작은 부착 인장, 주홍·금 폭발, 투명한 오방색 결계를 구현한다. 봉마참은 금빛 균열과 청백 외곽 고리를 사용하고 첫 발동 이름 노출 제한을 유지한다.

- [ ] **Step 6: 기하·효과 테스트 통과**

Run: `flutter test test/game/combat_visual_theme_test.dart test/game/attack_geometry_test.dart test/game/five_color_ward_component_test.dart test/game/weapon_synergy_resolver_test.dart test/game/combat_feedback_controller_test.dart`

Expected: PASS; no presentation component owns damage.

- [ ] **Step 7: 커밋**

```bash
git add lib/game/combat/combat_visual_theme.dart \
  lib/game/components/attack_effect_component.dart \
  lib/game/components/five_color_ward_component.dart \
  lib/game/components/talisman_presentation_component.dart \
  lib/game/pixel_survivor_game.dart test/game/combat_visual_theme_test.dart \
  test/game/attack_geometry_test.dart test/game/five_color_ward_component_test.dart \
  test/game/weapon_synergy_resolver_test.dart
git commit -m "feat: restyle representative combat effects"
```

### Task 9: 모바일 골든·밀도·성능 통합 검증

**Files:**
- Create: `test/app/goldens/balanced_casual_early_390x844.png`
- Create: `test/app/goldens/balanced_casual_late_390x844.png`
- Create: `test/app/balanced_casual_combat_golden_test.dart`
- Modify: `test/game/five_minute_performance_development_log_test.dart`
- Modify: `docs/testing/combat-mastery-vertical-slice-report.md`
- Create: `docs/testing/balanced-casual-mobile-checklist.md`

**Interfaces:**
- Consumes: 완성된 대표 아트·HUD·배경·효과.
- Produces: 초반·후반 골든, 5분 고정 시드 성능 증거, 실제 폰 체크리스트.

- [ ] **Step 1: 390×844 골든 테스트 작성**

초반은 플레이어와 네 역할 적이 분리된 상태, 후반은 30개 이상의 적과 환도 마스터·부적 결계가 동시에 보이는 상태를 고정 시드로 구성한다.

```dart
await tester.binding.setSurfaceSize(const Size(390, 844));
await expectLater(
  find.byKey(const Key('game-surface')),
  matchesGoldenFile('goldens/balanced_casual_late_390x844.png'),
);
```

- [ ] **Step 2: 골든 부재 실패 확인**

Run: `flutter test test/app/balanced_casual_combat_golden_test.dart`

Expected: FAIL for missing reviewed golden.

- [ ] **Step 3: 골든 생성 후 원본 크기 육안 검수**

Run: `flutter test --update-goldens test/app/balanced_casual_combat_golden_test.dart`

`view_image(detail: original)`로 플레이어 위치, 네 적 실루엣, 경고, HUD 면적, 후반 이펙트 투명도를 확인한다. 잘못된 골든을 테스트 통과 목적으로 승인하지 않는다.

- [ ] **Step 4: 5분 성능 기준 재수집**

Run: `flutter test test/game/five_minute_performance_development_log_test.dart test/game/multi_seed_run_regression_test.dart`

Expected: late average enemies 30~55, maximum near 60 but not above 96; population and memory proxy violations 0. 새 아트가 population count를 바꾸지 않았다면 기존 결정적 수치를 유지하고 임의로 기대값을 완화하지 않는다.

- [ ] **Step 5: 전체 자동 게이트**

```powershell
dart format --output=none --set-exit-if-changed lib test
git diff --check
flutter analyze
flutter test -r compact
flutter build web --release
flutter build apk --debug
```

Expected: every command exits 0; exact test count and artifact hashes are recorded.

- [ ] **Step 6: 실제 모바일 체크리스트 작성**

플레이어·적 실루엣, 30~55마리 가독성, 환도 레벨 1/마스터 차이, 부적 순서, 봉마참 구분, 방어 방향, 흔들림·흰 화면, Android 후반 FPS를 빈 체크박스로 기록한다. 자동 테스트 결과로 주관적 항목을 채우지 않는다.

- [ ] **Step 7: 최종 보고서와 커밋**

```bash
git add test/app/balanced_casual_combat_golden_test.dart \
  test/app/goldens/balanced_casual_*.png \
  test/game/five_minute_performance_development_log_test.dart \
  docs/testing/combat-mastery-vertical-slice-report.md \
  docs/testing/balanced-casual-mobile-checklist.md
git commit -m "test: verify balanced casual combat presentation"
```

### Task 10: 대표 세트 승인 상태와 외부 플레이 빌드

**Files:**
- Modify: `lib/game/content/sprite_atlas_contract.dart`
- Modify: `docs/assets/asset-rights-ledger.csv`
- Modify: `docs/testing/balanced-casual-mobile-checklist.md`
- Test: `test/game/sprite_atlas_contract_test.dart`

**Interfaces:**
- Consumes: Task 9의 자동 증거와 실제 모바일 관찰 결과.
- Produces: 검증된 에셋만 `approved`로 전환된 외부 플레이 빌드.

- [ ] **Step 1: 승인 전환 조건 테스트 작성**

```dart
test('only the reviewed representative atlases are approved', () {
  final approved = ReplaceableArtCatalog.atlases
      .where((atlas) => atlas.status == ArtAssetStatus.approved)
      .map((atlas) => atlas.id)
      .toSet();
  expect(approved, containsAll(representativeAtlasIds));
  expect(approved, isNot(contains('fallen_general')));
});
```

- [ ] **Step 2: 실제 모바일 관찰 전에는 테스트를 활성화하지 않음**

대표 골든과 자동 게이트만으로 `approved`를 설정하지 않는다. 외부 웹 링크와 Android APK를 제공해 체크리스트의 관찰자가 결과를 기록한 뒤 테스트를 활성화한다.

- [ ] **Step 3: 검증된 에셋만 승인 전환**

대표 5개 계약과 권리 원장의 상태를 `approved`로 바꾸고 나머지는 `temporary`로 유지한다.

- [ ] **Step 4: 최종 집중 테스트와 커밋**

Run: `flutter test test/game/sprite_atlas_contract_test.dart test/game/content_integrity_test.dart`

Expected: PASS.

```bash
git add lib/game/content/sprite_atlas_contract.dart \
  docs/assets/asset-rights-ledger.csv \
  docs/testing/balanced-casual-mobile-checklist.md \
  test/game/sprite_atlas_contract_test.dart
git commit -m "art: approve the representative combat set"
```

대표 세트 승인 이후에만 별도 계획으로 나머지 플레이어 2종과 적 9종을 같은 규격에 따라 제작한다.
