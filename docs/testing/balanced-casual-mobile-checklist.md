# Balanced Casual Physical-Mobile Play Checklist

This checklist is intentionally unchecked. Automated goldens, host simulation,
and successful builds do not prove physical-device readability, feel, sound,
thermal stability, or a player's willingness to start a second run.

## Test record

- [ ] Tester name:
- [ ] Device / Android version:
- [ ] Build commit:
- [ ] APK SHA-256:
- [ ] Session date and duration:
- [ ] Screen recording or screenshot path:
- [ ] Profile-mode timing / log path:

## Silhouette and density

- [ ] At 390x844-equivalent portrait scale, the exorcist swordsman remains
      immediately distinguishable from every enemy while stationary, moving,
      attacking, hit, and dying.
- [ ] Plague-rat swarm, vengeful spirit, sakkat specter, and dokkaebi are
      distinguishable from silhouette alone at normal play distance.
- [ ] The authored bandit remains readable beside the player and the larger
      black-hat-assassin variant without looking like a player clone.
- [ ] Plague crow, spear bandit, rotten herbalist, grave ember, black-hat
      assassin, broken jangseung spirit, and sorrowful maiden ghost all render
      as authored family art; no square enemy fallback appears while moving,
      attacking, hit, or dying.
- [ ] In the late window, count a representative frame and record whether
      30-55 live enemies are visible without losing the player position.
- [ ] When enemies overlap, the dash and ranged warnings remain readable.
- [ ] The compact HUD does not cover the player or hide the nearest threat.

## Weapon and synergy readability

- [ ] Hwando level 1 reads as a short directed fan slash.
- [ ] Hwando master reads as a different multi-stage circular sword storm,
      including opener, left/right arcs, circle, and finisher.
- [ ] Talisman attachment, delayed burst, transfer, and five-color ward read in
      that order without needing damage numbers.
- [ ] A master ward's boundary and slow-control area are readable under a dense
      enemy pack.
- [ ] Sealing Slash is distinguishable by name, gold/five-color presentation,
      and its short unique sound without repeatedly obscuring the HUD.
- [ ] Visual direction, radius, and timing match the actual hit result for
      hwando master, talisman ward, and Sealing Slash.
- [ ] Frost fields read as crystalline ice sigils rather than plain circles at
      normal, strong, and master tiers.
- [ ] Player projectiles retain a visible body, bright core, accent edge, and
      directional trail over both pale terrain and crowded mastery effects.

## Enemy behavior and combat comfort

- [ ] Dash warning gives enough time and direction information to evade.
- [ ] Ranged warning and projectile remain visible through mastery effects.
- [ ] Poison, shockwave, and scream hazards remain distinct from one another
      and from player frost/ward areas at normal viewing distance.
- [ ] Dokkaebi front shield direction is obvious, and side/rear or bypass hits
      communicate a different result.
- [ ] Strong attacks use limited shake and hit-stop; ordinary attacks do not
      create continuous shake.
- [ ] No effect whites out the whole screen or hides an unavoidable enemy
      attack.
- [ ] Damage numbers and repeated effects remain bounded in late combat.

## Progress and pickup readability

- [ ] The level badge and XP track remain fully inside the portrait SafeArea;
      neither is clipped by the screen edge, pause button, or device cutout.
- [ ] Current/required XP and the filled portion of the track are readable at
      a glance without hiding the health/time/kills row.
- [ ] Default and merged XP gems remain recognizable as cyan diamonds on pale
      terrain, under enemies, and beside bright weapon effects.
- [ ] A high-value merged gem is visibly larger/brighter than a one-XP gem but
      does not imply a larger pickup radius.

## Lobby presentation and interaction

- [ ] On the physical device, bundled SongMyung and Gowun Batang render every
      Korean lobby label without tofu glyphs, clipping, or broken syllables.
- [ ] Pressing and releasing 출진 and each dock control communicates a clear
      change in button depth without shifting or obscuring its label.
- [ ] In a one-handed portrait grip, the 출진 action and all four dock targets
      remain comfortable to reach with the thumb and do not cause mistaps.
- [ ] At the Android 2.0 text-scale setting, lobby titles, status chips, stage
      copy, 출진, and dock labels remain visible without overlap or clipping.
- [ ] With gesture navigation and a display cutout enabled, the command bar,
      stage card, 출진 action, and dock remain fully inside the SafeArea.
- [ ] Profile-mode lobby tab changes and the transition from lobby to stage
      selection sustain 60 FPS on the physical device; record timing evidence.

## Physical Android performance and replay signal

- [ ] Profile-mode late-window average FPS (record exact value):
- [ ] Profile-mode late-window minimum FPS (record exact value):
- [ ] Peak RSS / heap and thermal state (record exact values):
- [ ] No visible animation hitch occurs when the first master ward or hwando
      master sequence starts.
- [ ] Touch joystick and pause remain reliable during the densest frame.
- [ ] The tester voluntarily started a second run; record yes/no and reason:

## Notes

- Observed strengths:
- Readability failures:
- Combat-feel failures:
- Required follow-up before approval:
