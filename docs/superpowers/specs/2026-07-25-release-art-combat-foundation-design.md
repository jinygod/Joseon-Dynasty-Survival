# 릴리스 아트·전투 감각 기반과 환도 수직 패스 설계

- 날짜: 2026-07-25
- 기준 커밋: `7e029ee`
- 제품 방향: 출시 가능한 가로형 모바일 조선 민속 판타지 뱀서라이크

## 범위 분해

전체 목표는 한 번에 변경하지 않고 다음 독립 패스로 진행한다.

1. 아트·에셋·전투 감각·UI 기준 문서와 전수 감사
2. 환도베기 수직 패스
3. 벽돌처럼 보이는 기존 투사체와 swept collision
4. 플레이어·몬스터 가시성과 hurtbox
5. 도감
6. 로비와 나머지 Material UI

이번 상세 구현 설계는 1과 2까지만 포함한다. 새 캐릭터, 새 무기, 게임 밸런스 재설계는 범위 밖이다.

## 선택한 접근

`AttackPresentationContract`를 시각과 판정의 단일 진실 공급원으로 도입한다. 기존 `AttackSpec`, `AttackVisualEvent`, `AttackVisualRegistry`를 한 번에 폐기하지 않고 환도 경로에서 먼저 계약을 검증한다.

다른 접근을 선택하지 않은 이유:

- 환도만 수치 패치하면 다른 무기에서 같은 불일치가 반복된다.
- Flame collision tree 전면 교체는 현재 성능·회귀 위험에 비해 범위가 크다.

## 환도 데이터 흐름

1. `HwandoExecutor`가 레벨, 원점, 방향, 피해, 범위를 고정한다.
2. 환도 presentation contract가 준비·타격·회복과 visual sector를 만든다.
3. 동일 contract가 10% inset된 hit sector를 만든다.
4. 게임 루프는 준비 중 판정을 하지 않고 활성 타격 구간에서만 대상과 교차를 검사한다.
5. 최초 교차점에서 `CombatContact`를 생성한다.
6. 피해, 넉백, 피격 VFX, hit stop, 사운드가 같은 contact를 소비한다.
7. 회복 구간에는 잔광만 재생하고 새 피해를 적용하지 않는다.

## 구성 요소

### `AttackTimeline`

- `windupSeconds`
- `activeSeconds`
- `recoverySeconds`
- 현재 단계와 정규화 진행률
- pause/resume 안전성

### `AttackVisualGeometry`

- sector origin, direction, radius, angle
- sprite pivot와 world scale
- visual bounds

### `AttackHitGeometry`

- visual geometry에서 inset 비율로만 생성
- 환도 기본 inset 10%
- 별도 임의 반경을 허용하지 않음

### `CombatContact`

- attack ID
- target ID/reference
- world contact point
- normal
- hit time
- damage/knockback metadata

### `HwandoVfxComponent`

- contract의 timeline과 geometry만 소비
- 새 투명 PNG 프레임을 표시
- 자체적으로 피해 대상을 선택하지 않음

### `CombatDebugOverlay`

- visual sector, active hit sector, enemy hurtbox, contact point를 개발 빌드에서 표시
- 릴리스에서는 생성하지 않음

## 에셋 사양

환도 기본 베기에는 다음 실제 PNG가 필요하다.

- 준비용 짧은 칼빛 4~6프레임
- 활성 부채꼴 검기 6프레임
- 회복 잔광 3~4프레임
- 접촉 베기/불꽃 5~6프레임

각 프레임은 128px 셀, 투명 배경, 화면 우측을 기본 진행 방향으로 한다. 먹빛 외곽, 아이보리 칼날 중심, 달빛 청색 검기, 접촉점의 제한된 금색·주홍을 사용한다. 생성 원본은 `art_source/generated/`, 채택 결과는 `assets/images/vfx/hwando/`에 저장한다.

## 타이밍 초기값

- 준비: 0.06초
- 활성 타격: 0.08초
- 회복: 0.10초
- 접촉 VFX: 0.15초
- 일반 hit stop: 0.03초

이는 공격 cooldown이나 피해량을 바꾸지 않는다. 실제 모바일 캡처에서 동작이 흐리거나 급하면 시각 타이밍만 조정하되 판정은 항상 같은 timeline을 따른다.

## 오류와 중단 처리

- 이미지 누락은 릴리스에서 Canvas fallback으로 대체하지 않고 계약 검증을 실패시킨다.
- pause, level-up, 사망 시 timeline과 새 피해 판정을 정지한다.
- 같은 attack instance가 같은 target에 두 번 적용되지 않게 hit set을 보관한다.
- contact VFX 생성 실패가 피해 중복이나 공격 중단을 만들지 않는다.

## 테스트

- 준비·회복 구간에서 피해 0
- 활성 구간 안쪽 대상 적중, 1px 바깥 대상 미적중
- visual sector 대비 hit sector 10% inset
- 방향 회전 시 PNG와 sector가 같은 각도
- 동일 대상 1회만 피해
- contact point가 target hurtbox와 visual sector 양쪽에 포함
- pause/level-up/사망 후 중복 피해 없음
- 기존 환도 레벨 1~6의 공격 횟수와 피해량 보존
- debug overlay가 release에서 생성되지 않음

## 실행 검증

1. 환도 gallery에서 8방향, 0.25배·1배 속도, 밝고 어두운 배경 검토
2. Chrome landscape 개발 실행
3. 적 1기와 밀집 적에서 visual/hit/hurt/contact overlay 캡처
4. 16:9와 19.5:9 모바일 캡처 비교
5. 가독성이나 접촉감이 부족하면 한 원인씩 PNG 또는 타이밍 재작업
6. 관련 테스트와 analyze
7. Android debug 또는 release 검증 빌드

## 완료 조건

- 도형 fallback 없이 실제 PNG가 표시된다.
- 준비·타격·회복이 눈으로 구분된다.
- 보이는 부채꼴 안에서만 적중하고 hitbox가 visual보다 10% 작다.
- 피격 VFX가 실제 contact point에 나타난다.
- 실제 landscape 모바일 캡처가 상용 게임 수준의 가독성과 접촉감을 보인다.
- 테스트, analyze, Android build 결과와 전후 스크린샷이 보고서에 기록된다.

## 설계 자체 검토

- placeholder/TODO/TBD 없음
- 새 무기나 밸런스 변경 없음
- 시각·판정 데이터 소유권이 하나로 정의됨
- 환도 외 대규모 마이그레이션은 후속 패스로 분리됨
- 실제 실행과 Android 검증이 완료 조건에 포함됨

