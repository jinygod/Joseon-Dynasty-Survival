# 로비와 메타 저장 기반 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 기존 5분 전투 진입 흐름을 저장 가능한 관아 로비로 교체하고, 스키마 2의 지갑·수련·상점 진행 기반과 인물·스테이지·설정·기록 연결을 완성한다.

**Architecture:** `SaveState`가 메타 진행과 현재 선택을 직렬화하고 `LobbyController`가 로드·선택 변경·저장을 한 줄로 직렬화한다. `LobbyScreen`은 컨트롤러의 상태만 표시하며 기존 인물/스테이지 선택 화면을 선택 전용 화면으로 재사용한다. 실제 재화 지급, 희귀 드롭, 수련 구매와 상점 거래 규칙은 후속 프로젝트에서 `MetaProgressionService`로 추가한다.

**Tech Stack:** Flutter, Dart 3, Material widgets, SharedPreferences, flutter_test

## Global Constraints

- 첫 출시 플랫폼은 Android, 화면은 가로 방향, 플레이는 오프라인 싱글플레이로 유지한다.
- 한 판은 5분 보스 결전형을 기본으로 한다.
- 로비는 조선 관아를 중심으로 한 B안으로 만든다.
- 이모지는 제품 UI와 최종 에셋에서 사용하지 않는다.
- 캐릭터·건물·배경·메뉴 아이콘은 중앙 에셋 카탈로그의 ID와 경로를 교체할 수 있어야 한다.
- 기력 제한, 광고, 인앱 결제, 시즌, 일일 과제, 우편, 라이브 서비스는 Android 1.0 범위에서 제외한다.
- 스키마 1의 해금과 기록을 보존하고 스키마 2의 새 필드는 안전한 기본값으로 채운다.
- 이 계획에서는 재화 보상, 희귀 드롭, 수련 구매, 상점 거래를 구현하지 않는다.

---

### Task 1: 메타 진행 값 객체와 저장 스키마 2

**Files:**
- Create: `lib/game/content/meta_progress_definitions.dart`
- Create: `lib/game/models/meta_progress.dart`
- Modify: `lib/game/systems/save_system.dart`
- Test: `test/game/save_system_test.dart`

**Interfaces:**
- Produces: `Wallet`, `TrainingProgress`, `ShopProgress`
- Produces: 저장 호환성을 고정하는 수련·핵심 특성·상점 품목 ID 집합
- Produces: `SaveState.wallet`, `trainingProgress`, `shopProgress`, `selectedCharacterId`, `selectedStageId`
- Preserves: 스키마 0/1의 해금·누적 기록

- [ ] **Step 1: 스키마 2 마이그레이션 실패 테스트 작성**

```dart
test('schema one migrates to schema two without losing progress', () {
  final restored = SaveState.fromJson({
    'schemaVersion': 1,
    'unlockedCharacterIds': [rookieConstable, exorcistDosa],
    'totalKills': 91,
    'bestSurvivalSeconds': 240,
  });

  expect(restored.schemaVersion, 2);
  expect(restored.unlockedCharacterIds, contains(exorcistDosa));
  expect(restored.totalKills, 91);
  expect(restored.wallet, Wallet.empty);
  expect(restored.trainingProgress, TrainingProgress.empty);
  expect(restored.shopProgress, ShopProgress.empty);
  expect(restored.selectedCharacterId, rookieConstable);
  expect(restored.selectedStageId, moonlitAbandonedOffice);
});

test('schema two sanitizes invalid meta values and unknown selections', () {
  final restored = SaveState.fromJson({
    'schemaVersion': 2,
    'wallet': {'coin': -20, 'spiritJade': 'bad'},
    'trainingProgress': {
      'commonRanks': {'unknown': 9},
      'characterRanks': {'unknown': {'node': 1}},
      'activeCoreTraitIds': {'unknown': 'trait'},
    },
    'shopProgress': {'purchasedItemIds': ['manual.constable', 7]},
    'selectedCharacterId': 'missing',
    'selectedStageId': 'missing',
  });

  expect(restored.wallet, Wallet.empty);
  expect(restored.trainingProgress, TrainingProgress.empty);
  expect(restored.shopProgress.purchasedItemIds, {'manual.constable'});
  expect(restored.selectedCharacterId, rookieConstable);
  expect(restored.selectedStageId, moonlitAbandonedOffice);
});
```

