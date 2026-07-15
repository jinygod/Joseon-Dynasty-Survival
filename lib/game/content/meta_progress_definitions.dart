import 'character_definitions.dart';

const commonTrainingNodeIds = <String>{
  'common.max_health',
  'common.base_damage',
  'common.pickup_range',
  'common.move_speed',
};

const characterTrainingNodeIds = <String>{
  'max_health',
  'base_damage',
  'move_speed',
  'pickup_range',
  'cooldown',
  'survival',
};

const coreTraitIdsByCharacter = <String, Set<String>>{
  rookieConstable: {'constable.stalwart', 'constable.counter_stance'},
  exorcistDosa: {'dosa.talisman_mastery', 'dosa.spirit_burn'},
  mountainHunter: {'hunter.hawk_eye', 'hunter.trapcraft'},
};

const oneTimeShopItemIds = <String>{
  'manual.rookie_constable',
  'manual.exorcist_dosa',
  'manual.mountain_hunter',
};
