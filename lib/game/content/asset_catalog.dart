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
    'exorcist_dosa': 'assets/images/player/exorcist_swordswoman_static_64.png',
    'mountain_hunter':
        'assets/images/player/exorcist_swordswoman_static_64.png',
  };

  static const monsters = <String, String>{
    'plague_rat_swarm': 'assets/images/monsters/plague_rat_swarm_24.png',
    'bandit': 'assets/images/monsters/bandit_32.png',
    'dokkaebi': 'assets/images/monsters/dokkaebi_32.png',
    'sakkat_specter': 'assets/images/enemies/sakkat_specter_128.png',
    'vengeful_spirit': 'assets/images/monsters/vengeful_spirit_32.png',
    'plague_crow': 'assets/images/enemies/plague_crow_128.png',
    'spear_bandit': 'assets/images/enemies/spear_bandit_128.png',
    'rotten_herbalist': 'assets/images/enemies/rotten_herbalist_128.png',
    'grave_ember': 'assets/images/enemies/grave_ember_128.png',
    'black_hat_assassin': 'assets/images/enemies/black_hat_assassin_128.png',
    'broken_jangseung_spirit':
        'assets/images/enemies/broken_jangseung_spirit_128.png',
    'sorrowful_maiden_ghost':
        'assets/images/enemies/sorrowful_maiden_ghost_128.png',
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
    'enemy_poison_pool': 'assets/images/vfx/enemy/poison_pool_128.png',
    'enemy_shockwave': 'assets/images/vfx/enemy/shockwave_128.png',
    'enemy_spirit_scream': 'assets/images/vfx/enemy/spirit_scream_128.png',
    'enemy_line_telegraph': 'assets/images/vfx/enemy/line_telegraph_128.png',
    'enemy_ranged_telegraph':
        'assets/images/vfx/enemy/ranged_telegraph_128.png',
    'enemy_radial_telegraph':
        'assets/images/vfx/enemy/radial_telegraph_128.png',
    'enemy_shield_block_flash':
        'assets/images/vfx/enemy/shield_block_flash_128.png',
    'sakkat_spirit_projectile':
        'assets/images/projectiles/enemy/sakkat_spirit_projectile_128.png',
    'experience_gem': 'assets/images/effects/combat_effects_atlas_64.png',
    // Temporary art slot. Replace this path when the final spirit jade sprite lands.
    'spirit_jade': 'assets/images/effects/combat_effects_atlas_64.png',
    'hwando_slash_trail_128': 'assets/images/vfx/hwando_slash_trail_128.png',
    'hwando_slash_impact_128': 'assets/images/vfx/hwando_slash_impact_128.png',
    'hwando_blade_wave_trail_128':
        'assets/images/vfx/hwando_blade_wave_trail_128.png',
    'hwando_blade_wave_impact_128':
        'assets/images/vfx/hwando_blade_wave_impact_128.png',
    'hwando_master_circle_trail_128':
        'assets/images/vfx/hwando_master_circle_trail_128.png',
    'hwando_master_circle_impact_128':
        'assets/images/vfx/hwando_master_circle_impact_128.png',
    'hwando_master_finisher_trail_128':
        'assets/images/vfx/hwando_master_finisher_trail_128.png',
    'hwando_master_finisher_impact_128':
        'assets/images/vfx/hwando_master_finisher_impact_128.png',
    'sealing_slash_128': 'assets/images/vfx/player/sealing_slash_128.png',
    'wind_thunder_fan_128': 'assets/images/vfx/player/wind_thunder_fan_128.png',
    'singijeon_128': 'assets/images/projectiles/player/singijeon_128.png',
    'jangseung_ward_128': 'assets/images/zones/player/jangseung_ward_128.png',
    'frost_field_128': 'assets/images/zones/player/frost_field_128.png',
    'talisman_attachment_128':
        'assets/images/vfx/player/talisman_attachment_128.png',
    'talisman_transfer_128':
        'assets/images/vfx/player/talisman_transfer_128.png',
    'talisman_explosion_128':
        'assets/images/vfx/player/talisman_explosion_128.png',
    'talisman_ward_128': 'assets/images/zones/player/talisman_ward_128.png',
    'weapon_effects_atlas': 'assets/images/effects/weapon_effects_atlas_64.png',
    'combat_effects_atlas': 'assets/images/effects/combat_effects_atlas_64.png',
  };

  static const stages = <String, String>{
    'moonlit_abandoned_office':
        'assets/images/tiles/moonlit_office_tiles_128.png',
    'plague_market': 'assets/images/tiles/plague_market_tiles_128.png',
  };

  static const lobby = <String, String>{
    'government_office': 'assets/images/effects/combat_effects_atlas_64.png',
  };

  static const player = <String, String>{
    'rookie_constable_player':
        'assets/images/player/exorcist_swordswoman_static_64.png',
  };
}
