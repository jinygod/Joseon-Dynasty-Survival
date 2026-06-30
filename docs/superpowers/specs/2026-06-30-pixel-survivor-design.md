# Joseon Dynasty Survival Design

Date: 2026-06-30
Status: Approved for planning
Target: Flutter mobile game using Flame

## Goal

Build a small but expandable Joseon-era folk-fantasy auto-battler survival roguelite in Flutter. The first playable version should be simple enough to finish quickly, but it must already include a reason to keep playing: unlockable weapons, augments, characters, and progression goals.

Working title: Joseon Dynasty Survival.
Korean concept name: 조선 생존록.
Genre: 조선시대 민속 판타지 자동전투 생존 로그라이트.

The first release target is a 5 to 8 minute survival run with one starting character, one stage, several enemy types, automatic weapons, level-up choices, and persistent unlock progress.

## Product Pillars

- Fast runs: one session should be playable in a short break.
- Automatic combat: the player focuses on movement, positioning, and build choices.
- Unlock momentum: each run should make progress toward at least one visible goal.
- Pixel identity: characters, monsters, weapons, stage tiles, and UI icons use AI-generated pixel art.
- Landscape-first mobile controls: the game is designed around a wide mobile screen, with a virtual joystick in the lower-left area and touch-friendly combat, status, and level-up UI arranged for landscape play.

## MVP Scope

The MVP includes:

- One starting playable character.
- One locked character defined in data and unlockable after a milestone.
- Six weapon designs, with four implemented in the first playable build.
- Ten to twelve augment designs, with eight implemented in the first playable build.
- Four regular monster types.
- One boss monster.
- One stage.
- Eight to ten unlock goals.
- Persistent local save data for unlocked content and milestone progress.
- A documented AI pixel-art asset pipeline.

The MVP does not include:

- Online accounts.
- Leaderboards.
- In-app purchases.
- Multiple biomes.
- Complex story scenes.
- Procedural map generation.
- Two-player co-op gameplay.

## Core Game Loop

1. The player selects an available character and starts a run.
2. The character moves with a virtual joystick.
3. Weapons attack automatically based on their behavior.
4. Monsters spawn around the player and increase in density over time.
5. Defeated monsters drop experience gems.
6. The player levels up and chooses one of three augments or weapon upgrades.
7. The run ends when the player dies, survives the target time, or defeats the boss.
8. After the run, milestone progress is saved and new content may unlock.

## Run Structure

The first run target is 5 minutes. The design allows this to stretch to 8 minutes after tuning.

- 0:00 to 1:00: low monster density, basic enemies.
- 1:00 to 3:00: more enemies, first durable monster appears.
- 3:00 to 5:00: mixed enemy waves, pressure increases.
- 5:00: boss appears.

Victory condition for MVP:

- Defeat the boss, or survive until the run timer ends if boss tuning is not final.

Failure condition:

- Player health reaches zero.

## Characters

### Starting Character: Rookie Constable

Korean name: 수습 포졸.

Role: balanced beginner character who patrols a haunted district office site.

Initial weapon:

- 환도 베기.

Base stats:

- Medium health.
- Medium movement speed.
- Medium attack power.
- No special mechanic in the first implementation.

### Unlock Character: Exorcist Taoist

Korean name: 퇴마 도사.

Role: ritual specialist with stronger talisman and ward synergy.

Unlock condition:

- Defeat the first boss once.

Base stats:

- Lower health than the constable.
- Medium movement speed.
- Small cooldown or elemental-effect bonus.

The unlock character can be data-defined in the MVP even if the first implementation only fully supports the starting character.

## Weapons

Six weapons are part of the design. The first playable build should implement at least four.

### 환도 베기

Creates a close-range sword slash toward nearby enemies.

- Starts unlocked.
- Clear beginner weapon for the 수습 포졸.
- Upgrades improve damage, arc size, and cooldown.

### 각궁 사격

Fires an arrow at the nearest enemy.

- Starts unlocked.
- Gives the starter build a readable ranged option.
- Upgrades improve damage, cooldown, and projectile speed.

### 부적 투척

Throws talismans that seek or pierce nearby spirits.

- Unlock condition: survive for 3 minutes once.
- Flexible anti-spirit weapon.
- Upgrades improve talisman count, pierce, and damage.

### 비격진천뢰

Launches a delayed explosive shell at clustered enemies.

- Unlock condition: defeat 300 monsters total.
- Strong against dense waves.
- Upgrades improve strike count, damage, and cooldown.

### 장승 결계

Creates temporary ward zones around carved village guardians.

