# 전 화면·전투 에셋 감사

- 감사 기준 커밋: `7e029ee`
- 대상: Flutter UI, Flame 전투 렌더링, 에셋 카탈로그, 모바일 golden
- 상태: 구현 전 기준선

## 요약

현재 프로젝트는 조선풍 공용 패널과 다수 PNG 전투 에셋을 보유하지만 릴리스 기준을 충족하지 못한다. 특히 환도는 PNG 궤적과 부채꼴 판정이 같은 타임라인에서 움직이지 않고, 일반 투사체는 이미지가 없을 때 타원 도형 fallback을 사용한다. UI에는 기본 Material 표면이 남아 있고 도감·스테이지·캐릭터 일부는 누락 에셋 또는 공유 atlas를 대표 이미지로 사용한다.

## P0: 전투 판정과 시각 불일치

| 항목 | 현재 구현 | 위험 | 대상 파일 |
|---|---|---|---|
| 환도 타임라인 | `windupSeconds=0`, 생성 즉시 피해 계산, VFX는 별도 lifetime | 준비·타격·회복과 실제 판정 불일치 | `lib/game/systems/hwando_executor.dart`, `lib/game/pixel_survivor_game.dart` |
| 환도 범위 | sector 수치와 PNG 유효 픽셀이 독립 | 보이지 않는 영역 피격 또는 보이는 검기 미피격 | `lib/game/combat/attack_geometry.dart`, `lib/game/components/hwando_vfx_component.dart` |
| 환도 접촉점 | 적 중심 방향만 사용, 실제 contact point 없음 | 피격 효과가 실제 접촉 위치를 설명하지 못함 | `lib/game/pixel_survivor_game.dart` |
| 적 hurtbox | 다수 공격이 `enemy.size.x / 2` 사용 | 투명 여백과 장식까지 몸통으로 판정 | `lib/game/pixel_survivor_game.dart`, `lib/game/components/enemy_component.dart` |
| 일반 투사체 | 현재 위치의 원형 거리 검사 | 빠른 이동 시 통과 누락 | `lib/game/components/projectile_component.dart` |
| 투사체 visual/hitbox | 기본 size 8, atlas 표시 크기 28 | 이미지 접촉과 실제 피격 거리 불일치 | `lib/game/components/projectile_component.dart` |

## P0: 임시 도형과 fallback

| 표현 | 상태 | 조치 |
|---|---|---|
| 일반 투사체 fallback 타원 | 릴리스 경로에 존재 | 각 무기 전용 PNG와 visual bounds 계약으로 교체 |
| `AttackEffectComponent` sector/circle/line Canvas 경로 | 환도 외 무기와 synergy에서 사용 | 전투 레지스트리 PNG로 이관, 디버그 도형만 별도 유지 |
| `WardAuraComponent` 단색 원과 고리 | 최종 장판처럼 보일 수 있음 | 등록된 장판 PNG만 렌더링하고 원은 debug bounds로 제한 |
| `TalismanPresentationComponent` 일부 원형 보조 표현 | PNG와 혼재 | 실사용 여부를 추적하고 잔존 원형 표현 제거 |
| VFX gallery의 원·사각 안내선 | 개발 전용 | 허용하되 릴리스에서 접근 불가 유지 |
| World debug 사각형 | 개발 전용 | 허용, release tree-shaking 검증 |

## P0: 에셋 누락과 잘못된 대표 이미지

| 항목 | 증거 | 조치 |
|---|---|---|
| 캐릭터 초상화 3종 | `AssetCatalog.characterPortraits` 경로가 현재 PNG 목록에 없음 | 실제 초상화 제작·등록 |
| 스테이지 카드 2종 | `stagePresentation` 경로가 현재 PNG 목록에 없음 | 각 스테이지 16:9 일러스트 제작 |
| 무기 도감 12종 | 모두 `weapon_effects_atlas_64.png` 전체를 가리킴 | 무기별 아이콘 제작 |
| 증강 도감 16종 | 모두 `combat_effects_atlas_64.png` 전체를 가리킴 | 증강별 아이콘 제작 |
| spirit jade | 코드 주석이 temporary art slot을 명시 | 전용 PNG 제작 |
| 산악 사냥꾼 | 64px 정적 임시 플레이어 이미지 | 최종 128px 애니메이션 시트 제작 |
| 다수 보스 | 하나의 `fallen_general_64.png` 공유 | 고유 보스 에셋 제작 |

