# 환도 출시 세로 슬라이스 검증 보고서

검증일: 2026-07-25  
대상 브랜치: `codex/release-art-combat`

## 결과

기본 환도 베기는 준비 0.06초, 타격 0.08초, 회복 0.10초의 단일 타임라인을
사용한다. PNG 애니메이션과 부채꼴 판정은 같은
`AttackPresentationContract`에서 생성하며 실제 hit sector는 visual sector보다
10% 작다. 타격은 active 구간에서만 발생하고 접촉 이펙트는 적 중심이 아니라
부채꼴과 hurtbox가 만나는 지점에 생성된다.

실행 검증 중 발견한 다음 결함을 수정했다.

- 환도 PNG가 컴포넌트 중심축을 두 번 빼 우상단으로 잘리던 피벗 오류
- 갤러리가 재빌드될 때마다 `onGameResize`가 공격을 재시작해 프레임 0에
  고정되던 오류
- Flame 업데이트 중 `ValueNotifier`가 빌드를 다시 요청해
  `setState() or markNeedsBuild() called during build`를 반복하던 오류
- `Step`이 실제 0.24초 타임라인이 아니라 1초를 기준으로 점프하던 오류
- 갤러리의 밝은/어두운 배경 전환이 GameWidget 배경에 반영되지 않던 오류

수정 후 새 콘솔 오류는 관찰되지 않았다. 브라우저 세션에 남아 있던 마지막
과거 오류의 시각은 2026-07-24 23:51:27 UTC였으며, 최종 빌드 재실행 이후 같은
오류가 추가되지 않았다.

## 시각 증거

- 어두운 배경: `art_source/review/hwando/hwando_gallery_dark.png`
- 밝은 배경: `art_source/review/hwando/hwando_gallery_light.png`
- visual/hit/hurt/contact 오버레이:
  `art_source/review/hwando/hwando_debug_contact.png`
- 실제 전투 16:9, 960x540:
  `art_source/review/hwando/hwando_combat_16_9.png`
- 실제 전투 19.5:9, 932x430:
  `art_source/review/hwando/hwando_combat_19_5_9.png`
- 결정론적 골든:
  `test/app/goldens/hwando_release_landscape_16_9.png`

이전 상태는 환도 베기가 임시 도형 또는 피벗이 어긋난 스프라이트로 보였고,
접촉 위치를 실행 화면에서 확인할 수 없었다. 현재 갤러리 캡처에서는 청록
visual sector, 그 안쪽의 적색 hit sector, 아이보리 hurtbox, 자홍 contact point를
동시에 확인할 수 있다.

## 결정론적 배치

고정 시드 `960540`을 사용했다. 퇴마 도사 기준 오른쪽을 공격 방향으로 두고
산적 세 명을 다음 월드 오프셋에 배치했다.

- 내부: `(46, -18)`
- 경계: `(70, 0)`
- 외부: `(104, 20)`

골든에서 내부와 경계 대상은 타격 플래시가 보이고, 외부 대상은 원래
스프라이트를 유지한다. 카메라와 HUD를 포함한 전체 960x540 화면을 캡처했다.

## 집중 검증

- `test/game/hwando_vfx_component_test.dart`
- `test/game/vfx_gallery_game_test.dart`
- `test/app/vfx_gallery_screen_test.dart`
- `test/app/balanced_casual_combat_golden_test.dart`

환도 컴포넌트의 회전축, 준비/타격/회복 전환, 이미지 사전 로딩, 한 프레임
전진, 재빌드 중 상태 발행, 실제 가로형 골든을 검증한다.

## 휴대폰 확인 항목

- 932x430급 작은 가로 화면에서 플레이어와 쥐 실루엣이 충분히 큰지
- 실제 손가락 입력에서 조이스틱이 캐릭터와 전투 정보를 가리지 않는지
- 연속 공격 시 흰색 타격 플래시가 환도 궤적을 과도하게 덮지 않는지
- OLED 밝기에서 청백색 궤적이 석재 배경과 밝은 배경 모두에서 번지지 않는지
- 진동과 효과음이 0.03초 hit stop과 같은 순간에 느껴지는지

## 최종 품질 게이트

Task 9의 `flutter analyze`, 전체 `flutter test`, Android debug APK 결과와
아티팩트 해시는 최종 실행 후 이 문서에 추가한다.
