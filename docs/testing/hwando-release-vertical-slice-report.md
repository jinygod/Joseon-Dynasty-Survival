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

2026-07-25에 다음 게이트를 실행했다.

- `flutter analyze`: `No issues found!`
- `flutter test`: 1,152개 통과, 실패 0
- `flutter build apk --debug`: 성공
- APK:
  `build/app/outputs/flutter-apk/app-debug.apk`
- APK 크기: 180,627,157 bytes
- APK SHA-256:
  `BA2E29F0C2561EE9CE6B9A7B311F37D34E9D20FC08E13B23FBD84143540763F5`

첫 전체 테스트에서는 오래된 상태 계약과 5분 고정 시드 스냅샷 때문에
4개가 실패했다. 승인된 환도 시트의 상태를 `ready`/`approved`로 갱신하고,
컴포넌트 자체 회전을 적용하는 렌더 테스트가 `renderTree`를 사용하도록
고쳤다. 5분 성능 스냅샷은 현재 결정론적 결과로 갱신했다. 이후 네 실패
파일을 독립 실행해 25개가 통과했고, 전체 1,152개 테스트를 다시 실행해
실패 0을 확인했다.

## 고정 시드 5분 성능 비교

| 항목 | 이전 기준 | 현재 측정 |
| --- | ---: | ---: |
| 평균 활성 적 | 26.662 | 28.365 |
| 후반 평균 활성 적 | 49.440 | 53.934 |
| 최대 활성 적 | 86 | 84 |
| 최대 mounted component | 363 | 365 |
| 최대 retained owner | 30 | 30 |
| 최대 memory proxy | 383 | 391 |
| 최대 투사체 | 19 | 23 |
| 최대 데미지 숫자 | 24 | 22 |
| 최대 전투 이펙트 | 27 | 25 |
| 인구 예산 위반 샘플 | 0 | 0 |
| 메모리 proxy 위반 샘플 | 0 | 0 |

고정 dt 논리 FPS는 59.9988이었다. 이 테스트는 실제 기기 GPU FPS나 p95
frame time을 대신하지 않으며, 구성요소 수와 시뮬레이션 예산 회귀를
검출한다. 실제 Chrome 960x540 및 932x430 이동/교전에서는 눈에 보이는
급락을 관찰하지 않았지만 정량 GPU 측정은 Android 기기에서 남아 있다.

`flutter devices`에는 Chrome과 Edge만 있었고 Android 실기기나 AVD는
없었다. `flutter emulators`도 사용 가능한 AVD가 없다고 보고했다. 따라서
APK 생성과 해시 검증까지 완료했으며, 다음 항목은 Android 실기기 전용
확인으로 남는다.

최종 증분 APK 빌드에서는 `jni-1.0.0`의 CMake가 한글 Windows 사용자
경로를 ANSI 문자열로 잘못 해석해 한 차례 실패했다. 사용자 전역 설정은
변경하지 않고 해당 빌드 프로세스에만
`PUB_CACHE=D:\CodexCaches\Pub`를 지정해 영문 경로에서 재빌드했으며 성공했다.

- 준비/타격/회복의 체감 구분과 타격 전 선행 데미지 부재
- 칼날과 적 교차점의 접촉 이펙트
- 빠른 방향 변경 시 이미지와 hitbox의 동시 회전
- 일시정지/레벨업 중 중복 데미지 부재
- 밀집 다중 타격의 실제 GPU frame pacing, 진동, 효과음