- [ ] **Step 2: 테스트가 현재 스키마 1과 타입 부재로 실패하는지 확인**

Run: `flutter test test/game/save_system_test.dart`
Expected: FAIL (`Wallet` 미정의 또는 schema version 기대값 불일치)

- [ ] **Step 3: 중앙 메타 진행 ID 정의 작성**

`lib/game/content/meta_progress_definitions.dart`에 저장 키로 쓰일 다음 상수를 작성한다. 표시명과 가격은 구매 프로젝트에서 별도 정의한다.

```dart
const commonTrainingNodeIds = {
  'common.max_health',
  'common.base_damage',
  'common.pickup_range',
  'common.move_speed',
};

const characterTrainingNodeIds = {
  'max_health',
  'base_damage',
  'move_speed',
  'pickup_range',
  'cooldown',
  'survival',
};

const coreTraitIdsByCharacter = <String, Set<String>>{
  'rookie_constable': {'constable.stalwart', 'constable.counter_stance'},
  'exorcist_dosa': {'dosa.talisman_mastery', 'dosa.spirit_burn'},
  'mountain_hunter': {'hunter.hawk_eye', 'hunter.trapcraft'},
};

const oneTimeShopItemIds = {
  'manual.rookie_constable',
  'manual.exorcist_dosa',
  'manual.mountain_hunter',
};
```

- [ ] **Step 4: 불변 메타 값 객체 구현**

`lib/game/models/meta_progress.dart`에 다음 공개 계약을 구현한다.

```dart
class Wallet {
  const Wallet({required this.coin, required this.spiritJade});
  static const empty = Wallet(coin: 0, spiritJade: 0);
  final int coin;
  final int spiritJade;
  factory Wallet.fromJson(Object? value) {
    if (value is! Map) return empty;
    int read(Object? candidate) => candidate is int && candidate >= 0 ? candidate : 0;
    return Wallet(coin: read(value['coin']), spiritJade: read(value['spiritJade']));
  }
  Map<String, dynamic> toJson() => {'coin': coin, 'spiritJade': spiritJade};
  @override
  bool operator ==(Object other) =>
      other is Wallet && other.coin == coin && other.spiritJade == spiritJade;
  @override
  int get hashCode => Object.hash(coin, spiritJade);
}

class TrainingProgress {
  const TrainingProgress({
    required this.commonRanks,
    required this.characterRanks,
    required this.activeCoreTraitIds,
  });
  static const empty = TrainingProgress(
    commonRanks: {}, characterRanks: {}, activeCoreTraitIds: {},
  );
  final Map<String, int> commonRanks;
  final Map<String, Map<String, int>> characterRanks;
  final Map<String, String> activeCoreTraitIds;
  factory TrainingProgress.fromJson(Object? value) {
    if (value is! Map) return empty;
    Map<String, int> ranks(Object? raw) => raw is Map
        ? Map.unmodifiable(Map.fromEntries(raw.entries.where(
            (entry) => entry.key is String && entry.value is int && (entry.value as int) >= 0,
          ).map((entry) => MapEntry(entry.key as String, entry.value as int))))
        : const {};
    final characterRanks = <String, Map<String, int>>{};
    final rawCharacters = value['characterRanks'];
    if (rawCharacters is Map) {
      for (final entry in rawCharacters.entries) {
        if (entry.key is String && coreTraitIdsByCharacter.containsKey(entry.key)) {
          characterRanks[entry.key as String] = Map.unmodifiable(
            Map.fromEntries(ranks(entry.value).entries.where(
              (rank) => characterTrainingNodeIds.contains(rank.key),
            )),
          );
        }
      }
    }
    final activeTraits = <String, String>{};
    final rawTraits = value['activeCoreTraitIds'];
    if (rawTraits is Map) {
      for (final entry in rawTraits.entries) {
        if (entry.key is String &&
            entry.value is String &&
            coreTraitIdsByCharacter[entry.key]?.contains(entry.value) == true) {
          activeTraits[entry.key as String] = entry.value as String;
        }
      }
    }
    return TrainingProgress(
      commonRanks: Map.unmodifiable(Map.fromEntries(
        ranks(value['commonRanks']).entries.where(
          (rank) => commonTrainingNodeIds.contains(rank.key),
        ),
      )),
      characterRanks: Map.unmodifiable(characterRanks),
      activeCoreTraitIds: Map.unmodifiable(activeTraits),
    );
  }
  Map<String, dynamic> toJson() => {
    'commonRanks': commonRanks,
    'characterRanks': characterRanks,
    'activeCoreTraitIds': activeCoreTraitIds,
  };
}

class ShopProgress {
  const ShopProgress({required this.purchasedItemIds});
  static const empty = ShopProgress(purchasedItemIds: {});
  final Set<String> purchasedItemIds;
  factory ShopProgress.fromJson(Object? value) {
    if (value is! Map || value['purchasedItemIds'] is! Iterable) return empty;
    return ShopProgress(
      purchasedItemIds: Set.unmodifiable(
        (value['purchasedItemIds'] as Iterable).whereType<String>(),
      ),
    );
  }
  Map<String, dynamic> toJson() => {
    'purchasedItemIds': purchasedItemIds.toList()..sort(),
  };
}
```

