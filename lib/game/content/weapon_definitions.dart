import 'ids.dart';

const magicBolt = 'magic_bolt';
const bladeArc = 'blade_arc';
const orbitingDagger = 'orbiting_dagger';
const lightningStrike = 'lightning_strike';
const flameField = 'flame_field';
const iceShard = 'ice_shard';

const weaponDefinitions = <WeaponDefinition>[
  WeaponDefinition(
    id: magicBolt,
    name: 'Magic Bolt',
    element: ElementType.magic,
    maxLevel: 5,
    startsUnlocked: true,
  ),
  WeaponDefinition(
    id: bladeArc,
    name: 'Blade Arc',
    element: ElementType.physical,
    maxLevel: 5,
    startsUnlocked: true,
  ),
  WeaponDefinition(
    id: orbitingDagger,
    name: 'Orbiting Dagger',
    element: ElementType.physical,
    maxLevel: 5,
    startsUnlocked: false,
  ),
  WeaponDefinition(
    id: lightningStrike,
    name: 'Lightning Strike',
    element: ElementType.lightning,
    maxLevel: 5,
    startsUnlocked: false,
  ),
  WeaponDefinition(
    id: flameField,
    name: 'Flame Field',
    element: ElementType.fire,
    maxLevel: 5,
    startsUnlocked: false,
  ),
  WeaponDefinition(
    id: iceShard,
    name: 'Ice Shard',
    element: ElementType.ice,
    maxLevel: 5,
    startsUnlocked: false,
  ),
];
