# 오디오 서비스 기반 설계

## 목표

실제 음원 파일과 오디오 재생 패키지를 추가하지 않고 `AUD-001`의 기반을 완성한다. 게임 로직은 파일명이나 재생 라이브러리를 알지 않고 의미가 정해진 오디오 큐만 발생시킨다. 현재는 모든 명령을 안전하게 받아들이는 무음 백엔드를 사용하며, 향후 실제 음원 백엔드로 교체해도 전투 로직을 수정하지 않는다.

## 범위

이번 작업에 포함하는 항목은 다음과 같다.

- 음악, 효과음, UI의 세 채널 정의
- 게임 의미를 나타내는 타입이 정해진 오디오 큐와 채널 매핑
- 게임이 호출하는 단일 `GameAudioService`
- 외부 재생 구현을 숨기는 `AudioBackend` 계약
- 아무 소리도 내지 않는 `SilentAudioBackend`
- 음악 중지, 전체 일시정지, 재개, 종료 수명주기
- 백엔드 오류가 게임 진행에 전파되지 않는 오류 격리
- 채널 매핑, 명령 전달, 무음 동작, 오류 격리 단위 테스트

실제 음원 제작·구매·생성 방식은 `AUD-002`, 음악 적용은 `AUD-003`, 전투와 UI 효과음 적용은 `AUD-004`·`AUD-005`, 동시 재생 수·피치·우선순위는 `AUD-006`, 음량과 진동 설정 저장은 `AUD-007`에서 다룬다. 햅틱은 `AUD-008` 범위다.

## 구조

### AudioCue와 AudioChannel

`AudioChannel`은 `music`, `sfx`, `ui` 세 값만 가진다.

`AudioCue`는 파일명이 아니라 게임 의미를 표현한다.

- 음악: `menuMusic`, `battleMusic`, `bossMusic`, `victoryMusic`, `defeatMusic`
- 무기: `hwandoAttack`, `bowAttack`, `talismanAttack`, `bombAttack`
- 전투 피드백: `playerHit`, `criticalHit`, `enemyDeath`, `experiencePickup`, `levelUp`, `bossWarning`
- UI: `uiConfirm`, `uiBack`

`AudioCueCatalog.channelFor(AudioCue)`가 모든 큐를 정확히 한 채널로 매핑한다. 실제 경로, 볼륨, 피치, 동시 재생 수는 아직 보관하지 않는다.

### AudioBackend

백엔드는 다음 비동기 명령을 제공한다.

- `play(AudioCue cue, AudioChannel channel)`
- `stopMusic()`
- `pauseAll()`
- `resumeAll()`
- `dispose()`

`SilentAudioBackend`는 모든 명령을 즉시 정상 완료한다. 게임에 오디오 패키지나 플랫폼 플러그인 의존성을 추가하지 않는다.

### GameAudioService

서비스는 게임과 백엔드 사이의 유일한 진입점이다.

- `play(AudioCue cue)`는 카탈로그에서 채널을 구한 뒤 백엔드에 전달한다.
- `stopMusic`, `pauseAll`, `resumeAll`, `dispose`는 같은 이름의 백엔드 명령을 전달한다.
- 모든 백엔드 예외를 잡아서 게임에 전파하지 않는다.
- 개발 진단 콜백이 주어지면 실패한 작업명, 큐, 오류, 스택을 한 번 전달한다.
- `dispose` 이후의 명령은 무시해 종료된 화면이나 게임 인스턴스가 소리를 다시 시작하지 못하게 한다.

서비스는 이번 단계에서 큐를 저장하거나 재생 순서를 바꾸지 않는다. 호출 순서를 그대로 백엔드에 전달한다.

## 데이터 흐름

1. 게임 이벤트가 `GameAudioService.play(AudioCue.playerHit)`처럼 의미 큐를 전달한다.
2. 서비스가 `AudioCueCatalog`에서 `sfx` 채널을 결정한다.
3. 서비스가 `AudioBackend.play`를 호출한다.
4. 현재 무음 백엔드는 즉시 완료한다.
5. 미래의 실제 백엔드는 같은 큐를 음원 경로로 변환해 재생한다.

실제 게임 이벤트 연결은 해당 음원이 준비되는 `AUD-003`~`AUD-005`에서 수행한다. 이번 단계에서는 서비스 계약을 전투 코드에 주입하지 않는다.

## 수명주기

- 앱 또는 게임 일시정지: `pauseAll`
- 명시적 계속 또는 포그라운드 복귀: 정책 확인 후 `resumeAll`
- 런 음악 전환: `stopMusic` 후 새 음악 큐 재생
- 게임 화면 종료: `dispose`

현재 `GameScreen`의 일시정지 로직에는 아직 연결하지 않는다. `pauseAll`과 `resumeAll` 계약만 테스트해 이후 연결 시 UI 수명주기와 분리한다.

## 오류 처리

오디오 오류는 플레이, 저장, 결과 화면, 앱 종료를 막아서는 안 된다. 백엔드의 모든 동기·비동기 예외는 서비스 경계에서 잡는다. 진단 콜백 자체가 예외를 던져도 다시 게임으로 전파하지 않는다. 무음 백엔드는 플랫폼 바인딩 없이 순수 Dart 테스트에서 동작해야 한다.

## 테스트와 완료 기준

- 모든 `AudioCue`가 정확히 한 채널에 매핑된다.
- 음악 큐는 `music`, 무기·전투 큐는 `sfx`, UI 큐는 `ui`로 분류된다.
- 서비스가 큐와 채널을 백엔드에 그대로 한 번 전달한다.
- 중지·일시정지·재개·종료 명령이 백엔드에 전달된다.
- 백엔드가 각 명령에서 예외를 던져도 서비스 호출은 정상 완료되고 진단이 한 번 기록된다.
- `dispose` 이후에는 재생·수명주기 명령이 백엔드에 전달되지 않는다.
- `SilentAudioBackend`는 Flutter 바인딩이나 실제 음원 없이 모든 명령을 정상 완료한다.
- 기존 전체 테스트, 웹 빌드, Android 디버그 APK 빌드가 통과한다.
- `AUD-001`만 완료 처리하고 `AUD-002`~`AUD-010`은 미완료로 유지한다.