- Unlock condition: defeat 500 monsters total.
- Area-control and defensive weapon.
- Upgrades improve field duration, area, and damage.

### 신기전 세례

Fires a volley of rocket arrows across the screen.

- Unlock condition: reach level 10 in one run.
- High-pressure late unlock for wide wave clearing.
- Upgrades improve volley count, pierce, and damage.

## Augments

Augments appear as three choices on level-up. Early augments are simple stat improvements. Advanced augments unlock later and create stronger build identity.

### Starting Augments

- 무예 단련: increases all weapon damage.
- 내공 순환: reduces weapon cooldowns.
- 속보: increases movement speed.
- 장승의 가호: increases max health.
- 매의 눈: increases experience pickup range.
- 탕약: improves healing effects.

### Unlockable Advanced Augments

- 연발 장전: adds one projectile to compatible weapons.
- 도깨비불: adds critical hit chance or elemental amplification.
- 화약 장인: improves 비격진천뢰 and 신기전 세례 effects.
- 배수진: increases damage while health is low.
- 퇴마 의식: reduces requirements for weapon evolution.
- 육중한 일격: increases knockback or stagger on compatible attacks.

Advanced augment unlock examples:

- Reach level 10 in one run: unlock 연발 장전.
- Survive 5 minutes once: unlock 도깨비불.
- Unlock three weapons: unlock 화약 장인.
- Win with less than 30 percent health remaining: unlock 배수진.

## Monsters

### 역병 쥐떼

Basic swarm enemy. Introduced immediately.

### 산적

Human raider enemy. Introduced after the first minute.

### 도깨비

Durable trickster enemy. Introduced around the second minute.

### 원혼

Drifting spirit enemy. Introduced later in the run after basic movement is understood.

### Boss: 원혼 장군

Large enemy with high health. Appears at the final timer mark.

The first boss can start as a simple high-health enemy with a contact damage pattern. More attack patterns can be added after the core loop feels good.

## Stage

The first stage is 달빛 폐관아, an abandoned district office yard under moonlight.

Gameplay requirements:

- Readable ground tiles that do not hide enemies or drops.
- Open movement space.
- Simple decorative obstacles only after movement and collision are stable.

Visual requirements:

- Pixel-art tiles.
- Limited palette with distinct colors for player, enemies, projectiles, experience gems, and danger effects.

## Unlock Goals

The unlock system should make the player feel progress even after a failed run.

Initial unlock goals:

- Survive 3 minutes once: unlock 부적 투척.
- Defeat 300 monsters total: unlock 비격진천뢰.
- Reach level 10 in one run: unlock 신기전 세례 and 연발 장전.
- Defeat the first boss once: unlock 퇴마 도사.
- Survive 5 minutes once: unlock 도깨비불.
- Unlock three weapons: unlock 화약 장인.
- Defeat 500 monsters total: unlock 장승 결계.
- Win a run with low health: unlock 배수진.

The game should show locked content with clear requirements. Requirements should be specific, measurable, and stored in save data.

## Future Co-op Mode

Two-player play is possible, but it should not be part of the first MVP. The recommended first co-op version is same-device local co-op rather than online multiplayer. Online co-op requires networking, synchronization, matchmaking, latency handling, reconnect behavior, and more QA than the first release should carry.

The MVP architecture should still keep a future co-op path open:

- Player logic should support multiple player entities instead of assuming only one global player forever.
- Input should be routed through a player input abstraction so a second joystick, controller, or touch region can be added later.
- Enemy targeting should be able to choose from a list of active players.
- Progression should remain account/save based, while run stats can record whether the run was solo or co-op.

Future local co-op concept:

- Solo and two-player runs share the same unlock collection.
- Landscape orientation gives two same-device players more usable thumb space than portrait, especially for role pairings such as 포졸 plus 도사 for front-line control and exorcism, or 무사 plus 의원 for damage and sustain.
- Both players can level up the shared run, or each player can receive alternating level-up choices after playtesting.
- Enemy count and boss health scale up when two players are active.
- Co-op unlock goals can be added after the solo loop is stable.

## Progression Data

Persistent local save data should track:

- Unlocked characters.
- Unlocked weapons.
- Unlocked augments.
- Total monster kills.
- Best survival time.
- Boss defeats.
- Per-weapon milestone counters where needed.
- Completed goals.

The first implementation can use a simple local storage solution. The data model should be structured so it can later move to a more robust save system without changing game rules.

## Architecture

Use Flutter for the app shell and Flame for the game runtime.

Primary units:

