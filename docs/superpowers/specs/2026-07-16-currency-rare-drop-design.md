# 엽전 정산과 혼옥 희귀 드롭 설계

## 1. 목적과 범위

이 하위 프로젝트는 한 판의 플레이가 로비의 영구 재화로 이어지게 한다.

- 패배와 승리 모두 생존 시간과 전투 성과에 따라 엽전을 지급한다.
- 정예와 보스는 낮은 확률로 혼옥을 월드에 떨어뜨린다.
- 혼옥은 플레이어가 직접 수거하며 수거 즉시 영구 저장한다.
- 결과 화면은 이번 판에 정산된 엽전과 수거한 혼옥을 보여준다.

수련 구매, 상점 거래, 새 정예 종류, 새 스테이지, 최종 혼옥 이미지는 이 범위에 포함하지 않는다.

## 2. 사용자 결정과 기본값

- 혼옥은 정예·보스 처치 위치에 월드 드롭으로 생성한다.
- 플레이어가 획득 범위 안으로 이동해야 수거를 시작한다.
- 정예 혼옥 드롭률은 `0.01`, 보스 반복 드롭률은 `0.25`다.
- 최초 보스 처치 보상은 혼옥 1개를 보장한다.
- 보스 처치 뒤 3초간 보상 수거 시간을 제공한다.
- 3초가 지나도 남은 보스 혼옥은 자동 수거한다.
- 밸런스 값은 한 파일에서 숫자만 바꾸어 조정할 수 있어야 한다.

## 3. 중앙 밸런스 정의

