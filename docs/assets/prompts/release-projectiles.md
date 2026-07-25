# 릴리스 플레이어 투사체 생성 프롬프트

- 생성 방식: OpenAI 내장 이미지 생성
- 후처리: 고정 크기 셀 크롭, chroma key 제거, RGBA 검증
- 런타임 방향: 모든 투사체는 오른쪽을 향함
- 공통 광원: 좌상단의 차가운 달빛, 제한된 금빛 자체 발광

## 신기전

```text
Use case: stylized-concept
Asset type: 2D mobile action game projectile animation source sheet
Primary request: four consistent animation poses of one right-facing Joseon singijeon rocket arrow
Scene/backdrop: perfectly flat solid #00FF00 chroma-key background, one uniform color with no shadow, gradient, texture, floor, reflection, or lighting variation
Subject: wooden rocket arrow with a compact red gunpowder canister, dark iron bindings, pointed ivory arrowhead, and a short gold ignition flame; the four poses change only the flame and tiny smoke rhythm
Style/medium: polished cute Joseon folk-fantasy mobile game sprite, bold dark-ink outline, clean readable silhouette, restrained detail
Composition/framing: exact 2 by 2 contact-sheet layout, one centered right-facing projectile per quadrant, identical scale and anchor, generous clear padding, no divider
Lighting/mood: cool upper-left moonlight with a small warm ignition glow
Color palette: dark navy ink, warm wood brown, vermilion red, ivory, restrained gold
Constraints: no frame border, no card, no square aura, no panel background, no text, no watermark, no cast shadow; do not use #00FF00 in the subject
Avoid: primitive rectangle, toy block, opaque box edge, photorealism, muddy smoke, cropped silhouette
```

## 조총·화포 철환

```text
Use case: stylized-concept
Asset type: 2D mobile action game projectile animation source sheet
Primary request: four consistent animation poses of one fast right-facing Joseon matchlock iron shot
Scene/backdrop: perfectly flat solid #00FF00 chroma-key background, one uniform color with no shadow, gradient, texture, floor, reflection, or lighting variation
Subject: an irregular chipped dark iron shot with a vermilion fire core, thin ivory-hot leading rim, and a short tapered grey smoke tail; the four poses change only flame and smoke rhythm
Style/medium: polished cute Joseon folk-fantasy mobile game sprite, bold dark-ink outline, high readability at 18 pixels, restrained detail
Composition/framing: exact 2 by 2 contact-sheet layout, one centered right-facing projectile per quadrant, identical scale and anchor, generous clear padding, no divider
Lighting/mood: cool upper-left moonlight, restrained warm combustion glow
Color palette: charcoal iron, dark navy outline, vermilion, ivory, restrained gold, neutral grey smoke
Constraints: no frame border, no card, no square aura, no panel background, no text, no watermark, no cast shadow; do not use #00FF00 in the subject
Avoid: perfect circle icon, flat oval, brick, primitive shape, photorealism, excessive bloom, cropped smoke
```

## 수호매

```text
Use case: stylized-concept
Asset type: 2D mobile action game summoned projectile animation source sheet
Primary request: four consistent wingbeat poses of one compact right-facing guardian hawk
Scene/backdrop: perfectly flat solid #FF00FF chroma-key background, one uniform color with no shadow, gradient, texture, floor, reflection, or lighting variation
Subject: small Joseon folk-fantasy guardian hawk with a hooked ivory beak, navy feathers, gold-brown wing tips, and a tiny jade talisman band; clear spread-wing silhouette, four readable wingbeat poses
Style/medium: polished cute mobile game sprite, bold dark-ink outline, simplified feather groups, clear silhouette at 24 pixels
Composition/framing: exact 2 by 2 contact-sheet layout, one centered right-facing hawk per quadrant, identical body scale and anchor, generous clear padding, no divider
Lighting/mood: cool upper-left moonlight with restrained ivory edge light
Color palette: dark navy, muted blue, gold-brown, ivory, tiny jade accent
Constraints: no frame border, no card, no square aura, no panel background, no text, no watermark, no cast shadow; do not use #FF00FF in the subject
Avoid: realistic individual feathers, fuzzy edges, bullet shape, glowing orb, cropped wings
```

## 투사체 접촉 불꽃

```text
Use case: stylized-concept
Asset type: 2D mobile action game projectile impact animation source sheet
Primary request: six sequential poses of one tiny projectile contact spark, from first pinpoint contact through bright snap to fast fade
Scene/backdrop: perfectly flat solid #00FF00 chroma-key background, one uniform color with no shadow, gradient, texture, floor, reflection, or lighting variation
Subject: compact asymmetric ivory-gold spark burst with a restrained vermilion contact core and two or three dark-ink debris flecks; no projectile body
Style/medium: polished Joseon folk-fantasy mobile game VFX sprite, sharp readable strokes, restrained bloom
Composition/framing: exact 3 by 2 contact-sheet layout in chronological order left-to-right then top-to-bottom, one centered effect per cell, identical anchor, generous clear padding, no divider
Lighting/mood: crisp instantaneous contact
Color palette: ivory, restrained gold, vermilion, dark navy ink
Constraints: no frame border, no card, no square aura, no panel background, no text, no watermark; do not use #00FF00 in the subject
Avoid: perfect circle, generic star icon, large explosion, smoke cloud, cropped sparks
```
