# Final review fix report

## 상태

- 기준 커밋: `6c6151b`
- 최종 리뷰 findings 5건 처리
- 생산 코드 변경은 XP 잔여치 정규화, unknown augment fail-closed, 실제 jade mount를 막던 불필요한 기반 클래스 교정으로 제한

## RED → GREEN 증거

### RED

명령:

```powershell
$env:TEMP='C:\codex-temp'; $env:TMP='C:\codex-temp'; & 'S:\bin\flutter.bat' test test/game/run_progression_system_test.dart test/game/augment_effect_resolver_test.dart test/game/pixel_survivor_game_loop_test.dart
```

결과: exit 1.

- `floating-point threshold leaves zero public experience`: expected `0`, actual `-1`
- `unknown augment choice fails closed without recording state`: expected empty choices, actual one `RunChoiceRecord`
- resolver 경계/`innerBreath`/health 0, Last Stand heal 해제 계약 테스트는 기존 생산 코드에서 통과
- 최초 jade fixture는 `SpriteComponent.onMount`의 `sprite != null` assertion을 드러냄. 컴포넌트가 자체 atlas/fallback render만 사용하므로 `PositionComponent`로 최소 교정

### GREEN focused

동일 focused 명령 결과: exit 0, `39` tests passed, 5.8초.

- XP threshold를 반복당 한 번 계산해 차감하고 `(-1e-9, 0)` 잔여치를 0으로 정규화
- augment definition nullable 조회를 선택 기록/해금/레벨 변경 전에 수행해 unknown ID 즉시 반환
- 실제 `ExperienceGemComponent`와 `SpiritJadeComponent`를 6.9/7.1 거리에서 게임 `update()`를 통해 수집시켜 반경 7 안/밖을 검증

## 픽업 테스트 hang 조사

- 재현: jade 포함 픽업 단독 widget test가 60초 무출력 timeout
- 비교: XP 단독 7.5초 PASS, 실제 gem 단독 7.7초 PASS, 실제 jade 단독만 timeout
- 단일 가설: widget fake-async 안에서 `await Future.delayed(Duration.zero)`가 microtask 진행을 기다리며 종료되지 않음
- 최소 변경: verify 콜백의 대기를 `WidgetTester.pump()`로 교체
- 검증: 실제 jade 단독 7.8초 PASS; 이후 focused 39 tests PASS 및 full 318 tests PASS

## 최종 검증

```powershell
$env:TEMP='C:\codex-temp'; $env:TMP='C:\codex-temp'; & 'S:\bin\flutter.bat' analyze
```

- exit 0, `No issues found!`, 12.1초

```powershell
$env:TEMP='C:\codex-temp'; $env:TMP='C:\codex-temp'; & 'S:\bin\flutter.bat' test
```

- exit 0, `318` tests passed, 19.9초

Flutter 명령은 성공 후 환경의 `The network path was not found.` 문구를 출력했지만 모든 명령 exit code는 0이었고 analyzer/test 결과는 정상 완료됐다.

## 변경 파일

- `lib/game/systems/run_progression_system.dart`
- `lib/game/pixel_survivor_game.dart`
- `lib/game/components/spirit_jade_component.dart`
- `test/game/run_progression_system_test.dart`
- `test/game/augment_effect_resolver_test.dart`
- `test/game/pixel_survivor_game_loop_test.dart`
- `.superpowers/sdd/final-review-fix-report.md`

## 자체 검토

- `applyLevelUpChoice` public signature 유지
- unknown augment에서 choice 기록, unlock, level 및 첫 augment 오염 없음
- resolver 생산 로직은 변경하지 않고 계약 테스트만 추가
- Last Stand는 정확히 35%에서 발동하고 heal 후 캐릭터 passive(`0.88`)로 복귀
- 픽업 반경 산식/범위는 변경하지 않았고 실제 private 수집 경로를 사용
- `SpiritJadeComponent`는 `SpriteComponent.sprite`를 사용하지 않으므로 기반 클래스 변경에 렌더링 동작 차이 없음
- `dart format`: 6 files, 0 changed; `git diff --check`: clean