- App shell: navigation, menus, settings, save loading.
- Game world: Flame game instance, camera, stage, spawn system, timer.
- Player component: movement, health, stats, pickup behavior.
- Enemy components: movement, health, contact damage, death drops.
- Weapon system: automatic attacks and weapon upgrade levels.
- Augment system: level-up choices and stat modifiers.
- Progression system: unlock goals, save data, post-run updates.
- Asset catalog: maps logical asset ids to generated pixel-art files.
- Orientation and HUD layout: locks mobile builds to landscape and reserves the lower-left area for movement input while status, skill, and level-up UI use the extra horizontal space.

Each gameplay system should be data-driven where practical. Weapons, augments, monsters, characters, and unlock goals should be defined as data objects instead of hard-coded directly into one large game loop.

## Data Flow

At app startup:

1. Load save data.
2. Load content definitions.
3. Determine unlocked content.
4. Show the main menu.

At run start:

1. Create the Flame game instance.
2. Apply selected character data.
3. Add starting weapon.
4. Reset run-only state.

During a run:

1. Spawn system creates enemies based on timer.
2. Weapon system attacks automatically.
3. Enemy deaths grant experience drops and kill counters.
4. Level-up pauses or overlays the game.
5. Player chooses one of three options.

After a run:

1. Summarize time survived, kills, level, boss result, and weapon usage.
2. Apply progress to save data.
3. Evaluate unlock goals.
4. Save updated progress.
5. Show newly unlocked content.

## AI Pixel-Art Asset Pipeline

AI-generated pixel assets should be organized before implementation grows.

Asset folders:

- `assets/images/player`
- `assets/images/characters`
- `assets/images/monsters`
- `assets/images/weapons`
- `assets/images/effects`
- `assets/images/stages`
- `assets/images/ui`

Each asset should have:

- A short asset id.
- A prompt used to generate it.
- A target size such as 16x16, 24x24, 32x32, or 64x64.
- A transparent background when appropriate.
- A note for animation frames if needed.

The first asset batch should include:

- 수습 포졸 idle and walk frames.
- 역병 쥐떼, 산적, 도깨비, 원혼, and 원혼 장군 sprites.
- Icons for six weapons.
- Icons for starting and advanced augments.
- Experience gem.
- Health pickup.
- 달빛 폐관아 ground tile.

## Difficulty

Difficulty should be controlled through simple tuning tables:

- Spawn interval.
- Maximum enemy count.
- Enemy health multiplier over time.
- Enemy speed multiplier over time.
- Experience required per level.
- Boss health.

The MVP should prioritize readability and fun over punishing difficulty. The player should usually reach at least one level-up in the first minute.

## Error Handling

Missing save data:

- Create a default save with only starting content unlocked.

Missing asset:

- Use a visible placeholder sprite in development.
- Log the missing asset id.

Invalid content definition:

- Fail early in debug builds.
- Skip invalid optional content in release builds only if safe.

Save write failure:

- Keep progress in memory for the current session.
- Show a simple warning if progress cannot be saved.

## Testing Strategy

Automated tests should focus on data and progression rules first:

- Unlock goals trigger from the correct counters.
- Locked content is unavailable until requirements are met.
- Level-up choices only include valid unlocked weapons and augments.
- Weapon upgrade rules do not exceed max level.
- Save data loads defaults when no save exists.

Manual playtests should verify:

- Movement feels responsive on mobile.
- Enemies remain readable on the stage background.
- The player can understand level-up choices quickly.
- The first unlock happens within the first few runs.
- A 5-minute run has rising pressure but does not feel unfair.

## Git Plan

Use the current Git repository and keep commits meaningful.

Expected early commits:

1. Add approved game design spec.
2. Scaffold Flutter and Flame project.
3. Add game shell and main menu.
4. Add player movement and camera.
5. Add enemy spawning and contact damage.
6. Add first weapons and experience drops.
7. Add level-up augment choices.
8. Add unlock progression and save data.
9. Add AI-generated pixel-art asset batch.
10. Add mobile build preparation.

## Open Decisions For Implementation Planning

- Final Korean subtitle: 조선 생존록 or 조선 서바이벌.
- Exact package name for Android and iOS.
- Whether the first build targets Android only or Android plus iOS. Android builds can be produced on Windows with Android Studio, the Android SDK, and signing keys; iOS App Store or TestFlight builds require a Mac with Xcode.
- Which four weapons are implemented first.
- Which local save package is used.
- Whether two-player local co-op enters the second milestone or waits until after the first public test build.
- Docker does not solve iOS signing or App Store build requirements; keeping Flutter versioning fixed and GitHub branches synchronized is more important for release reliability.

These decisions do not block the design. They should be finalized in the implementation plan.
