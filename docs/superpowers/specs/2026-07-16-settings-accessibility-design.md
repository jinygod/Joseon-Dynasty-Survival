# 설정·접근성 설계

## 목표

음악 음량, 효과음 음량, 진동, 화면 흔들림, 피해 숫자, UI 크기를 하나의 영속 `GameSettings` 모델로 관리한다. 기존 오디오 설정 API와 SharedPreferences 키에서 무손실로 이전하며, 메타 진행 초기화는 두 번 확인한 뒤 `SaveState.defaults()`만 저장하고 설정은 보존한다.

## 구조

- `GameSettings`는 두 음량(0~1), 세 불리언, `UiScale`(`small`, `normal`, `large`)을 소유한다.
- `GameSettingsRepository`는 버전이 포함된 JSON 한 키를 우선 읽고, 없으면 기존 `audio.musicVolume`, `audio.sfxVolume`, `audio.vibrationEnabled` 키를 읽어 새 모델의 나머지 기본값과 합친다. 저장 시 새 JSON과 기존 오디오 키를 함께 갱신한다.
- `GameSettingsController`는 낙관적 UI 갱신과 직렬 저장을 담당한다. 기존 `AudioSettings`, `AudioSettingsStore`, `AudioSettingsController` 이름은 typedef/호환 래퍼로 유지해 오디오 서비스와 기존 테스트를 깨지 않는다.
- `SettingsScreen`은 여섯 설정을 즉시 반영하고, 진행 초기화 버튼에서 1차 경고와 2차 최종 확인을 순서대로 통과한 경우에만 주입된 `SaveStore`에 기본 진행을 저장한다.
- `GameScreen`은 컨트롤러 변경을 게임 런타임에 전달한다. 피해 숫자와 화면 흔들림은 `PixelSurvivorGame`의 런타임 플래그로 차단하고, HUD는 설정의 UI 배율만 적용한다.

## 오류 처리

잘못된 JSON·타입·범위는 안전한 기본값 또는 유효한 기존 키로 복구한다. 설정 저장 실패는 기존 진단 콜백으로 보고하되 현재 UI를 중단하지 않는다. 진행 초기화 저장 실패는 화면에 실패 안내를 표시한다.

## 검증

모델 정규화, 레거시 마이그레이션, 재실행 복원, 컨트롤러 직렬 저장, 설정 화면 토글·슬라이더·UI 크기, 초기화 취소·확정·설정 보존, 게임 런타임의 화면 흔들림·피해 숫자 차단, HUD 배율을 테스트한다. ASCII `subst` 경로에서 담당 테스트, 전체 `flutter test`, `dart analyze`, `flutter build web`을 실행한다.