- [ ] **Step 5: `SaveState`를 스키마 2로 확장**

`currentSchemaVersion = 2`로 올리고 생성자, `defaults`, `_fromSupportedJson`, `copyWith`, `toJson`에 다음 필드를 동일한 이름으로 추가한다.

```dart
required this.wallet,
required this.trainingProgress,
required this.shopProgress,
required this.selectedCharacterId,
required this.selectedStageId,
```

선택 ID는 실제 정의 목록에 존재하고 캐릭터는 해금된 경우에만 채택한다. 그렇지 않으면 각각 `rookieConstable`, `stageDefinitions.first.id`를 사용한다. 기존 정수 기록에도 `_nonNegativeIntValue`를 적용해 손상된 음수 값을 0으로 복구한다.

- [ ] **Step 6: 저장 테스트 통과 확인**

Run: `flutter test test/game/save_system_test.dart`
Expected: PASS

- [ ] **Step 7: 커밋**

```powershell
git add lib/game/content/meta_progress_definitions.dart lib/game/models/meta_progress.dart lib/game/systems/save_system.dart test/game/save_system_test.dart
git commit -m "feat: migrate saves to meta progression schema"
```

### Task 2: 로비 상태 컨트롤러와 저장 직렬화

**Files:**
- Create: `lib/app/lobby_controller.dart`
- Create: `test/app/lobby_controller_test.dart`

**Interfaces:**
- Consumes: `SaveSystem.load()`, `SaveSystem.save(SaveState)`
- Produces: `LobbyController.load()`, `selectCharacter(String)`, `selectStage(String)`, `state`, `loading`, `saving`, `recoveryNotice`

- [ ] **Step 1: 로드·선택·중복 입력 테스트 작성**

```dart
test('loads persisted selections and saves changes in order', () async {
  final store = MemorySaveStore(SaveState.defaults());
  final controller = LobbyController(store: store);
  await controller.load();

  await controller.selectCharacter(exorcistDosa);
  await controller.selectStage(moonlitAbandonedOffice);

  expect(controller.state.selectedCharacterId, exorcistDosa);
  expect(store.saved.last.selectedCharacterId, exorcistDosa);
  expect(store.maxConcurrentSaves, 1);
});

test('load failure uses defaults and exposes one recovery notice', () async {
  final controller = LobbyController(store: ThrowingSaveStore());
  await controller.load();
  expect(controller.state.selectedCharacterId, rookieConstable);
  expect(controller.takeRecoveryNotice(), isNotNull);
  expect(controller.takeRecoveryNotice(), isNull);
});
```

