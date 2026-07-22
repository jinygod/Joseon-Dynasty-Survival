abstract final class ContentRosterContract {
  static const characterIds = {
    'rookie_constable',
    'exorcist_dosa',
    'mountain_hunter',
  };

  static const weaponIds = {
    'hwando_slash',
    'gakgung_shot',
    'talisman_throw',
    'thunder_crash_bomb',
    'jangseung_ward',
    'singijeon_volley',
    'frost_flask',
    'wind_thunder_fan',
    'matchlock_cannon',
    'shaman_bells',
    'dokkaebi_chain',
    'hawk_summon',
  };

  static const augmentIds = {
    'martial_training',
    'quick_step',
    'inner_breath',
    'jangseung_blessing',
    'hawk_eye',
    'herbal_tonic',
    'rapid_reload',
    'goblin_fire',
    'powder_mastery',
    'last_stand',
    'ritual_shortcut',
    'heavy_strike',
    'iron_armor_training',
    'scholar_insight',
    'blood_oath',
    'ghost_step',
  };

  static const enemyIds = {
    'plague_rat_swarm',
    'bandit',
    'dokkaebi',
    'sakkat_specter',
    'vengeful_spirit',
    'plague_crow',
    'spear_bandit',
    'rotten_herbalist',
    'grave_ember',
    'black_hat_assassin',
    'broken_jangseung_spirit',
    'sorrowful_maiden_ghost',
    'fallen_general',
  };

  static const stageIds = {'moonlit_abandoned_office', 'plague_market'};
  static const bossIds = {
    'fallen_general',
    'plague_magistrate',
    'masked_executioner',
  };

  static const unlockGoalIds = {
    'survive_3_minutes',
    'defeat_300_enemies',
    'reach_level_10',
    'defeat_fallen_general',
    'survive_5_minutes',
    'unlock_three_weapons',
    'defeat_500_enemies',
    'low_health_win',
    'defeat_two_bosses',
    'unlock_six_weapons',
    'reach_level_5',
    'defeat_50_elites',
    'reach_level_15',
    'defeat_three_bosses',
    'win_first_run',
  };

  static const stageBossIds = <String, Set<String>>{
    'moonlit_abandoned_office': {'fallen_general', 'masked_executioner'},
    'plague_market': {'plague_magistrate'},
  };
}
