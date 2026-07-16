# Meta Compendium and History Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 로비에서 캐릭터·무기·증강 도감과 최고 기록·캐릭터 승리·무기 사용 기록을 확인하고 런 정산 결과를 호환 저장한다.

**Architecture:** SaveState schema v3는 캐릭터 승리와 도감 열람만 소유하고, 기존 RunTelemetry 이력은 무기 사용 기록만 소유한다. 순수 서비스가 화면용 모델을 만들며 Flutter 화면은 저장/집계 구현을 직접 알지 않는다.

**Tech Stack:** Flutter 3.44.4, Dart 3.12, SharedPreferences, flutter_test

## Global Constraints

- `docs/master-development-todo.md`, 보스, 설정, QA 런타임 파일을 수정하지 않는다.
- 모든 사용자 문구는 한국어이고 화면 본문은 SafeArea와 스크롤을 사용한다.
- production 변경 전 대응 테스트를 RED로 확인한다.
- 최종 검증은 ASCII 드라이브 매핑에서 focused test, 전체 analyze/test, web build 순서로 수행한다.

---

### Task 1: Schema v3 메타 기록

**Files:**
- Modify: `lib/game/systems/save_system.dart`
- Modify: `lib/game/systems/meta_progression_service.dart`
- Modify: `lib/app/game_screen.dart`
- Test: `test/game/save_system_test.dart`
- Test: `test/game/meta_progression_service_test.dart`

**Interfaces:**
- Produces: `SaveState.characterVictoryCounts`, `SaveState.seenCompendiumEntryIds`, `MetaProgressionService.settleRun(RunResult, {String? characterId})`

- [ ] **Step 1: Write failing schema tests**

Add assertions that schema v3 JSON round-trips both fields and legacy schema v3 JSON without them yields empty maps/sets.

- [ ] **Step 2: Run RED**

Run: `flutter test test/game/save_system_test.dart`
Expected: compile failure because the new fields do not exist.

- [ ] **Step 3: Implement compatible fields**

Add immutable, validated known-character counts and known compendium entry keys to constructor, defaults, parser, copyWith, and toJson without changing `currentSchemaVersion = 3`.

- [ ] **Step 4: Write and verify failing settlement test**

Test that victory for `rookieConstable` increments once, defeat does not increment, and best survival remains governed by existing progression.

- [ ] **Step 5: Implement settlement ownership**

Accept the selected character ID in `settleRun`, increment only known characters on victory, and pass `widget.playerSlot.characterId` from `GameScreen`.

- [ ] **Step 6: Run GREEN and commit**

Run: `flutter test test/game/save_system_test.dart test/game/meta_progression_service_test.dart test/app/game_screen_telemetry_test.dart`

### Task 2: 도감 모델과 진행률

**Files:**
- Create: `lib/game/models/compendium_entry.dart`
- Create: `lib/game/systems/compendium_service.dart`
- Test: `test/game/compendium_service_test.dart`

**Interfaces:**
- Produces: `CompendiumSection`, `CompendiumEntry`, `CompendiumService.entries(SaveState)`, `CompendiumService.unseenUnlockedKeys(SaveState)`

- [ ] **Step 1: Write failing catalog tests**

Assert all three rosters are represented, starting items say `기본 해금`, locked goal rewards expose Korean conditions/current/threshold/fraction, and unseen unlocked keys exclude locked/seen entries.

- [ ] **Step 2: Run RED**

Run: `flutter test test/game/compendium_service_test.dart`
Expected: missing import/type failure.

- [ ] **Step 3: Implement minimal immutable model and service**

Map unlock metrics to Korean condition text, derive progress via `ProgressionSystem.metricValue`, and use namespaced entry keys.

- [ ] **Step 4: Run GREEN and commit**

Run: `flutter test test/game/compendium_service_test.dart`

### Task 3: 텔레메트리 기록 집계

**Files:**
- Create: `lib/game/models/meta_history.dart`
- Create: `lib/game/systems/meta_history_service.dart`
- Test: `test/game/meta_history_service_test.dart`

**Interfaces:**
- Produces: `WeaponUsageRecord`, `MetaHistoryService.loadWeaponUsage()`
- Consumes: `TelemetryRepository.load()`, known `weaponDefinitions`

- [ ] **Step 1: Write failing aggregation tests**

Use real RunTelemetry values to assert usage-run union semantics, summed kills/damage, definition order, unknown ID filtering, empty history, and repository read failure recovery.

- [ ] **Step 2: Run RED**

Run: `flutter test test/game/meta_history_service_test.dart`
Expected: missing service failure.

- [ ] **Step 3: Implement minimal aggregation service**

Inject a history loader, aggregate maps without duplicating persistence, and return an immutable list.

- [ ] **Step 4: Run GREEN and commit**

Run: `flutter test test/game/meta_history_service_test.dart test/game/telemetry_repository_test.dart`

### Task 4: 도감 화면과 로비 연결

**Files:**
- Create: `lib/app/compendium_screen.dart`
- Modify: `lib/app/lobby_controller.dart`
- Modify: `lib/app/lobby_screen.dart`
- Create: `test/app/compendium_screen_test.dart`
- Modify: `test/app/lobby_screen_test.dart`
- Modify: `test/app/responsive_layout_test.dart`

**Interfaces:**
- Produces: `LobbyController.markCompendiumEntriesSeen(Set<String>)`
- Consumes: `CompendiumService`, current SaveState

- [ ] **Step 1: Write failing widget/controller tests**

Assert three Korean tabs, locked progress, `새 항목`, SafeArea, seen persistence, and `lobby-compendium` navigation.

- [ ] **Step 2: Run RED**

Run: `flutter test test/app/compendium_screen_test.dart test/app/lobby_screen_test.dart`
Expected: missing screen/key failures.

- [ ] **Step 3: Implement screen, persistence, and navigation**

Build a TabBar/TabBarView with scrollable cards; preserve initial unseen badges for the visit while persisting their keys through the controller.

- [ ] **Step 4: Run GREEN and commit**

Run: `flutter test test/app/compendium_screen_test.dart test/app/lobby_screen_test.dart test/app/responsive_layout_test.dart`

### Task 5: 기록 화면

**Files:**
- Modify: `lib/app/records_screen.dart`
- Create: `test/app/records_screen_test.dart`
- Modify: `test/app/korean_strings_test.dart`

**Interfaces:**
- Consumes: `SaveState.characterVictoryCounts`, `MetaHistoryService.loadWeaponUsage()`

- [ ] **Step 1: Write failing widget tests**

Assert 최고 기록, every character victory count, weapon usage values, Korean empty state, loading recovery, SafeArea, and small-screen scrolling.

- [ ] **Step 2: Run RED**

Run: `flutter test test/app/records_screen_test.dart`
Expected: missing history UI text.

- [ ] **Step 3: Implement async record sections**

Convert RecordsScreen to a stateful, scrollable screen with injected history service and stable Korean formatting.

- [ ] **Step 4: Run GREEN and commit**

Run: `flutter test test/app/records_screen_test.dart test/app/korean_strings_test.dart`

### Task 6: 문서와 전체 검증

**Files:**
- Create: `docs/meta/meta-compendium-history.md`
- Create: `docs/superpowers/verification/2026-07-16-meta-compendium-history.md`

- [ ] **Step 1: Document storage ownership and migration**

Describe schema v3 optional fields, telemetry aggregation, entry key format, and empty-state behavior.

- [ ] **Step 2: Run focused and full verification on ASCII mapping**

Run focused tests, `flutter analyze --no-pub`, `flutter test`, and `flutter build web --release` from a temporary ASCII drive mapping.

- [ ] **Step 3: Verify scope and diff**

Run `git diff --check`, `git status --short`, and confirm prohibited files are absent from `git diff --name-only db45241..HEAD`.

- [ ] **Step 4: Commit final documentation**

Commit all verified documentation and report commit hashes and command evidence.