`lib/game/balance/meta_reward_balance.dart`가 다음 값을 공개한다.

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
```

엽전 공식은 각 판마다 다음 값을 더한 뒤 내림한다.

```text
20
+ 생존 초 × 0.35
+ 전체 처치 수 × 0.4
+ 정예 처치 수 × 4
+ 보스 처치 시 60
```

목표 범위는 일반적인 패배 80~150개, 보스 승리 180~260개다. 수치는 `MetaRewardBalance`만 수정하며 서비스·UI·테스트에 숫자를 중복하지 않는다.

## 4. 데이터 모델

### 런 데이터

`RunStatsTracker`는 전체 처치와 별도로 `eliteKills`와 성공적으로 저장된 `spiritJadeCollected`를 기록한다. `RunResult`에 두 값을 추가하되 기본값은 0으로 두어 기존 생성 코드와 텔레메트리 스키마를 깨지 않는다.

### 영구 저장

`SaveState`에 `claimedRewardIds: Set<String>`을 추가한다. 최초 보스 혼옥의 ID는 `first_boss_spirit_jade`로 고정한다. 스키마 2가 아직 출시되지 않았으므로 스키마 번호는 2를 유지하고 필드가 없는 저장은 빈 집합으로 읽는다.

혼옥 수거 저장은 다음 세 값을 하나의 `SaveState` 쓰기로 반영한다.

- 혼옥 잔액 `+1`
- 필요하면 `first_boss_spirit_jade` 수령 ID 추가
- 다른 해금·기록·선택·수련·상점 필드 보존

## 5. 구성 요소와 책임

### `MetaRewardPolicy`

부작용이 없는 순수 정책이다.

- `coinForRun(RunResult)`
- `shouldDropSpiritJade({isElite, isBoss, firstBossRewardAvailable, roll})`

확률 판정은 호출자가 전달한 `roll` 값으로 수행해 고정 시드 없이도 경계값을 테스트할 수 있다. 최초 보스 보상이 가능하면 `roll`과 관계없이 드롭한다.

### `MetaProgressionService`

`SaveStore`와 `ProgressionSystem`을 사용하며 모든 영구 저장을 내부 큐로 직렬화한다.

- `loadFirstBossRewardAvailability()`
- `collectSpiritJade({required String pickupId, required bool claimsFirstBossReward})`
- `settleRun(RunResult)`

같은 `pickupId`의 동시 요청은 한 번만 처리한다. 혼옥 수거는 최신 저장을 다시 읽고 지갑과 보상 ID를 함께 저장한 뒤 성공을 반환한다. 결과 정산은 모든 앞선 수거 저장 뒤에 실행하고, 최신 저장에 기록·해금·엽전을 한 번에 반영한다.

`settleRun`은 `RunSettlement`을 반환한다.

- `before`: 정산 직전 저장
- `after`: 정산 완료 저장
- `coinEarned`: 이번 판 엽전
- `unlocks`: 이번 판 신규 해금

### `SpiritJadeComponent`

정예 또는 보스 위치에 생성되는 Flame 컴포넌트다.

- 중앙 에셋 카탈로그의 `effects/spirit_jade` 키를 사용한다.
- 현재는 기존 16px 보석 이미지를 색상 구분 가능한 임시 혼옥 표현으로 재사용하고 이후 경로만 교체한다.
- 플레이어 획득 범위와 겹치면 수거 콜백을 한 번 호출한다.
- 저장 중에는 중복 충돌을 막고 시각적으로 맥동한다.
- 저장 성공 시 제거하고 런의 혼옥 수를 1 증가시킨다.
- 저장 실패 시 1초 뒤 다시 수거할 수 있는 상태로 돌아간다.

## 6. 전투와 보스 종료 흐름

1. 적의 사망이 최초 기록될 때 `isElite`와 `isBoss`를 `RunStatsTracker`에 전달한다.
2. 정예 또는 보스면 `MetaRewardPolicy`로 혼옥 드롭을 판정한다.
3. 드롭이 결정되면 적의 사망 위치에 `SpiritJadeComponent`를 하나 생성한다.
4. 일반 전투 중 혼옥을 수거하면 `MetaProgressionService.collectSpiritJade`가 즉시 저장한다.
5. 보스가 죽으면 즉시 승리 결과로 이동하지 않고 `rewardCollection` 상태로 전환한다.
6. 남은 일반 적과 공격체를 제거하고 플레이어 피해를 막되 이동은 3초 동안 허용한다.
7. 3초 안에 보스 혼옥을 직접 수거할 수 있다.
8. 시간이 끝나면 남은 보스 혼옥의 수거 저장을 자동 요청한다.
9. 자동 저장이 성공한 뒤 승리 결과를 확정한다. 실패하면 1초 간격으로 재시도하며 HUD에 `혼옥 저장 재시도 중`을 표시한다.

보스 드롭이 발생하지 않은 반복 승리라면 보상 대기 상태는 즉시 종료한다. 최초 보상 또는 25% 드롭이 있을 때만 3초 수거 시간을 제공한다.

## 7. 결과 정산과 화면

`GameScreen`은 기존의 직접 `SaveSystem` 쓰기를 제거하고 `MetaProgressionService.settleRun`을 호출한다. 정산 저장이 성공한 뒤에만 결과 화면으로 이동한다.

결과 화면에는 기존 생존·처치·레벨 아래에 `이번 판 보상` 구역을 추가한다.

- `엽전 +N`
- 혼옥을 한 개 이상 수거한 경우 `혼옥 +N`

결과에서 로비로 돌아오거나 재도전하기 전 저장은 이미 끝난 상태다. 로비로 복귀하면 `LobbyController.load()`를 다시 호출해 새 잔액과 기록을 표시한다.

## 8. 오류 처리와 중복 방지

- 혼옥 저장 실패: 컴포넌트를 제거하거나 런 수치를 올리지 않고 재수거 가능 상태로 되돌린다.
- 보스 자동 수거 실패: 결과 화면으로 넘어가지 않고 1초 간격으로 재시도한다.
- 결과 엽전 저장 실패: 결과 화면 대신 `보상 저장에 실패했습니다` 안내와 `다시 시도` 버튼을 표시한다.
- 중복 충돌: 컴포넌트의 수거 중 상태와 서비스의 `pickupId` 집합으로 이중 지급을 막는다.
- 앱 종료: 저장 성공한 혼옥만 보존하며 결과 정산 전에 종료된 엽전은 지급하지 않는다.
- 손상 저장: 기존 스키마 2 복구 규칙을 유지하고 음수 잔액을 0으로 복구한다.

## 9. 테스트와 검증

사용자가 요청한 최소 테스트 원칙에 따라 규칙과 저장 경계에 집중한다.

- 엽전 공식의 패배·승리 대표값 2건
- 정예 1%, 보스 25%, 최초 보스 보장 경계값
- 같은 `pickupId`의 중복 수거가 혼옥을 한 번만 지급
- 최초 보상 ID와 혼옥 잔액이 한 저장에 반영
- 저장 실패 시 혼옥 컴포넌트가 사라지지 않음
- 보스 드롭이 있을 때 3초 수거 상태와 자동 수거 후 승리
- 결과 정산이 기록·해금·엽전을 한 저장에 반영
- 결과 화면의 엽전·혼옥 표시
- 로비 복귀 후 최신 지갑 재로드

로컬 `flutter_tester.exe`의 Windows `0xc0000409` 충돌이 계속되면 테스트 소스 정적 분석, 전체 `dart analyze`, 웹 빌드, 영문 Pub 캐시 기반 Android 디버그 APK 빌드를 필수 게이트로 사용하고 런타임 테스트 미실행을 문서에 남긴다.

## 10. 완료 기준

- 패배와 승리 모두 공식에 맞는 엽전을 한 번만 지급한다.
- 혼옥은 정예·보스 위치에서 보이고 직접 수거할 수 있다.
- 최초 보스 처치 보상은 결과 화면 전 반드시 저장된다.
- 수거 실패와 중복 충돌이 지갑을 잘못 증가시키지 않는다.
- 결과 화면과 복귀한 로비가 동일한 재화 잔액을 반영한다.
- 밸런스 조정은 `MetaRewardBalance`의 상수만 수정하면 된다.
