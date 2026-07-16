# 메타 도감·기록 설계

## 범위

META-001~003은 로비에서 진입하는 캐릭터·무기·증강 도감과 기록 화면을 제공한다. 도감은 모든 항목의 잠금 상태, 해금 조건, 현재 진행률, 처음 확인하는 해금 항목의 `새 항목` 표시를 보여 준다. 기록 화면은 최고 생존 기록, 캐릭터별 승리 횟수, 무기별 사용 판수·처치·피해를 보여 주며 기록이 없을 때도 한국어 빈 상태를 표시한다.

보스, 설정, QA 런타임 파일과 `docs/master-development-todo.md`는 수정하지 않는다.

## 데이터 소유권

- `SaveState` schema v3가 캐릭터별 승리와 도감 확인 여부의 유일한 원천이다. `characterVictoryCounts`와 `seenCompendiumEntryIds`를 optional/default 필드로 추가한다. 이전 schema 0~3 저장에는 빈 값이 기본 적용되며 기존 필드는 그대로 보존된다.
- `TelemetryRepository`의 기존 `RunTelemetry` 이력이 무기 사용 기록의 유일한 원천이다. 새 저장 복제 필드를 만들지 않고 `MetaHistoryService`가 최대 50개 기존 이력에서 사용 판수, 처치, 피해를 집계한다.
- 최고 생존 기록은 기존 `SaveState.bestSurvivalSeconds`를 계속 사용한다.

## 도감 모델과 화면

`CompendiumService`는 콘텐츠 정의, `unlockGoals`, `ProgressionSystem.metricValue`를 결합해 `CompendiumEntry` 목록을 만든다. 시작 해금 항목은 `기본 해금`, 목표 보상 항목은 한국어 조건과 `현재/목표` 진행률을 가진다. 항목 키는 `character:<id>`, `weapon:<id>`, `augment:<id>` 형식으로 충돌을 방지한다.

`CompendiumScreen`은 `인물`, `무기`, `증강` 탭을 사용한다. 잠긴 항목은 자물쇠와 조건/진행률을, 해금 항목은 이름과 핵심 정보를 표시한다. 해금됐지만 `seenCompendiumEntryIds`에 없는 항목은 해당 방문에서 `새 항목` 배지를 보이고, 로비 컨트롤러가 표시된 해금 키를 저장한다. 다음 방문부터 배지는 사라진다.

## 기록 집계와 정산

`MetaProgressionService.settleRun`은 선택 캐릭터 ID를 받아 승리 결과일 때만 해당 캐릭터의 승리 횟수를 증가시킨다. `GameScreen`은 이미 소유한 `playerSlot.characterId`를 전달한다. 패배, 재시도, 텔레메트리 기록 실패는 승리 집계 규칙을 바꾸지 않는다.

`MetaHistoryService`는 각 런의 `weaponKillCounts`와 `weaponDamageTotals` 키의 합집합을 사용해 무기 사용 판수를 세고 값을 누적한다. 알려진 무기만 표시하며 콘텐츠 정의 순서를 유지한다. 이력이 비었거나 유효한 무기 키가 없으면 빈 목록을 반환한다.

## 화면과 오류 처리

로비 우측 메뉴에 `도감`과 `기록` 진입을 함께 둔다. 두 화면은 `SafeArea`와 스크롤 가능한 레이아웃을 사용해 휴대폰 세로·가로 제약에서 오버플로를 피한다. 텔레메트리 읽기 실패는 기록 화면에서 빈 기록으로 복구하고 앱을 종료시키지 않는다.

## 테스트

- schema v3 round-trip과 이전 저장의 optional/default 마이그레이션
- 승리만 캐릭터별 누적하고 기존 최고 기록을 보존하는 정산
- 기존 텔레메트리의 무기 사용 집계와 빈/손상 기록 복구
- 도감의 잠금, 한국어 해금 조건, 진행률, 새 항목 표시 및 열람 저장
- 로비의 도감/기록 진입, 한국어 문구, SafeArea와 작은 화면 오버플로
- focused test, 전체 analyze/test, web build를 ASCII 드라이브 경로에서 검증
