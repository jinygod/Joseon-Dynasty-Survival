# Mobile Preview and Combat Presentation Design

## Goal

Improve local portrait-mobile testing and combat readability without changing
game balance, camera zoom, source artwork, or runtime layout on Android.

## Current State

- The app fills the browser window and has no development-only mobile preview.
- Runtime orientation is landscape-first, while the requested Chrome preview is
  a portrait 390 by 844 reference viewport.
- Actor visual sizes are centralized in `ActorRenderSizes`, but currently use
  the prior enlargement values: player 54, normal enemy 27, elite 40.5, and
  boss 63.
- Collision component sizes are player 24, normal enemy 18, elite 40, and boss
  42. Components use `Anchor.center`; actor bodies are rendered around a
  bottom-center pivot so their feet can remain fixed while art grows upward.
- The selected player artwork is a single 64 by 64 frame. It has no matching
  idle, walking, or attack frame sequence. Enemy sprites do contain move,
  attack, hit, and death animation rows.
- Normal and elite enemies do not have per-actor health bars, nameplates, or
  status labels. The boss health bar is a screen-space HUD element.
- Hwando slash already puts visual rotation and cone containment on one
  `MeleeArcComponent.direction`, but target selection does not exclude removing
  enemies, constrain the preferred target to attack range, define deterministic
  tie-breaking, or provide a no-target fallback direction.

## Architecture

The change is split into four focused units:

1. A Flutter-only mobile preview policy and frame at the application root.
2. Existing rank-aware actor render-size settings, updated without changing
   component collision sizes.
3. Render-only player motion state that never changes world position or hit
   geometry.
4. A deterministic hwando aim decision made once per attack and reused by the
   effect, cone test, damage selection, facing, and short attack motion.

No camera transform, combat definition, spawn definition, character stat, or
source PNG is changed.

## Mobile Preview

Add a small preview configuration with a 390 by 844 logical reference size.
The application root wraps its child only when all of these conditions hold:

- the target is web;
- the build is debug;
- `MOBILE_PREVIEW` is not explicitly set to `false`.

The preview uses a centered `FittedBox` with `BoxFit.contain` around a fixed
390 by 844 box. The outer area uses a plain neutral background. A scoped
`MediaQuery` reports the reference size and representative portrait safe-area
padding to the app inside the frame, so HUD and touch layout are evaluated
against mobile-like constraints.

Release web and every non-web target return the child unchanged. Therefore
Android receives neither preview margins nor a synthetic `MediaQuery`.

Document these commands:

```powershell
# Debug Chrome with portrait mobile preview (default)
flutter run -d chrome

# Debug Chrome using the full browser viewport
flutter run -d chrome --dart-define=MOBILE_PREVIEW=false
```

## Actor Rendering Sizes

Keep all current collision sizes and update only visual sizes:

| Actor tier | Before visual | After visual | Collision before/after |
|---|---:|---:|---:|
| Player | 54 | 108 | 24 |
| Normal enemy | 27 | 54 | 18 |
| Elite enemy | 40.5 | 81 | 40 |
| Boss | 63 | 126 | 42 |

This preserves the current visual hierarchy: elite is 1.5 times a normal enemy
and boss is approximately 2.33 times a normal enemy. Uniform scaling and
`FilterQuality.none` remain active. Player and enemy artwork continue to scale
around their bottom-center pivot, leaving the component anchor and foot point
unchanged.

The global boss health bar remains screen-space UI and needs no actor-relative
offset. No per-actor health bar, nameplate, or status-effect component currently
exists, so no nonexistent overlay is introduced. Damage numbers and combat
effects retain their existing world positions to avoid changing combat
feedback semantics.

Visual overlap can increase because separation and collision sizes remain
unchanged by design. It must be assessed in the portrait preview and reported;
it must not be hidden by changing camera zoom or gameplay separation.

## Player Procedural Motion

Because the approved player is a single frame, retain the static asset and add
small render-only motion:

- movement blend eases in and out rather than snapping;
- walking adds a low-amplitude vertical bob and slight alternating tilt;
- small complementary squash/stretch keeps the foot pivot stable;
- horizontal input updates the desired facing, while vertical-only input keeps
  the last valid horizontal facing;
- displayed facing interpolates over a short transition;
- stopping fades the current motion back to rest instead of returning abruptly
  to the first pose;
- an attack starts a roughly 0.15 second visual impulse with a small forward
  motion, rotation, and recoil while walking motion continues underneath it.

All transforms are applied inside `render` after saving the canvas. Component
`position`, `size`, movement input, camera tracking, collisions, cooldowns, and
damage timing remain untouched.

## Hwando Targeting and Direction Flow

At each hwando cooldown trigger:

1. Filter candidates to enemies that are alive and not scheduled for removal.
2. Keep candidates whose centers are within the existing effective hwando
   range. Do not change that range.
3. Select the smallest squared world distance from the player origin.
4. Break exact distance ties deterministically by enemy identifier and then by
   stable input order.
5. If no candidate exists, use the player's last movement direction, then last
   attack direction, then the default rightward direction.
6. Normalize and freeze the chosen base direction for the full slash.

The frozen direction constructs each `MeleeArcComponent`. Its effect rotation
and `containsEnemy` cone test already read the component direction. Damage
events are created only for enemies contained by that same cone. The first
hwando base direction is also returned in the weapon tick result so the player
uses it for facing and the short attack impulse. Multi-arc level behavior keeps
its existing fixed angular offsets, damage, knockback, cooldown, count, and
range.

If a target moves or dies after creation, the existing arc direction remains
unchanged. The next cooldown trigger performs a fresh selection.

## Testing

Add or update tests that prove:

- a 390 by 844 preview keeps its aspect ratio under larger and smaller parent
  constraints;
- preview configuration is disabled for non-web targets and release builds;
- actor visual sizes double while collision sizes and balance definitions stay
  unchanged;
- anchors and nearest-neighbor filtering remain intact;
- procedural movement changes render state without changing world position;
- beginning an attack while moving does not change movement input or distance;
- the closest valid enemy is selected for hwando;
- dead and removing enemies are excluded;
- exact distance ties resolve deterministically;
- no target uses last movement, then last attack, then the default direction;
- the arc effect angle and hit cone derive from the same normalized direction;
- damage targets are exactly the enemies inside that cone.

After focused red-green cycles, run formatting, Flutter analysis, the complete
Flutter test suite, a Chrome web build, and an Android debug build. Finally run
the debug Chrome preview and inspect portrait containment, safe areas, actor
foot alignment, sprite sharpness, combat readability, and dense-wave overlap.

## Scope Boundaries

Do not change actor health, damage, speed, enemy spawning, difficulty curves,
experience, level progression, weapon damage, weapon cooldown, weapon range,
animation frame timing, camera zoom, source images, or overall mobile UI
architecture. Do not add new characters, monsters, images, or large combat
system abstractions.