테스트 지원 저장소는 `SaveStore` 인터페이스를 구현하고 저장 동시 실행 수를 기록한다.

- [ ] **Step 2: 테스트 실패 확인**

Run: `flutter test test/app/lobby_controller_test.dart`
Expected: FAIL (`LobbyController` 미정의)

- [ ] **Step 3: 저장 추상화와 컨트롤러 구현**

`SaveSystem`이 다음 인터페이스를 구현하게 하고 컨트롤러는 `ChangeNotifier`로 만든다.

```dart
abstract interface class SaveStore {
  Future<SaveState> load();
  Future<void> save(SaveState state);
}

class LobbyController extends ChangeNotifier {
  LobbyController({required SaveStore store});
  SaveState state = SaveState.defaults();
  bool loading = true;
  bool saving = false;
  String? recoveryNotice;

  Future<void> load();
  Future<void> selectCharacter(String characterId);
  Future<void> selectStage(String stageId);
  String? takeRecoveryNotice();
}
```

모든 변경은 내부 `Future<void> _saveQueue = Future.value()` 뒤에 연결한다. 저장 성공 뒤에만 확정 상태를 유지하고 실패하면 직전 상태로 되돌린 뒤 `recoveryNotice = '저장하지 못했습니다. 다시 시도해 주세요.'`를 설정한다.

- [ ] **Step 4: 컨트롤러 테스트 통과 확인**

Run: `flutter test test/app/lobby_controller_test.dart`
Expected: PASS

- [ ] **Step 5: 커밋**

```powershell
git add lib/app/lobby_controller.dart lib/game/systems/save_system.dart test/app/lobby_controller_test.dart
git commit -m "feat: add persistent lobby controller"
```

### Task 3: 인물·스테이지 선택 화면을 선택 전용으로 재사용

**Files:**
- Modify: `lib/app/character_select_screen.dart`
- Modify: `lib/app/stage_select_screen.dart`
- Modify: `test/app/character_select_screen_test.dart`
- Modify: `test/app/stage_select_screen_test.dart`

**Interfaces:**
- Consumes: 저장된 `initialCharacterId`, `initialStageId`
- Produces: `ValueChanged<String> onSelected`
- Removes: 선택 화면이 전투 시작을 직접 결정하는 책임

- [ ] **Step 1: 초기 선택과 완료 콜백 테스트 작성**

```dart
testWidgets('character picker starts at saved character and returns selection', (tester) async {
  String? selected;
  await tester.pumpWidget(MaterialApp(
    home: CharacterSelectScreen(
      initialCharacterId: exorcistDosa,
      unlockedCharacterIds: const {rookieConstable, exorcistDosa},
      onSelected: (value) => selected = value,
    ),
  ));
  expect(find.byKey(const Key('character-selected-exorcist_dosa')), findsOneWidget);
  await tester.tap(find.byKey(const Key('character-confirm')));
  expect(selected, exorcistDosa);
});

testWidgets('stage picker starts at saved stage and returns selection', (tester) async {
  String? selected;
  await tester.pumpWidget(MaterialApp(
    home: StageSelectScreen(
      initialStageId: moonlitAbandonedOffice,
      onSelected: (value) => selected = value,
    ),
  ));
  await tester.tap(find.byKey(const Key('stage-confirm')));
  expect(selected, moonlitAbandonedOffice);
});
```

- [ ] **Step 2: 기존 생성자와 키 때문에 실패하는지 확인**

