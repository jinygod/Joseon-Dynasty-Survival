# 도감과 메타 기록

## 화면

로비의 `도감`은 인물, 무기, 증강 전체 목록을 표시한다. 잠긴 항목은 한국어 해금 조건과 `현재 / 목표` 진행률을 표시하고, 새로 해금된 항목은 처음 도감을 연 방문에서 `새 항목`으로 표시된다. 로비의 `기록`은 최고 생존, 누적 기록, 캐릭터별 승리, 무기별 사용 판수·처치·피해를 표시한다.

## 저장 소유권

`SaveState` schema v3는 다음 optional 필드를 소유한다.

- `characterVictoryCounts`: 알려진 캐릭터 ID별 승리 횟수
- `seenCompendiumEntryIds`: `character:<id>`, `weapon:<id>`, `augment:<id>` 형식의 확인한 도감 키

기존 schema 0~3 저장에 필드가 없거나 값이 손상되면 빈 map/set으로 복구한다. 알려지지 않은 캐릭터와 도감 키, 음수 승리 횟수는 버린다. schema 버전은 3으로 유지한다.

무기 사용 기록은 `SaveState`에 복제하지 않는다. `TelemetryRepository`의 기존 최대 50개 `RunTelemetry` 이력이 유일한 원천이며, 기록 화면을 열 때 `MetaHistoryService`가 `weaponKillCounts`와 `weaponDamageTotals`를 집계한다. 이력을 읽을 수 없거나 유효한 무기 기록이 없으면 한국어 빈 상태를 표시한다.

## 런 정산

`GameScreen`은 현재 `PlayerSlot.characterId`를 `MetaProgressionService.settleRun`에 전달한다. 정산 결과가 승리이고 알려진 캐릭터일 때만 해당 승리 횟수를 1 증가시킨다. 최고 생존과 전체 승리는 기존 `ProgressionSystem`이 계속 소유하고, 무기 기록은 기존 런 텔레메트리 저장 흐름이 소유한다.
