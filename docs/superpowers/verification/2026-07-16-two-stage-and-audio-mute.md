# 2개 스테이지와 실시간 오디오 음소거 검증

## 전달 결과

- 음악 음량 0%는 재생 중인 음악을 즉시 중단한다.
- 효과음 음량 0%는 재생 중인 효과음과 UI 음성을 즉시 중단한다.
- 음소거 직전에 직렬 대기열에 들어간 요청은 백엔드 실행 직전 최신 설정을 다시 검사해 재생하지 않는다.
- 설정 컨트롤러의 로드·슬라이더 변경 알림은 앱 수명주기 바인딩을 통해 오디오 서비스에 전달되며, 바인딩 종료 후에는 전달되지 않는다.
- `달빛 폐관아`는 기존 표준 압력을 유지하고 `역병 장터`는 역병 적 중심의 더 높은 생성 속도·동시 적 상한·정예 확률을 사용한다.
- 스테이지 선택 화면에서 두 카드를 선택할 수 있고, 선택 ID가 저장 상태에서 `GameScreen`과 `PixelSurvivorGame`의 웨이브 디렉터까지 전달된다.

## TDD 근거

- 오디오 테스트는 `applySettings` 미정의 컴파일 실패와 대기 요청이 두 번째로 재생되는 실패를 확인한 뒤 구현했다.
- 앱 바인딩 테스트는 바인딩 파일과 타입이 없는 컴파일 실패를 확인한 뒤 구현했다.
- 스테이지 콘텐츠 테스트는 `plagueMarket`, 시각 메타데이터, 스테이지 웨이브 조회가 없는 컴파일 실패를 확인한 뒤 구현했다.
- 게임 루프 테스트는 `PixelSurvivorGame.stageId` 인수가 없는 컴파일 실패를 확인한 뒤 구현했다.
- 선택 화면 테스트는 `역병 장터` 카드가 없는 위젯 실패를 확인한 뒤 구현했다.

## 최종 릴리스 게이트

2026-07-16에 `tool/release_check.ps1 -IncludeAndroid`를 현재 `master`에서 새로 실행했다.

- `dart format --output=none --set-exit-if-changed lib test`: Git 정규화 기준 변경 없음
- `dart analyze`: `No issues found!`
- `flutter test -r compact`: 345개 통과, 실패 0개
- `flutter build web`: `build/web` 생성 성공
- `flutter build apk --debug`: `build/app/outputs/flutter-apk/app-debug.apk` 생성 성공
- 최종 스크립트 결과: `Release checks passed.`

## 주요 커밋

- `2892b6e` `fix: stop audio immediately when muted`
- `c632bca` `fix: synchronize mute settings with active audio`
- `671a781` `feat: define moonlit and plague stage rosters`
- `af7fb2e` `feat: route stage waves into game runs`
- `d08858e` `feat: add plague market stage selection`
