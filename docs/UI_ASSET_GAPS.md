# UI 에셋 공백 명세

작성일: 2026-07-24

기존 에셋을 우선 재사용한 뒤에도 서로 다른 콘텐츠를 구분할 수 없는 항목만 기록한다. 버튼 글자는 이미지로 굽지 않으며 프레임·배경은 텍스트 없는 9-slice 사용을 원칙으로 한다.

| 필요한 파일명 | 용도 | 권장 크기 | 투명 배경 | 필요한 상태 | 현재 임시 표현 | 연결할 코드 위치 | 생성 프롬프트 요약 | 우선순위 |
|---|---|---:|---|---|---|---|---|---|
| `ui/joseon_panel_9slice.png` | 공통 패널·선택 카드 프레임 | 192×192 | 예 | 기본 | 단색 Container/Card 테두리 | 신규 `JoseonPanel`, `JoseonSelectionCard` | 짙은 남색 옻칠 목재, 얇은 아이보리·금속 모서리, 중앙 무문양, 텍스트 없음 | P1 |
| `ui/joseon_primary_button_9slice.png` | 출진·선택 완료 버튼 | 256×96 | 예 | 기본·눌림 | 그라데이션 FilledButton | 신규 `JoseonPrimaryButton` | 금빛 옻칠 버튼 프레임, 중앙 깨끗함, 텍스트 없음 | P2 |
| `characters/rookie_constable_portrait.png` | 신참 포졸 선택·도감·기록 | 512×640 | 예 | 기본 | `exorcist_dosa_128.png` 공유 | `AssetCatalog.player`, 캐릭터 선택·도감·기록 | 귀엽고 캐주얼한 조선 포졸 전신, 정면 3/4, 또렷한 실루엣 | P0 |
| `characters/exorcist_dosa_portrait.png` | 퇴마 의사 선택·도감·기록 | 512×640 | 예 | 기본 | 전투용 128px 이미지 확대 | `AssetCatalog.player`, 캐릭터 선택·도감·기록 | 기존 퇴마 의사 디자인 유지, 모바일 카드용 고해상도 전신 | P0 |
| `characters/mountain_hunter_portrait.png` | 설산 사냥꾼 선택·도감·기록 | 512×640 | 예 | 기본 | 64px 정적 이미지 또는 Material 아이콘 | `AssetCatalog.player`, 캐릭터 선택·도감·기록 | 조선 산포수, 활 또는 조총, 겨울 산악 장비, 캐주얼 비율 | P0 |
| `stages/moonlit_office_card.png` | 달빛 폐관아 선택 카드 | 768×432 | 아니오 | 기본 | 단색 남색 + 달 아이콘 | `StageDefinition` 시각 메타데이터, 스테이지 선택 | 기존 달빛 관아·석바닥·기와·등불, 텍스트 없음 | P0 |
| `stages/plague_market_card.png` | 역병 장터 선택 카드 | 768×432 | 아니오 | 기본 | 단색 녹색 + 질병 아이콘 | `StageDefinition` 시각 메타데이터, 스테이지 선택 | 버려진 조선 장터, 녹청 안개, 약재와 천막, 텍스트 없음 | P0 |
| `weapons/*_icon_128.png` | 무기 도감·레벨업·HUD·결과 | 128×128 | 예 | 기본 | 여러 무기가 같은 효과 atlas 공유 | `AssetCatalog.weapons`, 공통 무기 아이콘 위젯 | 무기별 단일 물체, 조선 민속 판타지, 강한 실루엣, UI 아이콘 | P1 |
| `augments/*_icon_128.png` | 증강 도감·레벨업 | 128×128 | 예 | 기본 | 같은 전투 효과 atlas 공유 | `AssetCatalog.augments`, 도감·레벨업 | 능력별 상징물, 인물·무기와 구분되는 부적·문양 계열 | P2 |

## 적용 규칙

- 에셋이 없으면 개발 빌드에서 카드 내부에 `ASSET MISSING`과 필요한 키를 표시한다.
- 잠금 항목에는 원본 에셋 대신 불투명 실루엣과 해금 조건만 표시한다.
- P0 초상과 스테이지 삽화가 준비되기 전에도 레이아웃·상태·접근성 구현은 가능하지만, 임시 Material 아이콘을 최종 상태로 간주하지 않는다.
- 에셋 생성은 기존 캐릭터·스테이지 외형을 변경하지 않고 현재 아트 방향을 해상도와 용도에 맞게 확장하는 작업으로 제한한다.