Run: `flutter test test/app/character_select_screen_test.dart test/app/stage_select_screen_test.dart`
Expected: FAIL (새 생성자 인자 및 확인 키 부재)

- [ ] **Step 3: 두 화면의 공개 생성자와 버튼 문구 변경**

```dart
const CharacterSelectScreen({
  required this.initialCharacterId,
  required this.unlockedCharacterIds,
  required this.onSelected,
  super.key,
});

const StageSelectScreen({
  required this.initialStageId,
  required this.onSelected,
  super.key,
});
```

캐릭터 화면의 내부 `SaveSystem` 로드를 제거하고 전달된 해금 집합을 사용한다. 버튼 키와 문구를 각각 `character-confirm`/`선택 완료`, `stage-confirm`/`선택 완료`로 바꾸고 콜백에 선택 ID를 전달한다.

- [ ] **Step 4: 선택 화면 테스트 통과 확인**

Run: `flutter test test/app/character_select_screen_test.dart test/app/stage_select_screen_test.dart`
Expected: PASS

- [ ] **Step 5: 커밋**

```powershell
git add lib/app/character_select_screen.dart lib/app/stage_select_screen.dart test/app/character_select_screen_test.dart test/app/stage_select_screen_test.dart
git commit -m "refactor: reuse character and stage pickers from lobby"
```

### Task 4: 설정과 기록 화면

**Files:**
- Create: `lib/app/settings_screen.dart`
- Create: `lib/app/records_screen.dart`
- Create: `test/app/settings_screen_test.dart`
- Create: `test/app/records_screen_test.dart`

**Interfaces:**
- Consumes: `AudioSettingsController`, `SaveState`
- Produces: 로비가 push할 수 있는 실제 설정·기록 화면

- [ ] **Step 1: 화면 계약 테스트 작성**

```dart
testWidgets('settings updates music, effects, and vibration', (tester) async {
  final controller = await memoryAudioController();
  await tester.pumpWidget(MaterialApp(home: SettingsScreen(controller: controller)));
  expect(find.text('설정'), findsOneWidget);
  expect(find.byKey(const Key('music-volume')), findsOneWidget);
  expect(find.byKey(const Key('sfx-volume')), findsOneWidget);
  expect(find.byKey(const Key('vibration-enabled')), findsOneWidget);
});

testWidgets('records shows persisted totals and best time', (tester) async {
  final state = SaveState.defaults().copyWith(totalKills: 321, bestSurvivalSeconds: 245);
  await tester.pumpWidget(MaterialApp(home: RecordsScreen(state: state)));
  expect(find.text('누적 처치 321'), findsOneWidget);
  expect(find.text('최고 생존 4:05'), findsOneWidget);
});
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `flutter test test/app/settings_screen_test.dart test/app/records_screen_test.dart`
Expected: FAIL (화면 클래스 미정의)

- [ ] **Step 3: 설정 화면 구현**

`SettingsScreen`은 `AnimatedBuilder(animation: controller)` 안에서 `Slider` 두 개와 `SwitchListTile` 한 개를 렌더링한다. 키는 테스트의 세 키를 사용하고 콜백은 각각 `setMusicVolume`, `setSfxVolume`, `setVibrationEnabled`에 연결한다. 로비에서는 뒤로 가기로 닫히며 별도 저장 버튼을 만들지 않는다.

- [ ] **Step 4: 기록 화면 구현**

`RecordsScreen`은 `SaveState`에서 누적 처치, 최고 생존, 보스 격파, 완료 목표 수, 해금 무기 수를 읽어 한국어 레이블의 카드로 표시한다. 시간은 `분:초` 형식으로 변환한다.

- [ ] **Step 5: 화면 테스트 통과 확인**

Run: `flutter test test/app/settings_screen_test.dart test/app/records_screen_test.dart`
Expected: PASS

- [ ] **Step 6: 커밋**

```powershell
git add lib/app/settings_screen.dart lib/app/records_screen.dart test/app/settings_screen_test.dart test/app/records_screen_test.dart
git commit -m "feat: add lobby settings and records screens"
```

### Task 5: B안 관아 로비와 출진 흐름

**Files:**
- Create: `lib/app/lobby_screen.dart`
- Modify: `lib/app/pixel_survivor_app.dart`
- Delete: `lib/app/main_menu_screen.dart`
- Modify: `test/main_menu_screen_test.dart` (rename to `test/app/lobby_screen_test.dart`)
- Modify: `test/app/korean_strings_test.dart`
- Modify: `test/app/responsive_layout_test.dart`

**Interfaces:**
- Consumes: `LobbyController`, `AudioSettingsController`, `GameAudioService`, `TutorialProgressRepository`
- Produces: 앱 첫 화면, 인물/스테이지/설정/기록 이동, 현재 선택 기반 `GameScreen` 출진

- [ ] **Step 1: 로비 정보와 경로 테스트 작성**

```dart
testWidgets('lobby shows wallet, selection, and working destinations', (tester) async {
  final controller = LobbyController(store: MemorySaveStore(SaveState.defaults()));
  await controller.load();
  await tester.pumpWidget(MaterialApp(home: LobbyScreen(controller: controller)));

  expect(find.text('엽전 0'), findsOneWidget);
  expect(find.text('혼옥 0'), findsOneWidget);
  expect(find.text('신참 포졸'), findsOneWidget);
  expect(find.byKey(const Key('lobby-character')), findsOneWidget);
  expect(find.byKey(const Key('lobby-stage')), findsOneWidget);
  expect(find.byKey(const Key('lobby-settings')), findsOneWidget);
  expect(find.byKey(const Key('lobby-records')), findsOneWidget);
  expect(find.byKey(const Key('lobby-deploy')), findsOneWidget);
});

