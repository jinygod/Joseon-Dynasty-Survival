# Pixel Survivor Design

Date: 2026-06-30
Status: Approved for planning
Target: Flutter mobile game using Flame

## Goal

Build a small but expandable Vampire Survivors-like mobile game in Flutter. The first playable version should be simple enough to finish quickly, but it must already include a reason to keep playing: unlockable weapons, augments, characters, and progression goals.

The first release target is a 5 to 8 minute survival run with one starting character, one stage, several enemy types, automatic weapons, level-up choices, and persistent unlock progress.

## Product Pillars

- Fast runs: one session should be playable in a short break.
- Automatic combat: the player focuses on movement, positioning, and build choices.
- Unlock momentum: each run should make progress toward at least one visible goal.
- Pixel identity: characters, monsters, weapons, stage tiles, and UI icons use AI-generated pixel art.
- Mobile-first controls: the game is designed around a virtual joystick and touch-friendly choices.

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

### Starting Character: Apprentice Wanderer

Role: balanced beginner character.

Initial weapon:

- Magic Bolt.

Base stats:

- Medium health.
- Medium movement speed.
- Medium attack power.
- No special mechanic in the first implementation.

### Unlock Character: Iron Pilgrim

Role: slower but sturdier character.

Unlock condition:

- Defeat the first boss once.

Base stats:

- Higher health.
- Lower movement speed.
- Small damage resistance bonus.

The unlock character can be data-defined in the MVP even if the first implementation only fully supports the starting character.

## Weapons

Six weapons are part of the design. The first playable build should implement at least four.

### Magic Bolt

Fires a projectile at the nearest enemy.

- Starts unlocked.
- Clear beginner weapon.
- Upgrades improve damage, cooldown, and projectile speed.

### Blade Arc

Creates a short-range slash toward nearby enemies.

- Starts unlocked.
- Rewards close-range positioning.
- Upgrades improve damage, arc size, and cooldown.

### Orbiting Dagger

Creates one or more daggers that rotate around the player.

- Unlock condition: survive for 3 minutes once.
- Defensive and consistent.
- Upgrades improve dagger count, radius, and damage.

### Lightning Strike

Periodically strikes random enemies.

- Unlock condition: defeat 300 monsters total.
- Good for scattered enemies.
- Upgrades improve strike count, damage, and cooldown.

### Flame Field

Creates temporary damaging zones on the ground.

- Unlock condition: defeat 500 monsters total.
- Area-control weapon.
- Upgrades improve field duration, area, and damage.

### Ice Shard

Fires piercing shards that slow enemies.

- Unlock condition: reach level 10 in one run.
- Crowd-control weapon.
- Upgrades improve pierce count, slow strength, and damage.

## Augments

Augments appear as three choices on level-up. Early augments are simple stat improvements. Advanced augments unlock later and create stronger build identity.

### Starting Augments

- Attack Up: increases all weapon damage.
- Haste: reduces weapon cooldowns.
- Swift Feet: increases movement speed.
- Vitality: increases max health.
- Magnet Sense: increases experience pickup range.
- Recovery: improves healing effects.

### Unlockable Advanced Augments

- Extra Projectile: adds one projectile to compatible weapons.
- Critical Spark: adds critical hit chance.
- Element Focus: improves fire, ice, and lightning effects.
- Desperation: increases damage while health is low.
- Evolution Shortcut: reduces requirements for weapon evolution.
- Heavy Impact: increases knockback or stagger on compatible attacks.

Advanced augment unlock examples:

- Reach level 10 in one run: unlock Extra Projectile.
- Survive 5 minutes once: unlock Critical Spark.
- Unlock three weapons: unlock Element Focus.
- Win with less than 30 percent health remaining: unlock Desperation.

## Monsters

### Slime

Basic slow enemy. Introduced immediately.

### Bat

Fast but fragile enemy. Introduced after the first minute.

### Armored Husk

Slow durable enemy. Introduced around the second minute.

### Spitter

Ranged or semi-ranged enemy. Introduced later in the run after basic movement is understood.

### Boss: Grave Golem

Large enemy with high health. Appears at the final timer mark.

The first boss can start as a simple high-health enemy with a contact damage pattern. More attack patterns can be added after the core loop feels good.

## Stage

The first stage is a ruined grassland with scattered stone ruins.

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

- Survive 3 minutes once: unlock Orbiting Dagger.
- Defeat 300 monsters total: unlock Lightning Strike.
- Reach level 10 in one run: unlock Ice Shard and Extra Projectile.
- Defeat the first boss once: unlock Iron Pilgrim.
- Survive 5 minutes once: unlock Critical Spark.
- Unlock three weapons: unlock Element Focus.
- Defeat 500 monsters total: unlock Flame Field.
- Win a run with low health: unlock Desperation.

The game should show locked content with clear requirements. Requirements should be specific, measurable, and stored in save data.

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

- Starting character idle and walk frames.
- Slime, bat, armored husk, spitter, and boss sprites.
- Icons for six weapons.
- Icons for starting and advanced augments.
- Experience gem.
- Health pickup.
- Ruined grassland ground tile.

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

- Final Korean or English game title.
- Exact package name for Android and iOS.
- Whether the first build targets Android only or Android plus iOS.
- Which four weapons are implemented first.
- Which local save package is used.

These decisions do not block the design. They should be finalized in the implementation plan.
