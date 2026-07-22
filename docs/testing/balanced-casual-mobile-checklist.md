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

## Enemy behavior and combat comfort

- [ ] Dash warning gives enough time and direction information to evade.
- [ ] Ranged warning and projectile remain visible through mastery effects.
- [ ] Dokkaebi front shield direction is obvious, and side/rear or bypass hits
      communicate a different result.
- [ ] Strong attacks use limited shake and hit-stop; ordinary attacks do not
      create continuous shake.
- [ ] No effect whites out the whole screen or hides an unavoidable enemy
      attack.
- [ ] Damage numbers and repeated effects remain bounded in late combat.

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