testWidgets('deploy launches game with persisted character and stage', (tester) async {
  final controller = LobbyController(store: MemorySaveStore(
    SaveState.defaults().copyWith(selectedCharacterId: exorcistDosa),
  ));
  await controller.load();
  await tester.pumpWidget(MaterialApp(home: LobbyScreen(controller: controller)));
  await tester.tap(find.byKey(const Key('lobby-deploy')));
  await tester.pumpAndSettle();
  final game = tester.widget<GameScreen>(find.byType(GameScreen));
  expect(game.playerSlot.characterId, exorcistDosa);
  expect(game.stageId, controller.state.selectedStageId);
});
```

- [ ] **Step 2: 로비 클래스 부재로 실패하는지 확인**

Run: `flutter test test/app/lobby_screen_test.dart`
Expected: FAIL (`LobbyScreen` 미정의)

- [ ] **Step 3: 로비 레이아웃 구현**

`LobbyScreen`은 `AnimatedBuilder`로 컨트롤러를 구독한다. 상단에는 계정 진행 자리(`수련 단계 0`), 엽전, 혼옥, 설정을 배치한다. 중앙에는 `AssetCatalog.lobby['government_office']`로 조회한 관아 장면 영역, 선택 캐릭터와 스테이지의 이름·최고 기록을 표시한다. 에셋이 준비되지 않았으면 `Color(0xff243b32)` 배경과 `Icons.account_balance`를 사용한다. 하단 중앙에 가장 큰 `출진` 버튼을 둔다.

오른쪽에는 `인물`, `기록`만 표시한다. 장비·수련·상점·도감·업적은 실제 후속 화면이 생기기 전까지 버튼을 만들지 않는다. 인물/스테이지에서 선택 완료 시 컨트롤러 저장을 기다린 뒤 로비로 pop한다. 설정과 기록은 Task 4의 화면을 push한다.

- [ ] **Step 4: 앱 루트를 로비로 교체하고 기존 메뉴 삭제**

`PixelSurvivorApp`이 `SaveSystem`을 주입한 `LobbyController`를 소유하고 `initState`에서 `unawaited(load())`, `dispose`에서 컨트롤러를 정리하게 한다. `home`을 `LobbyScreen`으로 교체한다. 전투 결과의 `popUntil(route.isFirst)`는 자동으로 로비로 돌아오므로 유지한다.

- [ ] **Step 5: 한국어와 화면 비율 회귀 테스트 갱신**

`korean_strings_test.dart`의 첫 화면을 로비로 바꾸고 렌더된 `Text`에 영문 제품 문구가 없는지 유지한다. `responsive_layout_test.dart`에서 16:9, 18:9, 19.5:9, 4:3 각각 로비를 펌프해 `tester.takeException()`이 null이고 `lobby-deploy`가 화면 안에 있는지 확인한다.

- [ ] **Step 6: 로비 관련 테스트 통과 확인**

Run: `flutter test test/app/lobby_screen_test.dart test/app/korean_strings_test.dart test/app/responsive_layout_test.dart`
Expected: PASS

- [ ] **Step 7: 커밋**

```powershell
git add lib/app test/app test/main_menu_screen_test.dart
git commit -m "feat: replace main menu with persistent government lobby"
```

### Task 6: 전체 게이트와 문서 근거

**Files:**
- Modify: `docs/master-development-todo.md`
- Modify: `docs/superpowers/plans/2026-07-16-lobby-meta-save-foundation.md`

**Interfaces:**
- Verifies: 스키마 1→2 보존, 로비 선택 저장, 네 경로 연결, 출진, 반응형 레이아웃

- [ ] **Step 1: 포맷과 정적 분석 실행**

Run: `dart format --output=none --set-exit-if-changed lib test`
Expected: exit 0

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 2: 전체 Flutter 테스트 실행**

Run: `flutter test`
Expected: 모든 테스트 PASS

- [ ] **Step 3: 웹과 Android 빌드 실행**

Run: `flutter build web`
Expected: exit 0, `build/web` 생성

Run: `flutter build apk --debug`
Expected: exit 0, `build/app/outputs/flutter-apk/app-debug.apk` 생성

- [ ] **Step 4: 마스터 TODO 근거 갱신**

`META-001`에는 로비에서 인물·스테이지 선택과 현재 상태 표시, `META-003`에는 기록 화면, `META-008`에는 스키마 1→2 마이그레이션 근거를 기록한다. 수련 구매와 재화 정산을 구현하지 않았으므로 관련 항목은 완료 처리하지 않는다. 이 계획의 완료된 체크박스를 `[x]`로 바꾼다.

- [ ] **Step 5: 변경 상태와 최종 diff 확인**

Run: `git status --short`
Expected: 계획된 파일만 수정됨

Run: `git diff --check`
Expected: 출력 없음

- [ ] **Step 6: 최종 커밋**

```powershell
git add docs/master-development-todo.md docs/superpowers/plans/2026-07-16-lobby-meta-save-foundation.md
git commit -m "docs: record lobby foundation verification"
```

## Self-Review

- Spec coverage: 첫 하위 프로젝트의 스키마 2, 빈 지갑·수련·상점 상태, 저장 복구, 선택 보존, 관아 로비, 인물·스테이지·설정·기록·출진 연결, 네 화면 비율 검증을 모두 태스크에 연결했다.
- Deferred by project boundary: 결과 엽전 정산, 혼옥 월드 드롭과 즉시 저장, 구매 원자성, 수련 보너스, 오프라인 상점 품목, 미구현 좌우 메뉴 화면은 후속 하위 프로젝트 범위다.
- Placeholder scan: 구현 대상 공개 타입과 메서드, 테스트 명령, 성공 조건을 명시했다. 메타 모델의 파싱 내부는 공개 계약과 허용 규칙을 고정하고 사적인 반복 코드는 구현자에게 맡겼다.
- Type consistency: `SaveStore` → `LobbyController` → `LobbyScreen` 의존 방향과 `selectedCharacterId`/`selectedStageId` 이름을 전 태스크에서 동일하게 사용한다.
