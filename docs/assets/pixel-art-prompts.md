# Joseon Dynasty Survival Pixel Art Prompts

이 문서는 실제 PNG 생성 전에 사용할 AI 도트 에셋 카탈로그와 프롬프트 기준을 정의한다. 프롬프트 본문은 생성 도구 호환성을 위해 영어 중심으로 작성하고, 설명과 검수 기준은 한국어로 관리한다.

## Copyright And Originality Rules

- Do not copy external game characters, skills, trademarks, logos, named costumes, proprietary silhouettes, or recognizable UI compositions.
- Do not request "in the style of" living artists, commercial games, anime franchises, film characters, or branded monster designs.
- Use Joseon-era visual research only as broad public-domain inspiration: gat, durumagi, hemp cloth, talisman paper, hwando sword, gakgung bow, jangseung, moonlit tiled roofs, old government office props.
- Every prompt must describe an original asset made for Joseon Dynasty Survival.
- Avoid one-to-one references to existing games, including character poses, weapon effects, enemy silhouettes, and icon layouts.

## Generation Guide

- Background: transparent background, no shadow unless the prompt asks for a tiny readable pixel contact shadow.
- Format: crisp pixel art, orthographic or three-quarter view, readable at native resolution, no antialiasing, no blur, no painterly texture.
- Sizes:
  - 16x16: pickups, gems, small status symbols.
  - 24x24: tiny swarm enemies or compact props.
  - 32x32: standard characters, monsters, weapon icons, augment icons, tiles.
  - 64x64: bosses, large effects, showcase variants.
- Canvas discipline: leave 1-2 pixels of transparent padding; keep the silhouette clear.
- Palette: muted Joseon fabric colors, moonlight blue-gray, faded red seals, brass, dark ink, pale spirit glow. Avoid neon unless it marks magic or pickups.
- Export naming: use lowercase snake_case and the target size suffix, for example `rookie_constable_32.png`.

## Characters

| Logical id | File | Size | Prompt |
| --- | --- | --- | --- |
| rookie_constable | `assets/images/characters/rookie_constable_32.png` | 32x32 | Original Joseon rookie constable, pixel art sprite, simple blue-gray uniform, small black gat-inspired hat, short hwando at waist, determined expression, compact readable silhouette, three-quarter view, transparent background, crisp 32x32 pixel art, no antialiasing |
| exorcist_dosa | `assets/images/characters/exorcist_dosa_32.png` | 32x32 | Original Joseon exorcist dosa, pixel art sprite, pale robe with ink trim, talisman papers tucked in belt, small ritual bell, calm focused pose, subtle teal spirit accent, three-quarter view, transparent background, crisp 32x32 pixel art, no antialiasing |

## Monsters

| Logical id | File | Size | Prompt |
| --- | --- | --- | --- |
| plague_rat_swarm | `assets/images/monsters/plague_rat_swarm_24.png` | 24x24 | Original plague rat swarm enemy, cluster of small dark rats with sickly green eyes, ragged Joseon street dirt, readable group silhouette, transparent background, crisp 24x24 pixel art, no antialiasing |
| bandit | `assets/images/monsters/bandit_32.png` | 32x32 | Original Joseon mountain bandit enemy, rough hemp clothes, red cloth headband, chipped knife, hunched aggressive stance, earthy colors, transparent background, crisp 32x32 pixel art, no antialiasing |
| dokkaebi | `assets/images/monsters/dokkaebi_32.png` | 32x32 | Original Korean folklore dokkaebi enemy, mischievous horned spirit, patched vest, wooden club, warm ember eyes, chunky readable silhouette, transparent background, crisp 32x32 pixel art, no antialiasing |
| vengeful_spirit | `assets/images/monsters/vengeful_spirit_32.png` | 32x32 | Original vengeful spirit enemy, floating pale hanbok fragments, long dark hair shape without copying any film character, cold blue glow, wispy lower body, transparent background, crisp 32x32 pixel art, no antialiasing |
| fallen_general | `assets/images/monsters/fallen_general_64.png` | 64x64 | Original fallen Joseon general boss, broken lamellar armor, cracked helmet, ghostly moonlit aura, one hand holding damaged command sword, tragic imposing posture, transparent background, crisp 64x64 pixel art, no antialiasing |

## Weapon Icons

| Logical id | File | Size | Prompt |
| --- | --- | --- | --- |
| hwando_slash | `assets/images/weapons/hwando_slash_32.png` | 32x32 | Original weapon icon, curved hwando sword slash arc, steel blade and pale blue motion streak, compact square composition, transparent background, crisp 32x32 pixel art |
| gakgung_shot | `assets/images/weapons/gakgung_shot_32.png` | 32x32 | Original weapon icon, Korean gakgung bow with flying arrow, taut string, small brass accent, clean readable silhouette, transparent background, crisp 32x32 pixel art |
| talisman_throw | `assets/images/weapons/talisman_throw_32.png` | 32x32 | Original weapon icon, paper talisman projectile with red seal marks and ink sparks, diagonal motion, transparent background, crisp 32x32 pixel art |
| thunder_crash_bomb | `assets/images/weapons/thunder_crash_bomb_32.png` | 32x32 | Original weapon icon, Joseon black powder bomb with lightning crack, smoke fuse, yellow flash accent, transparent background, crisp 32x32 pixel art |
| jangseung_ward | `assets/images/weapons/jangseung_ward_32.png` | 32x32 | Original weapon icon, miniature jangseung guardian totem with protective ring, carved wood face, teal ward glow, transparent background, crisp 32x32 pixel art |
| singijeon_volley | `assets/images/weapons/singijeon_volley_32.png` | 32x32 | Original weapon icon, bundle of singijeon fire arrows launching upward, tiny flame trails, dark wood launcher hint, transparent background, crisp 32x32 pixel art |

