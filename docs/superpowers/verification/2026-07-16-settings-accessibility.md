# 설정·접근성 검증 기록

## 범위

- 음악, 효과음, 진동, 화면 흔들림, 피해 숫자, UI 크기의 단일 `GameSettings` 저장
- 기존 `AudioSettings` API와 세 SharedPreferences 키 호환·마이그레이션
- 실행 중 피해 숫자, 화면 흔들림, HUD 배율 반영
- 1차·2차 확인 뒤 메타 진행만 초기화하고 설정 보존

모든 Flutter 명령은 한글 경로의 shader compiler 충돌을 피하려고 저장소를 `V:`에, Flutter SDK를 `W:`에 임시 `subst`한 뒤 실행했다. 다른 작업의 드라이브 매핑은 변경하지 않았다.

## 결과

### 담당 focused suite

명령:

```powershell
W:\bin\flutter.bat test -r compact test/app/game_settings_repository_test.dart test/app/game_settings_controller_test.dart test/app/settings_screen_test.dart test/app/game_hud_settings_test.dart test/app/game_screen_settings_test.dart test/game/pixel_survivor_game_settings_test.dart test/game/audio_settings_repository_test.dart test/game/audio_settings_controller_test.dart test/app/audio_settings_audio_binding_test.dart
```

결과: exit 0, 27 tests passed. 토글·슬라이더·재실행 복원·레거시 이전·1/2차 취소·최종 초기화·설정 보존·게임 런타임 반영을 포함한다.

### 정적 분석

명령: `W:\bin\dart.bat analyze`

결과: exit 0, `No issues found!`

### 웹 빌드

명령: `W:\bin\flutter.bat build web`

결과: exit 0, `Built V:\build\web`; Wasm dry run도 성공했다.

### 전체 테스트

명령:

```powershell
W:\bin\flutter.bat test -r compact
W:\bin\flutter.bat test --concurrency=1 -r compact
```

두 실행 모두 350 tests passed, 7 tests failed. 일곱 실패는 모두 기존 Material 위젯 테스트에서 발생한 동일한 Flutter 환경 오류 `Asset 'shaders/ink_sparkle.frag' not found`이며 기능 assertion 실패는 없었다. 병렬도를 1로 낮춰도 동일했고, 작업 전 베이스라인도 같은 shader compiler 계열 오류로 전체 테스트가 시작되지 않았다.

### 포맷

`dart format --output=none --set-exit-if-changed lib test`는 기존 파일을 포함한 6개 파일의 Windows 줄바꿈 정규화를 변경으로 보고 exit 1을 반환했다. 명령 직후 `git diff --quiet -- lib test`는 exit 0이어서 실제 내용 diff는 없었다. 이는 저장소 `tool/release_check.ps1`가 명시적으로 허용하는 경우다.

## 리뷰 수정 재검증

리뷰 후 초기화 경로를 `LobbyController` 저장 큐로 통합해 열린 로비 state와 영속 저장을 하나의 순서로 갱신했다. 보류 중 선택 저장 뒤 초기화가 최종 상태가 되는 컨트롤러 테스트와 `로비 → 설정 → 초기화 → 복귀 → 후속 선택` 위젯 회귀 테스트를 추가했다.

HUD 루트 `Transform.scale`은 제거했다. SafeArea 안의 좌상단 pause와 좌하단 joystick 좌표는 고정하고, 텍스트·패딩·폭·아이콘·조이스틱 입력 크기에만 배율을 적용했다. 1.15배에서 안전영역 좌표, 138px 입력 영역, 실제 방향 입력을 검증한다.

설정 load 중 변경은 필드 단위로 영속 snapshot과 병합한 뒤 한 번 저장한다. 화면 흔들림을 끄면 현재 카메라 오프셋을 같은 호출에서 제거한다.

최종 ASCII 경로 검증 결과:

| 명령 | 결과 |
| --- | --- |
| 리뷰 focused suite | PASS, 24/24 |
| `flutter clean; flutter pub get; flutter test -r compact` | PASS, 362/362 |
| `dart analyze` | PASS, `No issues found!` |
| `flutter build web` | PASS, `build/web` 생성 및 Wasm dry run 성공 |

앞서 기록한 셰이더 자산 실패는 `flutter clean` 후 새 mapped asset bundle을 생성해 해소되었다. 로비 캐시 위험도 큐 통합으로 해소되었다.
