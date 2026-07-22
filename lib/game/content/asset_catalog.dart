class AssetCatalog {
  const AssetCatalog._();

  static final Set<String> allPaths = Set.unmodifiable([
    ...characters.values,
    ...monsters.values,
    ...weapons.values,
    ...augments.values,
    ...effects.values,
    ...stages.values,
    ...lobby.values,
    ...player.values,
  ]);

  static const characters = <String, String>{
    'rookie_constable':
        'assets/images/player/exorcist_swordswoman_static_64.png',
    'exorcist_dosa': 'assets/images/player/exorcist_dosa_128.png',
    'mountain_hunter':
        'assets/images/player/exorcist_swordswoman_static_64.png',
  };

  static const monsters = <String, String>{
    'plague_rat_swarm': 'assets/images/monsters/plague_rat_swarm_128.png',
    'bandit': 'assets/images/monsters/bandit_32.png',
    'dokkaebi': 'assets/images/monsters/dokkaebi_128.png',
    'sakkat_specter': 'assets/images/monsters/sakkat_specter_128.png',
    'vengeful_spirit': 'assets/images/monsters/vengeful_spirit_128.png',
    'plague_crow': 'assets/images/monsters/plague_rat_swarm_24.png',
    'spear_bandit': 'assets/images/monsters/bandit_32.png',
    'rotten_herbalist': 'assets/images/monsters/bandit_32.png',
    'grave_ember': 'assets/images/monsters/vengeful_spirit_32.png',
    'black_hat_assassin': 'assets/images/monsters/bandit_32.png',
    'broken_jangseung_spirit': 'assets/images/monsters/dokkaebi_32.png',
    'sorrowful_maiden_ghost': 'assets/images/monsters/vengeful_spirit_32.png',
    'fallen_general': 'assets/images/monsters/fallen_general_64.png',
    'plague_magistrate': 'assets/images/monsters/fallen_general_64.png',
    'masked_executioner': 'assets/images/monsters/fallen_general_64.png',
  };

  static const weapons = <String, String>{
    'hwando_slash': 'assets/images/effects/weapon_effects_atlas_64.png',
    'gakgung_shot': 'assets/images/effects/weapon_effects_atlas_64.png',
    'talisman_throw': 'assets/images/effects/weapon_effects_atlas_64.png',
    'thunder_crash_bomb': 'assets/images/effects/weapon_effects_atlas_64.png',
    'jangseung_ward': 'assets/images/effects/weapon_effects_atlas_64.png',
    'singijeon_volley': 'assets/images/effects/weapon_effects_atlas_64.png',
    'frost_flask': 'assets/images/effects/weapon_effects_atlas_64.png',
    'wind_thunder_fan': 'assets/images/effects/weapon_effects_atlas_64.png',
    'matchlock_cannon': 'assets/images/effects/weapon_effects_atlas_64.png',
    'shaman_bells': 'assets/images/effects/weapon_effects_atlas_64.png',
    'dokkaebi_chain': 'assets/images/effects/weapon_effects_atlas_64.png',
    'hawk_summon': 'assets/images/effects/weapon_effects_atlas_64.png',
  };

  static const augments = <String, String>{
    'martial_training': 'assets/images/effects/combat_effects_atlas_64.png',
    'quick_step': 'assets/images/effects/combat_effects_atlas_64.png',
    'inner_breath': 'assets/images/effects/combat_effects_atlas_64.png',
    'jangseung_blessing': 'assets/images/effects/combat_effects_atlas_64.png',
    'hawk_eye': 'assets/images/effects/combat_effects_atlas_64.png',
    'herbal_tonic': 'assets/images/effects/combat_effects_atlas_64.png',
    'rapid_reload': 'assets/images/effects/combat_effects_atlas_64.png',
    'goblin_fire': 'assets/images/effects/combat_effects_atlas_64.png',
    'powder_mastery': 'assets/images/effects/combat_effects_atlas_64.png',
    'last_stand': 'assets/images/effects/combat_effects_atlas_64.png',
    'ritual_shortcut': 'assets/images/effects/combat_effects_atlas_64.png',
    'heavy_strike': 'assets/images/effects/combat_effects_atlas_64.png',
    'iron_armor_training': 'assets/images/effects/combat_effects_atlas_64.png',
    'scholar_insight': 'assets/images/effects/combat_effects_atlas_64.png',
    'blood_oath': 'assets/images/effects/combat_effects_atlas_64.png',
    'ghost_step': 'assets/images/effects/combat_effects_atlas_64.png',
  };

  static const effects = <String, String>{
    'experience_gem': 'assets/images/effects/combat_effects_atlas_64.png',
    // Temporary art slot. Replace this path when the final spirit jade sprite lands.
    'spirit_jade': 'assets/images/effects/combat_effects_atlas_64.png',
    'healing_item': 'assets/images/effects/healing_item_16.png',
    'hwando_slash_effect': 'assets/images/effects/hwando_slash_effect_64.png',
    'weapon_effects_atlas': 'assets/images/effects/weapon_effects_atlas_64.png',
    'combat_effects_atlas': 'assets/images/effects/combat_effects_atlas_64.png',
  };

  static const stages = <String, String>{
    'moonlit_abandoned_office':
        'assets/images/effects/combat_effects_atlas_64.png',
    'plague_market': 'assets/images/effects/combat_effects_atlas_64.png',
  };

  static const lobby = <String, String>{
    'government_office': 'assets/images/effects/combat_effects_atlas_64.png',
  };

  static const player = <String, String>{
    'rookie_constable_player':
        'assets/images/player/exorcist_swordswoman_static_64.png',
    'exorcist_dosa_atlas': 'assets/images/player/exorcist_dosa_128.png',
  };
}