## Augment Icons

| Logical id | File | Size | Prompt |
| --- | --- | --- | --- |
| martial_training | `assets/images/ui/martial_training_32.png` | 32x32 | Original augment icon, crossed wooden practice swords with cloth wrap, disciplined training mood, transparent background, crisp 32x32 pixel art |
| quick_step | `assets/images/ui/quick_step_32.png` | 32x32 | Original augment icon, straw shoe stepping through pale wind lines, speed motif, transparent background, crisp 32x32 pixel art |
| inner_breath | `assets/images/ui/inner_breath_32.png` | 32x32 | Original augment icon, calm breath swirl over small chest charm, soft blue energy, transparent background, crisp 32x32 pixel art |
| jangseung_blessing | `assets/images/ui/jangseung_blessing_32.png` | 32x32 | Original augment icon, protective jangseung mask charm with green ward halo, transparent background, crisp 32x32 pixel art |
| hawk_eye | `assets/images/ui/hawk_eye_32.png` | 32x32 | Original augment icon, hawk eye symbol combined with arrow fletching, sharp aim motif, transparent background, crisp 32x32 pixel art |
| herbal_tonic | `assets/images/ui/herbal_tonic_32.png` | 32x32 | Original augment icon, small ceramic medicine bottle with herb leaf and red cord, healing motif, transparent background, crisp 32x32 pixel art |
| rapid_reload | `assets/images/ui/rapid_reload_32.png` | 32x32 | Original augment icon, fast hands reloading arrow bundle or powder pouch, circular motion marks, transparent background, crisp 32x32 pixel art |
| goblin_fire | `assets/images/ui/goblin_fire_32.png` | 32x32 | Original augment icon, folklore spirit flame in a small brass bowl, blue-orange fire, transparent background, crisp 32x32 pixel art |
| powder_mastery | `assets/images/ui/powder_mastery_32.png` | 32x32 | Original augment icon, black powder pouch with tiny spark and sealed label, explosive mastery motif, transparent background, crisp 32x32 pixel art |
| last_stand | `assets/images/ui/last_stand_32.png` | 32x32 | Original augment icon, cracked shield and red knot charm, resilient final defense motif, transparent background, crisp 32x32 pixel art |
| ritual_shortcut | `assets/images/ui/ritual_shortcut_32.png` | 32x32 | Original augment icon, folded talisman path with small moon seal, ritual efficiency motif, transparent background, crisp 32x32 pixel art |
| heavy_strike | `assets/images/ui/heavy_strike_32.png` | 32x32 | Original augment icon, heavy hammer impact mark beside a short blade, forceful strike motif, transparent background, crisp 32x32 pixel art |

## Effects And Pickups

| Logical id | File | Size | Prompt |
| --- | --- | --- | --- |
| experience_gem | `assets/images/effects/experience_gem_16.png` | 16x16 | Original pickup icon, small moonlit jade experience orb, bright center pixel, readable at tiny size, transparent background, crisp 16x16 pixel art |
| healing_item | `assets/images/effects/healing_item_16.png` | 16x16 | Original pickup icon, tiny red-and-white medicine packet with herb leaf, healing pickup, transparent background, crisp 16x16 pixel art |
| hwando_slash_effect | `assets/images/effects/hwando_slash_effect_64.png` | 64x64 | Original attack effect, sweeping hwando slash crescent with pale blue edge and a few white impact pixels, transparent background, crisp 64x64 pixel art |

## Stages

| Logical id | File | Size | Prompt |
| --- | --- | --- | --- |
| moonlit_abandoned_government_office_tile | `assets/images/stages/moonlit_abandoned_government_office_tile_32.png` | 32x32 | Original seamless floor tile for moonlit abandoned Joseon government office, cracked stone courtyard, moss in seams, cold blue-gray moonlight, subtle dirt, tileable edges, crisp 32x32 pixel art, no antialiasing |

## Review Checklist

- 파일 경로가 `pubspec.yaml`에 등록된 `assets/images/.../` 하위인지 확인한다.
- 카탈로그 logical id와 PNG 파일명이 snake_case로 일치하는지 확인한다.
- 프롬프트에 외부 게임명, 상표명, 특정 캐릭터명, 고유 실루엣 복제 지시가 없는지 확인한다.
- 생성 결과는 투명 배경, 원본 해상도, 픽셀 선명도, 작은 화면 가독성을 기준으로 선별한다.
