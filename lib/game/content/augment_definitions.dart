import 'ids.dart';

const attackUp = 'attack_up';
const haste = 'haste';
const swiftFeet = 'swift_feet';
const vitality = 'vitality';
const magnetSense = 'magnet_sense';
const recovery = 'recovery';
const extraProjectile = 'extra_projectile';
const criticalSpark = 'critical_spark';
const elementFocus = 'element_focus';
const desperation = 'desperation';
const evolutionShortcut = 'evolution_shortcut';
const heavyImpact = 'heavy_impact';

const augmentDefinitions = <AugmentDefinition>[
  AugmentDefinition(
    id: attackUp,
    name: 'Attack Up',
    maxLevel: 5,
    startsUnlocked: true,
  ),
  AugmentDefinition(
    id: haste,
    name: 'Haste',
    maxLevel: 5,
    startsUnlocked: true,
  ),
  AugmentDefinition(
    id: swiftFeet,
    name: 'Swift Feet',
    maxLevel: 5,
    startsUnlocked: true,
  ),
  AugmentDefinition(
    id: vitality,
    name: 'Vitality',
    maxLevel: 5,
    startsUnlocked: true,
  ),
  AugmentDefinition(
    id: magnetSense,
    name: 'Magnet Sense',
    maxLevel: 5,
    startsUnlocked: true,
  ),
  AugmentDefinition(
    id: recovery,
    name: 'Recovery',
    maxLevel: 5,
    startsUnlocked: true,
  ),
  AugmentDefinition(
    id: extraProjectile,
    name: 'Extra Projectile',
    maxLevel: 1,
    startsUnlocked: false,
  ),
  AugmentDefinition(
    id: criticalSpark,
    name: 'Critical Spark',
    maxLevel: 5,
    startsUnlocked: false,
  ),
  AugmentDefinition(
    id: elementFocus,
    name: 'Element Focus',
    maxLevel: 5,
    startsUnlocked: false,
  ),
  AugmentDefinition(
    id: desperation,
    name: 'Desperation',
    maxLevel: 3,
    startsUnlocked: false,
  ),
  AugmentDefinition(
    id: evolutionShortcut,
    name: 'Evolution Shortcut',
    maxLevel: 1,
    startsUnlocked: false,
  ),
  AugmentDefinition(
    id: heavyImpact,
    name: 'Heavy Impact',
    maxLevel: 5,
    startsUnlocked: false,
  ),
];
