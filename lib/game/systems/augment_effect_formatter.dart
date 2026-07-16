import '../content/ids.dart';

class AugmentEffectFormatter {
  const AugmentEffectFormatter();

  String describeLevelChange(AugmentDefinition definition, int currentLevel) {
    final descriptions = <AugmentCondition, List<String>>{};
    for (final effect in definition.effects) {
      descriptions
          .putIfAbsent(effect.condition, () => <String>[])
          .add(_describeEffect(effect, currentLevel));
    }

    return descriptions.entries
        .map((entry) {
          final description = entry.value.join(' · ');
          return switch (entry.key) {
            AugmentCondition.always => description,
            AugmentCondition.healthAtOrBelow35 => '체력 35% 이하: $description',
          };
        })
        .join(' · ');
  }

  String _describeEffect(AugmentEffect effect, int currentLevel) {
    final current = effect.valuePerLevel * currentLevel;
    final next = effect.valuePerLevel * (currentLevel + 1);
    return switch (effect.stat) {
      AugmentStat.weaponDamage => _percentage('무기 피해', current, next),
      AugmentStat.fireDamage => _percentage('화염 피해', current, next),
      AugmentStat.attackSpeed => _percentage('공격 속도', current, next),
      AugmentStat.criticalChance => _percentage('치명타', current, next),
      AugmentStat.weaponSize => _percentage('공격 크기', current, next),
      AugmentStat.moveSpeed => _percentage('이동 속도', current, next),
      AugmentStat.incomingContactDamage => _percentage(
        '받는 접촉 피해',
        current,
        next,
      ),
      AugmentStat.experienceGain => _percentage('경험치 획득', current, next),
      AugmentStat.pickupRadius => _numeric('획득 반경', current, next),
      AugmentStat.experienceRequirement => _percentage('필요 경험치', current, next),
      AugmentStat.maxHealth => _numeric('최대 체력', current, next),
      AugmentStat.healing => '체력 ${_number(effect.valuePerLevel)} 회복',
    };
  }

  String _percentage(String label, double current, double next) =>
      '$label ${_signed((current * 100).round())}% → '
      '${_signed((next * 100).round())}%';

  String _numeric(String label, double current, double next) =>
      '$label ${_signedNumber(current)} → ${_signedNumber(next)}';

  String _signed(int value) => value >= 0 ? '+$value' : '$value';

  String _signedNumber(double value) =>
      value >= 0 ? '+${_number(value)}' : _number(value);

  String _number(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(2);
}