## P1: 기본 Material UI 잔존

| 화면/구성요소 | 잔존 위젯 |
|---|---|
| 도감 | `AppBar` |
| 기록 | `AppBar`, `CircularProgressIndicator` |
| 금옥 상점 | `AppBar`, `ListTile` |
| 설정 | `AppBar`, `SwitchListTile` |
| 수련 | `AppBar` |
| 크레딧/라이선스 | `AppBar`, `Card`, `CircularProgressIndicator` |
| 계정 | `Card` |
| 첫 실행 안내 | `Card` |
| 게임 로딩/오류 | `CircularProgressIndicator`, `Card` |
| 일시정지 설정 | `SwitchListTile` |
| 로비 재화 | `ActionChip` |
| 로비 로딩 | `CircularProgressIndicator` |
| VFX gallery | `AppBar` — 개발 전용이지만 릴리스 접근 차단 필요 |

## P1: 가독성

- 플레이어와 적 스프라이트의 표시 크기는 개선됐지만 일부 적은 바닥과 명도·채도가 비슷하다.
- 쥐 떼는 모바일 축소 상태에서 작은 검은 덩어리로 읽힐 가능성이 높다.
- 환도 밝은 리본이 타격 프레임과 무관하게 보이면 공격 범위를 오해하게 한다.
- 장판의 반투명 단색 면이 배경 디테일을 가리고 속성 정체성이 약하다.
- 현재 세로 golden은 존재하지만 새 제품 목표인 landscape 전투·로비·도감 검증 세트가 부족하다.

## P1: 로비와 도감

- 로비 주요 구조는 커스텀화됐지만 재화 진입, 로딩, 오류 알림에 Material 기본 표현이 남아 있다.
- 도감은 세로 2열 카드 중심이며 landscape master-detail 구조가 아니다.
- 잠긴 실루엣은 단색 사각형과 Material 자물쇠로 표현된다.
- 누락 에셋 placeholder가 최종 화면에 노출될 수 있다.

## P2: 배경과 개발 표현

- `StageBackdropComponent`의 base drawRect는 배경 합성 기반으로 허용할 수 있으나 최종 화면에서 단색 면이 노출되지 않는지 확인해야 한다.
- 월드·chunk·camera debug 사각형은 개발 전용으로 유지한다.
- golden failure 이미지가 `test/app/failures`에 남아 있으므로 릴리스 산출물과 혼동하지 않게 관리한다.

## “벽돌처럼 보이는 기존 투사체” 추적

코드에 `brick` 무기 ID는 없다. 사용자 표현은 기존 일반 투사체의 generic fallback 또는 방향·스케일이 맞지 않는 atlas 표시를 가리킨다.

현재 generic projectile 경로를 사용하는 후보:

- 각궁: atlas row가 있지만 로딩 실패 시 타원 fallback
- 조총·화포: 전용 atlas row가 없어 항상 generic fallback 가능
- 수호매: 전용 atlas row가 없어 항상 generic fallback 가능
- 신기전: registry PNG가 있으나 로딩·등록 실패 시 fallback 가능

2차 패스에서는 실제 실행 캡처와 runtime weapon ID를 함께 표시해 정확한 후보를 확정하고, 확인된 무기에 전용 PNG와 swept collision을 적용한다.

## 기준선 테스트 기록

- 첫 전체 테스트: Flutter 3.44.4, 병렬 실행
- 결과: 1,110 통과, 11 실패
- 공통 실패: `Asset 'shaders/ink_sparkle.frag' not found`
- 단일 동시성 재실행: 3분 도구 제한으로 종료
- 판단: 소스 변경 전 환경/runner 문제이며 구현 회귀와 별도로 추적한다.
- 직전 `master` 최종 검증 기록: 1,121 통과, analyze 통과, web build 통과

## 구현 순서

1. 환도베기 단일 판정 계약, 실제 PNG, contact point, hit stop
2. 벽돌처럼 보이는 기존 투사체 runtime 식별, 전용 PNG, swept collision
3. 플레이어·몬스터 가시성 및 실제 hurtbox
4. 도감 전용 에셋과 landscape master-detail UI
5. 로비 및 전 화면 Material 기본 표면 제거
6. 남은 무기·VFX·아이콘을 같은 계약으로 이관

각 단계는 코드 테스트만이 아니라 실제 실행, 디버그 bounds 캡처, 모바일 스크린샷 검토, 관련 테스트, analyze, Android build를 통과해야 완료된다.

