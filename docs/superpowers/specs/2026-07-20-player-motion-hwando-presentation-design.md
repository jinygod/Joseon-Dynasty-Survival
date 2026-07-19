# Player Motion and Hwando Presentation Design

## Goal

Make the single-frame player character feel grounded and responsive instead of sliding or flipping like a rigid card, and connect the player pose, Hwando slash effect, and hit timing into one short attack action without changing combat balance.

## Existing Cause

- The active player asset is a single 64×64 frame, so no idle, walk, turn, or attack frames are available.
- `PlayerComponent` currently eases the entire render canvas from `scaleX = 1` to `scaleX = -1`. This passes through a nearly flat intermediate image and transforms everything rendered by the component rather than isolating the character sprite.
- Facing reacts to horizontal input above only `0.05`, with no candidate stabilization or minimum hold time. Small diagonal input noise can repeatedly request opposite directions.
- The procedural walk and attack transforms share one canvas transform and a 0.15-second sine pulse. There is no explicit wind-up, strike, impact, or recovery phase.
- `WeaponSystem` creates the slash effect and damage events in the same tick, and `PixelSurvivorGame` applies damage immediately. The visual effect therefore cannot meet a later, readable impact moment.
- `MeleeArcComponent` is centered on the player origin. It has no independent visual socket, so the slash appears detached from the sword hand while moving the component itself would also move the hit test origin.

## Chosen Approach

Use a small, deterministic presentation controller inside `PlayerComponent`, plus a short Hwando timing contract shared by `WeaponSystem`, `PixelSurvivorGame`, and `MeleeArcComponent`.

This is preferred over converting the whole player to a new child-component hierarchy because the current component is compact and has no child health bar or shadow. It is also preferred over a cross-fade or shader turn because the source art has no alternate frames and a shader would add complexity without providing a real turning pose.

## Facing Stabilization

- Ignore horizontal facing requests when normalized input has `abs(x) < 0.25`.
- Preserve the last committed horizontal facing during vertical movement and neutral input.
- A request for the opposite side becomes a candidate. Commit it only after it remains stable for 0.10 seconds.
- After committing a side, keep it for at least 0.12 seconds before another commit.
- Starting an attack immediately commits and locks the attack direction for the full 0.24-second attack presentation.
- Movement input continues to update world position during the lock. When the attack ends, the current meaningful horizontal movement request resumes the normal stabilization process.

## Turn Presentation

The turn lasts 0.10 seconds and affects only the character visual layer.

- First half: horizontal magnitude eases from `1.0` to `0.88`, with at most 2 degrees of lean toward the requested direction.
- Midpoint: the sprite-only facing sign changes discretely.
- Second half: horizontal magnitude and lean ease back to neutral.
- The pivot is the bottom-center foot point. The world position, collision size, component anchor, and foot point remain unchanged.
- The sprite flip is not applied to `super.render`, child components, shadows, hitboxes, weapon effects, or UI.

The 12% squash is intentionally small: it disguises the unavoidable single-frame mirror change without making the character rubbery or passing through a flat zero-width image.

## Locomotion Presentation

Because the current asset has one frame, movement remains procedural and affects only the character sprite layer.

- Movement blend eases in and out instead of snapping.
- Bob amplitude is capped at 1.5% of the displayed character height.
- Walk lean is capped at 2 degrees.
- Squash/stretch is capped at 3%.
- A small forward lean appears during movement start and settles into the walk cycle.
- Diagonal movement advances one stable walk phase; vertical movement does not change facing.
- Attack pose is added to the continuing movement pose, so automatic attacks never pause locomotion.

## Visual State

Expose a computed state with this priority:

`dead > hurt > attacking > moving > idle`

The state describes presentation priority only. Independent booleans such as moving and attacking remain available so lower-priority locomotion can be composed under the attack pose. Hurt and dead suppress attack presentation as appropriate and reset temporary turn/attack transforms safely.

## Hwando Timeline

One slash lasts 0.24 seconds:

| Phase | Time | Presentation |
|---|---:|---|
| Wind-up | 0.00–0.06 s | Face and lock the attack direction; pull the visual body slightly opposite the attack vector. |
| Strike | 0.06–0.14 s | Move the visual body slightly along the frozen direction and add a short torso rotation. Show the slash from the sword socket. |
| Impact | 0.11 s | Apply the already-selected damage events and show the brightest effect frame. |
| Recovery | 0.14–0.24 s | Ease visual offset, rotation, and scale back to neutral while movement continues. |

No global hit stop or camera shake is added. This avoids global timing changes and excessive repeated feedback during dense combat.

The cooldown is still consumed when the attack starts. Only Hwando damage delivery is delayed by 0.11 seconds; damage, range, knockback, target count, cooldown, and targeting rules remain unchanged.

## Shared Direction and Damage Timing

- `HwandoAimResolver` continues to produce the one normalized, frozen attack direction at attack start.
- `WeaponSystem` derives every Hwando arc and its damage cone from that direction.
- `WeaponTickResult` exposes a Hwando presentation cue containing the frozen direction, the Hwando damage events, and the 0.11-second impact delay.
- Non-Hwando damage events remain immediate.
- `PixelSurvivorGame` queues only the Hwando damage batch and releases it once at the impact time.
- A finished or interrupted visual effect cannot duplicate damage; queued batches are consumed exactly once.
- Repeated attacks replace the player's pose timeline cleanly while each already-created damage batch retains its own direction and due time.

## Effect Socket and Arc Rendering

- Hit testing remains centered on the existing player world origin and keeps the current range and cone.
- `MeleeArcComponent` receives a visual-only socket offset that does not alter `position`, `containsEnemy`, or damage calculations.
- The socket uses the 108-unit displayed player height, not the 24-unit collision component size.
- The base hand socket is approximately 12% of player height toward the committed facing side and 36% upward from the foot reference, with a small additional offset along the attack direction.
- Left and right sockets are exact mirrors around the player centerline.
- The effect pivot stays at the weapon-hand end of the arc. Its rotation uses the same `direction` used by `containsEnemy`.
- Effect visibility follows wind-up, strike, impact, and recovery progress and remains bounded so it does not cover the whole character.

## Rendering Boundaries

- Root component: world position, center anchor, collision size, movement, and camera tracking.
- Character visual transform: locomotion bob/lean/stretch plus turn and attack pose.
- Character sprite transform: committed left/right mirror only, pivoted at bottom center.
- Hwando effect: separate world component with a visual-only socket translation.
- UI, health information, collision, and any future shadow: outside both character transforms.

No new image assets are created or modified.

## Tests

Add or update automated tests for:

- horizontal dead zone and stable-candidate timing;
- minimum facing hold time and vertical-input preservation;
- attack-facing lock and post-attack facing recovery;
- bottom-center foot point and world geometry invariance through turns and attacks;
- bounded locomotion pose values and smooth return to neutral;
- state priority and combined moving/attacking behavior;
- wind-up, strike, impact, and recovery phase boundaries;
- one-time delayed Hwando damage while movement continues;
- shared effect angle and hit-cone direction;
- mirrored socket offsets for left and right attacks;
- complete pose reset and no transform accumulation across repeated attacks;
- unchanged movement speed, attack values, range, cooldown, knockback, and target count.

## Verification

Run:

- focused player, weapon, arc, and game-loop tests during TDD;
- `flutter analyze`;
- the full Flutter test suite;
- `flutter build web`;
- `flutter build apk --debug`.

Manual playtesting is explicitly left to the user. The final report will list a short set of turn, movement, socket, and attack-flow checks for that playtest.

