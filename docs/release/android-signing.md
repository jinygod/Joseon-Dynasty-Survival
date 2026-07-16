# Android 릴리스 서명과 산출물 보관

릴리스 AAB는 업로드 키로 서명하며, 키 파일과 암호는 저장소에 커밋하지 않는다. 디버그 빌드는 이 설정 없이 계속 동작하지만, 릴리스 태스크는 설정이 빠졌거나 키 파일을 찾지 못하면 즉시 실패한다.

## 1. 업로드 키 준비

키는 저장소 밖의 접근 제한 디렉터리에 생성하고 별도로 백업한다.

```powershell
& 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe' `
  -genkeypair -v -keystore 'C:\secure\pixel-survivor-upload.jks' `
  -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

키스토어, 별칭, 두 암호를 암호 관리자에 기록한다. 키 파일은 Git, 메신저, 일반 공유 폴더에 두지 않는다.

## 2. 서명 설정

둘 중 한 방식만 사용한다. `android/key.properties`와 환경 변수는 혼합할 수 없으며 각 방식에 필요한 값을 모두 설정해야 한다.

로컬 전용 `android/key.properties`:

```properties
storeFile=C:/secure/pixel-survivor-upload.jks
storePassword=<keystore-password>
keyAlias=upload
keyPassword=<key-password>
uploadCertSha256=<64-hex-upload-certificate-sha256>
```

또는 CI/일회성 PowerShell 환경 변수:

```powershell
$env:ANDROID_KEYSTORE_PATH = 'C:\secure\pixel-survivor-upload.jks'
$env:ANDROID_KEYSTORE_PASSWORD = '<keystore-password>'
$env:ANDROID_KEY_ALIAS = 'upload'
$env:ANDROID_KEY_PASSWORD = '<key-password>'
$env:ANDROID_UPLOAD_CERT_SHA256 = '<64-hex-upload-certificate-sha256>'
```

`keytool -list -v -keystore <path> -alias <alias>`에 표시되는 SHA-256 인증서 지문에서 콜론을 제거해 사용한다. 지문은 비밀이 아니지만, 빌드가 의도한 업로드 인증서로 서명됐는지 확인하는 신뢰 기준이다. `android/key.properties`와 `ANDROID_*` 환경 변수는 혼합하지 않고 한 소스에 다섯 값을 모두 설정한다.

`android/key.properties`, `*.jks`, `*.keystore`는 `.gitignore`에 포함되어 있다. 암호나 키를 소스, Gradle 파일, 빌드 로그에 넣지 않는다.

## 3. 서명 AAB 빌드와 검증

백업 위치는 반드시 저장소 밖이어야 한다. 스크립트는 `flutter build appbundle --release --obfuscate --split-debug-info`를 실행하고, AAB 서명과 심볼을 검증한 뒤 SHA-256 목록과 백업 사본을 만든다.

```powershell
.\tool\build_android_release.ps1 `
  -BackupRoot 'D:\pixel-survivor-release-backup' `
  -TrustAnchorRoot 'E:\pixel-survivor-release-trust'
