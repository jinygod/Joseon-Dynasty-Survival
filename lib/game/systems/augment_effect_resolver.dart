import 'dart:collection';
import 'dart:math';

import '../content/augment_definitions.dart';
import '../content/ids.dart';

class AugmentModifiers {
  AugmentModifiers({
    this.weaponDamageMultiplier = 1,
    this.attackSpeedMultiplier = 1,
    this.criticalChanceBonus = 0,
    this.weaponSizeMultiplier = 1,
    this.moveSpeedMultiplier = 1,
    this.incomingContactDamageMultiplier = 1,
    this.experienceGainMultiplier = 1,
    this.pickupRadiusBonus = 0,
    this.experienceRequirementMultiplier = 1,
    Map<ElementType, double> elementDamageMultipliers = const {},
  }) : elementDamageMultipliers = UnmodifiableMapView(
         Map<ElementType, double>.of(elementDamageMultipliers),
       );

  final double weaponDamageMultiplier;
  final double attackSpeedMultiplier;
  final double criticalChanceBonus;
  final double weaponSizeMultiplier;
  final double moveSpeedMultiplier;
  final double incomingContactDamageMultiplier;
  final double experienceGainMultiplier;
  final double pickupRadiusBonus;
  final double experienceRequirementMultiplier;
  final Map<ElementType, double> elementDamageMultipliers;
}

class AugmentEffectResolver {
  const AugmentEffectResolver();

  AugmentModifiers resolve({
    required Map<AugmentId, int> levels,
    double healthFraction = 1,
  }) {
    var weaponDamageBonus = 0.0;
    var fireDamageBonus = 0.0;
    var attackSpeedBonus = 0.0;
    var criticalChanceBonus = 0.0;
    var weaponSizeBonus = 0.0;
    var moveSpeedBonus = 0.0;
    var incomingDamageBonus = 0.0;
    var experienceGainBonus = 0.0;
    var pickupRadiusBonus = 0.0;
    var experienceRequirementBonus = 0.0;

    for (final entry in levels.entries) {
      final definition = augmentDefinitionFor(entry.key);
      if (definition == null || entry.value <= 0) continue;
      for (final effect in definition.effects) {
        if (effect.application == AugmentEffectApplication.onAcquire) continue;
        if (effect.condition == AugmentCondition.healthAtOrBelow35 &&
            !(healthFraction > 0 && healthFraction <= 0.35)) {
          continue;
        }
        final value = effect.valuePerLevel * entry.value;
        switch (effect.stat) {
          case AugmentStat.weaponDamage:
            weaponDamageBonus += value;
          case AugmentStat.fireDamage:
            fireDamageBonus += value;
          case AugmentStat.attackSpeed:
            attackSpeedBonus += value;
          case AugmentStat.criticalChance:
            criticalChanceBonus += value;
          case AugmentStat.weaponSize:
            weaponSizeBonus += value;
          case AugmentStat.moveSpeed:
            moveSpeedBonus += value;
          case AugmentStat.incomingContactDamage:
            incomingDamageBonus += value;
          case AugmentStat.experienceGain:
            experienceGainBonus += value;
          case AugmentStat.pickupRadius:
            pickupRadiusBonus += value;
          case AugmentStat.experienceRequirement:
            experienceRequirementBonus += value;
          case AugmentStat.maxHealth:
          case AugmentStat.healing:
            break;
        }
      }
    }

    return AugmentModifiers(
      weaponDamageMultiplier: max(0, 1 + weaponDamageBonus),
      attackSpeedMultiplier: max(0.1, 1 + attackSpeedBonus),
      criticalChanceBonus: criticalChanceBonus.clamp(0, 1).toDouble(),
      weaponSizeMultiplier: max(0.1, 1 + weaponSizeBonus),
      moveSpeedMultiplier: max(0.1, 1 + moveSpeedBonus),
      incomingContactDamageMultiplier: max(0, 1 + incomingDamageBonus),
      experienceGainMultiplier: max(0, 1 + experienceGainBonus),
      pickupRadiusBonus: pickupRadiusBonus,
      experienceRequirementMultiplier: (1 + experienceRequirementBonus)
          .clamp(0.2, 1)
          .toDouble(),
      elementDamageMultipliers: {
        if (fireDamageBonus != 0) ElementType.fire: max(0, 1 + fireDamageBonus),
      },
    );
  }
}
