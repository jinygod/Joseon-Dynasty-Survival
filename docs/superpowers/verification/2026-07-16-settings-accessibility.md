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

## 잔여 위험

- 이 환경의 Flutter 3.44.4 셰이더 테스트 자산 문제 때문에 전체 suite의 완전한 exit 0 증거는 없다.
- 진행 초기화는 영속 `SaveState`를 즉시 기본값으로 바꾸지만, 이미 화면에 떠 있는 로비 컨트롤러의 캐시는 다음 `load()` 또는 앱 재실행까지 이전 값을 표시할 수 있다. 설정 데이터 자체는 별도 키에 남는다.