```

산출물은 `dist/android/<release-id>/`에 생성된다.

- `pixel-survivor-<version>.aab`: Play Console 업로드 파일
- `symbols/`: 난독화된 스택 추적 복구에 필요한 split-debug-info
- `SHA256SUMS.txt`: AAB, 심볼, 메타데이터의 SHA-256
- `BUILD-METADATA.txt`: 재현할 빌드 명령과 버전
- `UPLOAD-CERT-SHA256.txt`: 검증에 사용한 업로드 인증서 지문

스크립트는 `jarsigner -verify -strict`가 모든 AAB 항목의 서명을 확인한 뒤 저장소 밖 `-BackupRoot`에 동일한 디렉터리를 복사하고 모든 파일 해시를 다시 비교한다. 자체 서명 업로드 인증서의 신뢰 체인은 Play Console에서 확인하므로 로컬 검증에는 경고가 표시될 수 있다. 기존 release-id나 백업을 덮어쓰지 않는다. 개별 AAB를 다시 검사하려면 다음을 실행한다.

`SHA256SUMS.txt` 자체의 SHA-256은 `<release-id>.MANIFEST-SHA256.txt`로 `-TrustAnchorRoot`에 별도 저장된다. 이 trust anchor가 backup 밖에 있어야 artifacts와 manifest를 함께 바꿔 다시 해시하는 변조도 탐지할 수 있다.

```powershell
.\tool\verify_android_release.ps1 `
  -AabPath '.\dist\android\<release-id>\pixel-survivor-<version>.aab' `
  -SymbolsPath '.\dist\android\<release-id>\symbols' `
  -ExpectedCertSha256 '<64-hex-upload-certificate-sha256>'
```

외부 백업을 복원한 뒤에는 manifest의 모든 파일을 다시 해시하고 AAB 인증서까지 재검증한다.

```powershell
.\tool\restore_verify_android_release.ps1 `
  -ArtifactDirectory 'D:\pixel-survivor-release-backup\<release-id>' `
  -TrustAnchorPath 'E:\pixel-survivor-release-trust\<release-id>.MANIFEST-SHA256.txt'
```

자동화 시스템이 digest를 별도 보안 저장소에서 전달할 때는 `-TrustAnchorPath` 대신 `-ExpectedManifestSha256 <64-hex>`를 사용할 수 있다. `OutputRoot`, `BackupRoot`, `TrustAnchorRoot`는 동일하거나 서로의 상위/하위 디렉터리일 수 없다. 빌드·검증·백업 중 실패하면 해당 release-id의 부분 디렉터리와 trust anchor만 제거하므로 같은 ID로 안전하게 재시도할 수 있다.

한국어가 포함된 작업 경로에서 Flutter 도구가 실패하면 `tool/release_check.ps1`로 기본 검사를 먼저 수행하고, 임시 ASCII 드라이브에 저장소를 매핑한 셸에서 같은 빌드 스크립트를 실행한다.

```powershell
subst R: (Resolve-Path .).Path
subst S: $env:LOCALAPPDATA\Android\Sdk
R:
$env:PUB_CACHE = 'C:\flutter-pub-cache'
$env:ANDROID_HOME = 'S:\'
$env:ANDROID_SDK_ROOT = 'S:\'
.\tool\build_android_release.ps1 `
  -BackupRoot 'D:\pixel-survivor-release-backup' `
  -TrustAnchorRoot 'E:\pixel-survivor-release-trust'
Remove-Item Env:PUB_CACHE
Remove-Item Env:ANDROID_HOME
Remove-Item Env:ANDROID_SDK_ROOT
subst S: /d
subst R: /d
```

## 4. 업로드와 보관

1. Play Console 내부 테스트 트랙에 AAB를 업로드한다.
2. Play Console이 표시하는 인증서와 앱 서명 상태를 확인한다.
3. `SHA256SUMS.txt`와 외부 백업의 해시가 일치하는지 확인한다.
4. AAB와 `symbols/`를 같은 release-id로 장기 보관한다. 심볼이 없으면 난독화된 장애 스택을 복구하기 어렵다.

## 5. 키 분실 또는 복구

- 키스토어 파일과 암호 관리자 기록을 함께 복구하고 `keytool -list -v`로 별칭과 인증서 지문을 확인한다.
- 백업 복원 후 `tool/verify_android_release.ps1`로 보관 AAB 서명을 다시 검증한다.
- 업로드 키를 분실했지만 Play App Signing을 사용 중이면 Play Console의 업로드 키 재설정 절차를 따른다. 앱 서명 키와 업로드 키를 혼동하지 않는다.
- 복구 테스트는 실제 장애 전에 별도 장비 또는 격리된 디렉터리에서 정기적으로 수행한다.
