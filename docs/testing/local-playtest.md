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

subst P: "C:\Users\전성진\Documents\뱀서라이크게임\.worktrees\pixel-survivor-mvp"
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

세부 기록 양식은 `docs/testing/manual-qa-test-cases.txt`를 사용한다.
