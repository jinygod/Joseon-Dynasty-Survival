# UI 시각 감사

작성일: 2026-07-24
기준 커밋: `b71e6c0`
기준 화면: 현재 390×844 웹 모바일 렌더링과 `test/app/goldens`

## 요약

현재 로비는 전용 배경 일러스트, 조선풍 서체, 금색 프레임을 사용하지만 나머지 비전투 화면은 기본 `Scaffold`, `AppBar`, `Card`, Material 아이콘에 의존한다. 동일 게임 안에서 로비와 선택·도감·기록·결과 화면이 서로 다른 제품처럼 보이는 것이 가장 큰 문제다.

캐릭터 및 스테이지 선택 화면에는 깨진 한글 문자열이 소스에 남아 있으며, 기존 골든은 가로형 데스크톱 구조를 기준으로 한다. 모바일 SafeArea 자체는 여러 화면에서 사용하지만 본문, 고정 하단 행동 버튼, 하단 탐색 영역을 공통 구조로 분리하지 않아 작은 Safari 화면에서 겹침과 잘림 위험이 있다.

## 화면별 감사

| 화면 | 진입 경로 | 관련 Dart 파일 | 현재 공통 위젯 | 이미지 에셋 | 고정 높이·너비 | SafeArea | 스크롤 및 하단 겹침 | 현재 색상·폰트 | 현재 문제 | 재사용 가능 요소 | 우선순위 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 로비 | 앱 시작 → 로비 | `lib/app/lobby_screen.dart`, `lobby_top_command_bar.dart`, `lobby_battle_stage.dart`, `lobby_navigation_dock.dart` | `JoseonGameButton`, 로비 전용 3개 위젯 | 조선 관아 배경, 플레이어 이미지 | 전투 무대 522px, 하단 독 93px | 적용 | 본문만 스크롤되지만 낮은 화면에서 전투 무대와 출진 버튼 압축 필요 | 남색·아이보리·금색, 조선풍 제목체 | 캐릭터 아래 녹색 원, 자원·설정 프레임 불일치, 수련 진입점 부재 | 배경, 그라데이션, 전투 무대 구성, 출진 버튼 | P0 |
| 캐릭터 선택 | 로비 하단 `인물` | `lib/app/character_select_screen.dart` | `AccessibleStatusBadge` | 실제 캐릭터 이미지 미사용 | 가로 3열, 24px 고정 외곽 여백 | 적용 | 카드 행이 모바일 폭에서 과밀, 완료 버튼은 본문 Column 하단 | 기본 Material + 화면 내부 색상 직접 지정 | 깨진 한글, 세로로 길고 좁은 카드, Material 아이콘, 공격력 100% 표기, 이미지 부재 | 캐릭터 정의·잠금 상태·선택 저장 흐름 | P0 |
| 스테이지 선택 | 로비 하단 `지도` | `lib/app/stage_select_screen.dart` | 없음 | 타일 atlas만 있고 선택 카드용 삽화 없음 | 가로 카드 2개 + 우측 상세 2:3 구조 | 적용 | 세로 모바일에서 구조가 성립하지 않음 | 녹색·청색 카드와 Material 아이콘 | 깨진 한글, 카드와 상세·버튼 분리, 모바일 세로 대응 부재 | 스테이지 정의·잠금 상태·선택 저장 흐름 | P0 |
| 도감 | 로비 하단 `도감` | `lib/app/compendium_screen.dart` | 기본 TabBar·Card | 카탈로그 에셋 일부 연결 가능 | 고정 큰 크기 없음 | 적용 | 탭별 ListView, 하단 독과는 별도 route | 기본 테마와 Material Card | 큰 회색 카드 목록, 잠금 항목에 자물쇠와 콘텐츠가 동시에 노출될 가능성, 한 화면 정보 밀도 낮음 | 도감 데이터·새 항목 상태·탭 구조 | P1 |
| 기록 | 로비 하단 `기록` | `lib/app/records_screen.dart` | `_SummaryCard` | 실제 초상·무기 이미지 미사용 | 너비 기준 열 수만 변경 | 적용 | 전체 SingleChildScrollView | 흰 Card, 적색 Material 아이콘 | 통계 앱처럼 보임, 요약 카드가 크고 무기·캐릭터 정체성이 약함 | 기록 집계 데이터·반응형 열 수 | P1 |
| 수련 진입 | 현재 직접 진입 불가 | `lib/game/models/meta_progress.dart`, `lib/game/content/meta_progress_definitions.dart`, `lib/game/systems/save_system.dart` | 없음 | 전용 UI 에셋 없음 | 해당 없음 | 해당 없음 | 해당 없음 | 해당 없음 | 데이터 모델은 있으나 화면과 로비 진입점이 없음 | `TrainingProgress`, 공통/캐릭터 수련 노드 ID | P1 |
| 전투 HUD | 출진 → 전투 | `lib/app/game_hud.dart`, `game_screen.dart`, `virtual_joystick.dart` | 전투 HUD 내부 전용 위젯 | 무기·경험치 에셋 일부 | 64px 상단 패널 중심 | 적용 | 화면 고정 overlay, 카메라와 분리 | 짙은 남색·아이보리·금색 | 방향은 맞지만 처치 수 의미가 약하고 별 등급 규칙이 공통화되지 않음 | 축소 HUD 구조, 고정 overlay, 투명 조이스틱 | P1 |
| 전투 바닥·배경 | 전투 월드 | `stage_tile_batch_component.dart`, `stage_backdrop_component.dart`, `stage_visual_spec.dart`, `stage_chunk_streamer.dart` | 청크·배치 렌더링 | 스테이지별 128px tile atlas, props | 512px 청크 | 해당 없음 | 카메라 월드 좌표 | 스테이지별 아트 팔레트 | 큰 사각 타일 경계와 유사한 장식 반복이 눈에 띔, 기본 타일과 decal 역할 혼재 | 고정 시드, 청크 스트리밍, batch 구조 | P0 |
| 레벨업 선택 | 경험치 충족 → overlay | `lib/app/level_up_overlay.dart` | 선택 카드 내부 전용 구성 | 무기·증강 카탈로그 연결 가능 | LayoutBuilder 사용 | 적용 | overlay 내부 카드 영역 | 전투 UI 계열 | 무기 등급 표시가 다른 화면과 동일 규칙을 보장하지 않음 | 기존 선택 로직과 반응형 분기 | P1 |
| 일시정지 | 전투 중 일시정지 | `lib/app/pause_menu_overlay.dart` | 기본 Card | 없음 | 중앙 Card | 적용 | overlay | 아이보리 Card + 남색 배경 | 로비보다 Material dialog에 가까움, 빌드·무기 정보 밀도 부족 | 일시정지/재개/나가기 흐름 | P1 |
| 런 종료 | 승리·패배 후 | `lib/app/run_summary_screen.dart` | 내부 결과 섹션 | 실제 무기 이미지 미사용 | ListView | 적용 | 전체 목록 스크롤 | 흰 배경, 기본 버튼, 상태별 amber/red | 게임 결과보다 일반 보고서처럼 보임, 별 등급과 무기 시각 언어 부재 | 결과 데이터와 저장·동기화 흐름 | P1 |

