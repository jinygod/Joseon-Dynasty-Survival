import 'ids.dart';

class EnemyBehaviorProfile {
  const EnemyBehaviorProfile({
    required this.id,
    required this.kind,
    this.warningSeconds = 0,
    this.activeSeconds = 0,
    this.recoverySeconds = 0,
    this.cooldownSeconds = 0,
    this.movementMultiplier = 1,
    this.range = 0,
    this.effectMultiplier = 1,
    this.maxOwnedEffects = 0,
    this.preferredRange = 0,
    this.minimumRange = 0,
    this.projectileSpeed = 0,
  });

  final EnemyBehaviorProfileId id;
  final EnemyBehaviorKind kind;
  final double warningSeconds;
  final double activeSeconds;
  final double recoverySeconds;
  final double cooldownSeconds;
  final double movementMultiplier;
  final double range;
  final double effectMultiplier;
  final int maxOwnedEffects;
  final double preferredRange;
  final double minimumRange;
  final double projectileSpeed;
}

const enemyBehaviorProfiles = <EnemyBehaviorProfileId, EnemyBehaviorProfile>{
  'chase': EnemyBehaviorProfile(id: 'chase', kind: EnemyBehaviorKind.chase),
  'swarm': EnemyBehaviorProfile(id: 'swarm', kind: EnemyBehaviorKind.swarm),
  'dash': EnemyBehaviorProfile(
    id: 'dash',
    kind: EnemyBehaviorKind.dash,
    warningSeconds: .5,
    activeSeconds: .35,
    recoverySeconds: .18,
    cooldownSeconds: 2.4,
    movementMultiplier: 3.2,
  ),
  'tank': EnemyBehaviorProfile(id: 'tank', kind: EnemyBehaviorKind.tank),
  'sakkat_ranged': EnemyBehaviorProfile(
    id: 'sakkat_ranged',
    kind: EnemyBehaviorKind.ranged,
    warningSeconds: .7,
    activeSeconds: .05,
    recoverySeconds: .3,
    cooldownSeconds: 2.6,
    range: 420,
    preferredRange: 170,
    minimumRange: 105,
    projectileSpeed: 150,
  ),
  'crow_dive': EnemyBehaviorProfile(
    id: 'crow_dive',
    kind: EnemyBehaviorKind.dive,
    warningSeconds: .45,
    activeSeconds: .42,
    recoverySeconds: .3,
    cooldownSeconds: 2.8,
    movementMultiplier: 3.6,
    range: 22,
  ),
  'spear_thrust': EnemyBehaviorProfile(
    id: 'spear_thrust',
    kind: EnemyBehaviorKind.thrust,
    warningSeconds: .55,
    activeSeconds: .18,
    recoverySeconds: .45,
    cooldownSeconds: 2.2,
    movementMultiplier: 1.8,
    range: 54,
  ),
  'poison_death_zone': EnemyBehaviorProfile(
    id: 'poison_death_zone',
    kind: EnemyBehaviorKind.deathZone,
    activeSeconds: 4,
    range: 38,
    effectMultiplier: .35,
    maxOwnedEffects: 1,
  ),
  'grave_haste_aura': EnemyBehaviorProfile(
    id: 'grave_haste_aura',
    kind: EnemyBehaviorKind.hasteAura,
    activeSeconds: .2,
    range: 96,
    effectMultiplier: .2,
  ),
  'assassin_double_dash': EnemyBehaviorProfile(
    id: 'assassin_double_dash',
    kind: EnemyBehaviorKind.doubleDash,
    warningSeconds: .55,
    activeSeconds: .28,
    recoverySeconds: .16,
    cooldownSeconds: 3.2,
    movementMultiplier: 4,
    range: 24,
  ),
  'jangseung_shockwave': EnemyBehaviorProfile(
    id: 'jangseung_shockwave',
    kind: EnemyBehaviorKind.shockwave,
    warningSeconds: .8,
    activeSeconds: .12,
    recoverySeconds: .55,
    cooldownSeconds: 3.8,
    range: 88,
  ),
  'maiden_scream': EnemyBehaviorProfile(
    id: 'maiden_scream',
    kind: EnemyBehaviorKind.scream,
    warningSeconds: .9,
    activeSeconds: .15,
    recoverySeconds: .5,
    cooldownSeconds: 4.2,
    range: 120,
    effectMultiplier: .75,
  ),
};

EnemyBehaviorProfile enemyBehaviorProfileFor(EnemyBehaviorProfileId id) =>
    enemyBehaviorProfiles[id] ?? enemyBehaviorProfiles['chase']!;
