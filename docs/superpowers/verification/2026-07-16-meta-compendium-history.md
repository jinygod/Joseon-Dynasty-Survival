# META-001~003 검증 기록

## TDD

- schema v3 새 필드와 캐릭터별 승리 정산 테스트를 먼저 작성하고 missing parameter/getter 컴파일 실패를 확인했다.
- 도감 서비스 테스트를 먼저 작성하고 missing model/service 실패를 확인했다.
- 텔레메트리 집계 테스트를 먼저 작성하고 missing service 실패를 확인했다.
- 도감/로비 widget 테스트를 먼저 작성하고 missing screen/key/controller API 실패를 확인했다.
- 기록 widget 테스트를 먼저 작성하고 missing `historyService` API 실패를 확인했다.

각 RED 뒤 최소 구현을 추가하고 해당 focused 테스트의 GREEN을 확인했다.

## 최종 게이트

Windows의 한글 사용자 경로에서 Flutter `impellerc`가 SIGSEGV를 일으키므로 프로젝트를 `M:`에, Flutter SDK를 `F:`에 각각 `subst`한 완전 ASCII 경로로 검증했다. 테스트용 Material shader는 동일 Flutter SDK로 이미 생성된 캐시를 사용했고, web release build는 SDK와 프로젝트를 모두 ASCII로 매핑해 새로 완료했다.

- Focused: 관련 model/service/widget/정산/저장/반응형 테스트 63개 통과
- Analyze: `F:\bin\dart.bat analyze --format machine` 종료 코드 0, 진단 0건
- Full test: `flutter test --concurrency=1` 413개 통과
- Web: `F:\bin\flutter.bat build web --release` 종료 코드 0, `Built M:\build\web`
- Diff: `git diff --check` 통과

## 범위 감사

변경은 도감/기록 화면, 로비 진입, 메타 모델·서비스·저장, 런 정산 연결, 대응 테스트와 문서에 한정한다. `docs/master-development-todo.md`, 보스, 설정, QA 런타임 파일은 수정하지 않았다.
