# 로컬 플레이 테스트 안내

이 문서는 Windows에서 조선시대 서바이벌의 가로 화면 5분 런을 확인하기 위한 안내다.

## Current Test Scope

- Automated validation is available with `flutter test`.
- A web build is available with `flutter build web`.
- `flutter run -d chrome` may hit a Flutter shader compilation issue when the
  Flutter SDK is loaded from a Korean user path. Use the ASCII `subst F:`
  mapping below before trying Chrome.

## Stable Windows Procedure

Open PowerShell and run:

```powershell
New-Item -ItemType Directory -Force -Path C:\codex-tmp | Out-Null
$env:TEMP = "C:\codex-tmp"
$env:TMP = "C:\codex-tmp"

subst F: "$env:USERPROFILE\source\flutter"
$env:Path = "F:\bin;$env:Path"

subst P: "C:\Users\전성진\Documents\뱀서라이크게임"
Push-Location P:\

flutter pub get
dart analyze
flutter test
flutter build web
flutter build apk --debug

Pop-Location
subst P: /D
subst F: /D
```

If `F:` or `P:` is already in use, choose another unused ASCII drive letter and
update the commands consistently.

## Android Preparation

Android builds can be prepared on Windows. Install and configure:

- Android Studio
- Android SDK
- Android emulator, or a physical Android device with USB debugging enabled

Run `flutter doctor` and resolve Android toolchain warnings before relying on
Android test results.

Android SDK 약관은 사용자 본인이 아래 명령으로 확인하고 동의해야 한다.

```powershell
flutter doctor --android-licenses
```

## iOS Preparation

iOS builds require a MacBook or other Mac with Xcode installed. Clone the same
GitHub branch on the Mac, then use the same Flutter version as the Windows
environment before building.

## 핵심 플레이 체크

1. Pull the latest repository changes:

   ```powershell
   git pull --ff-only
   ```

2. Confirm the expected branch:

   ```powershell
   git branch --show-current
   ```

3. 위 Windows 절차를 실행한다.
4. 웹 서버를 실행하고 `http://127.0.0.1:8765/`을 연다.
5. 가로 화면에서 이동, 자동 공격, 경험치 획득, 레벨업 선택을 확인한다.
6. 환도 베기, 각궁 사격, 부적 투척, 벽력진천뢰의 공격 방식과 레벨 변화를 확인한다.
7. 04:30 보스 등장, 보스 체력 바, 돌진/부채꼴 예고, 저체력 소환을 확인한다.
8. 보스를 처치해 승리 결과와 최종 무기 레벨을 확인한다. 사망 시에는 패배가 표시되어야 한다.
9. 다시 시작했을 때 시간, 레벨, XP, 적, 처치 수, 보스 상태가 모두 초기화되는지 확인한다.

## Chrome 오디오 체크

Chrome은 페이지가 열린 직후의 자동재생을 차단하므로 메인 화면은 첫 입력 전까지 무음이 정상이다.

1. `출진 준비`를 한 번 눌러 확인음과 메뉴 음악이 들리는지 확인한다.
2. 캐릭터와 스테이지를 선택해 게임에 진입하면 전투 음악으로 바뀌는지 확인한다.
3. 환도·각궁·부적·벽력진천뢰가 실제 발사될 때 서로 다른 공격음이 들리는지 확인한다.
4. 피격, 치명타, 적 사망, 경험치 획득, 레벨업과 보스 경고 효과음을 확인한다.
5. 일시정지하면 음악·효과음이 멈추고 `계속하기`를 누르면 다시 재생되는지 확인한다.
6. 보스 등장, 승리, 패배에서 각각 음악이 전환되는지 확인한다.
7. 소리가 없으면 Chrome 탭 음소거, Windows 앱별 볼륨, 게임의 음악·효과음 슬라이더가 0%인지 확인한 뒤 새로고침하고 `출진 준비`를 다시 누른다.

세부 기록 양식은 `docs/testing/manual-qa-test-cases.txt`를 사용한다.

## 5분 플레이테스트 프로토콜

테스트 데이터는 기기에만 저장되며 서버로 전송되지 않는다. 이름, 이메일, 전화번호 등 개인 식별 정보는 의견란에 입력하지 않는다. 테스터 코드는 `T01`, `T02`처럼 별도로 부여한다.

1. 빌드 버전과 Android 기기 모델을 `playtest-run-log.csv`에 기록한다.
2. 새 런을 시작하고 도움 없이 이동·레벨업 선택·보스전을 진행한다.
3. 사망하거나 보스를 처치할 때까지 플레이한다. 중도 종료도 그대로 한 런으로 기록한다.
4. 결과 화면에서 재미 1~5, 난이도 1~5, 재도전 의사 예/아니오를 반드시 선택한다.
5. 의견은 선택 사항이며 200자 이내로 가장 좋았던 점이나 불편했던 점 하나만 적는다.
6. `피드백 저장`을 누른 뒤 `이 런 JSON 복사`로 단일 런 데이터가 생성되는지 확인한다.
7. 테스트 세션이 끝나면 `전체 기록 JSON 내보내기`를 눌러 `run-telemetry.json`을 공유·저장한다.
8. 파일명은 `build-테스터코드-날짜-run-telemetry.json` 형식으로 바꿔 전달한다. 예: `0.1.0+1-T01-20260714-run-telemetry.json`.

## 필수 확인 항목

- 런 ID와 앱 버전이 비어 있지 않다.
- 결과, 생존 시간, 최종 레벨, 총 처치, 보스 결과가 화면과 일치한다.
- 무기별 레벨·피해·처치가 결과 화면과 JSON에 존재한다.
- 피드백 저장 후 복사한 단일 런 JSON에 `feedback`이 존재한다.
- 전체 내보내기 파일은 최근 최대 50런을 오래된 순서부터 포함한다.
- 피드백·복사·내보내기 실패 여부와 관계없이 다시 시작과 메인 메뉴 버튼이 동작한다.

## 전달물

- 작성한 `docs/testing/playtest-run-log.csv`
- 내보낸 `run-telemetry.json`
- 재현 가능한 진행 불가·입력 불가·보이지 않는 공격이 있으면 발생 시각과 재현 순서