## 공통 원인

1. 로비 전용 시각 시스템이 다른 route로 확장되지 않았다.
2. `JoseonUiTheme`는 존재하지만 패널·탭·카드·자원 칩·고정 행동 영역 토큰이 부족하다.
3. 캐릭터·스테이지·무기 이미지 경로가 화면 모델과 직접 연결되지 않거나 서로 다른 항목이 같은 임시 이미지를 공유한다.
4. 캐릭터·스테이지 선택 소스에 문자 인코딩이 깨진 문자열이 남아 있다.
5. 기존 선택 화면 골든이 16:9 가로 화면 중심이라 세로 모바일 회귀를 막지 못한다.
6. 무기 1~6레벨을 표현하는 공통 위젯이 없어 화면마다 숫자 또는 임의 표현을 사용한다.
7. 바닥 기본 변형과 희귀 decal의 빈도·배치 책임이 분리되지 않아 체커보드와 반복 무늬가 강조된다.

## 재사용 원칙

- 로비 배경, 캐릭터·몬스터·VFX, 스테이지 tile atlas는 유지한다.
- 로비의 남색·아이보리·금색과 조선풍 제목 서체를 전역 토큰의 기준으로 삼는다.
- 기존 Navigator 경로, 선택 저장 콜백, `LobbyController`, `TrainingProgress`, 전투 overlay 분리는 유지한다.
- 화면별 임시 색상과 기본 Material Card만 교체하며 게임 밸런스·스폰·저장 데이터는 변경하지 않는다.

## 수정 우선순위

1. 깨진 한글과 모바일 선택 화면 구조
2. 공통 Scaffold·TopBar·Panel·Button·Tab·Card·별 등급
3. SafeArea 및 고정 하단 행동 영역
4. 로비 수련 진입과 비전투 화면 통일
5. 전투 타일 반복·이음새와 HUD·overlay 통일
6. 세 가지 모바일 크기 골든과 전체 회귀 검증
