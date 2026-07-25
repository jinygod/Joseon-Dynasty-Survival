class AssetCatalog {
  const AssetCatalog._();

  static final Set<String> allPaths = Set.unmodifiable([
    ...characters.values,
    ...characterPortraits.values,
    ...monsters.values,
    ...weapons.values,
    ...augments.values,
    ...effects.values,
    ...stages.values,
    ...stagePresentation.values,
    ...lobby.values,
    ...lobbyScene.values,
    ...lobbyFrames.values,
    ...lobbyIcons.values,
    ...lobbyCharacters.values,
    ...player.values,
  ]);

  static const characters = <String, String>{
    'rookie_constable': 'assets/images/player/exorcist_dosa_128.png',
    'exorcist_dosa': 'assets/images/player/exorcist_dosa_128.png',
    'mountain_hunter':
        'assets/images/player/exorcist_swordswoman_static_64.png',
  };

  static const characterPortraits = <String, String>{
    'rookie_constable':
        'assets/images/characters/rookie_constable_portrait.png',
    'exorcist_dosa': 'assets/images/characters/exorcist_dosa_portrait.png',
    'mountain_hunter': 'assets/images/characters/mountain_hunter_portrait.png',
  };

  static const monsters = <String, String>{
    'plague_rat_swarm': 'assets/images/monsters/plague_rat_swarm_128.png',
    'bandit': 'assets/images/monsters/bandit_128.png',
    'dokkaebi': 'assets/images/monsters/dokkaebi_128.png',
    'sakkat_specter': 'assets/images/enemies/sakkat_specter_128.png',
    'vengeful_spirit': 'assets/images/monsters/vengeful_spirit_128.png',
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
    'hwando_slash_ribbon_hd':
        'assets/images/effects/hwando_slash_ribbon_512.png',
    'hwando_slash_trail_128': 'assets/images/vfx/hwando_slash_trail_128.png',
    'hwando_slash_impact_128': 'assets/images/vfx/hwando_slash_impact_128.png',
    'hwando_release_windup_128':
        'assets/images/vfx/hwando/hwando_windup_128.png',
    'hwando_release_strike_128':
        'assets/images/vfx/hwando/hwando_strike_128.png',
    'hwando_release_recovery_128':
        'assets/images/vfx/hwando/hwando_recovery_128.png',
    'hwando_release_contact_128':
        'assets/images/vfx/hwando/hwando_contact_128.png',
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
    'matchlock_shot_128':
        'assets/images/projectiles/player/matchlock_shot_128.png',
    'hawk_flight_128': 'assets/images/projectiles/player/hawk_flight_128.png',
    'projectile_contact_128':
        'assets/images/vfx/player/projectile_contact_128.png',
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
    'government_office':
        'assets/images/stages/joseon_moonlit_lobby_1536x2730.png',
  };

  static const lobbyScene = <String, String>{
    'night_palace_landscape':
        'assets/images/stages/joseon_night_palace_landscape.png',
    'character_shadow': 'assets/images/ui/lobby/character_shadow.png',
  };

  static const lobbyCharacters = <String, String>{
    'rookie_constable': 'assets/images/characters/lobby/rookie_constable.png',
    'exorcist_dosa': 'assets/images/characters/lobby/exorcist_dosa.png',
    'mountain_hunter': 'assets/images/characters/lobby/mountain_hunter.png',
  };

  static const lobbyFrames = <String, String>{
    'profile': 'assets/images/ui/lobby/frame_profile.png',
    'resource': 'assets/images/ui/lobby/frame_resource.png',
    'side_command': 'assets/images/ui/lobby/frame_side_command.png',
    'stage_plaque': 'assets/images/ui/lobby/frame_stage_plaque.png',
    'deploy': 'assets/images/ui/lobby/frame_deploy.png',
    'quick_action': 'assets/images/ui/lobby/frame_quick_action.png',
    'primary_navigation': 'assets/images/ui/lobby/frame_primary_navigation.png',
    'feature_notice': 'assets/images/ui/lobby/frame_feature_notice.png',
  };

  static const lobbyIcons = <String, String>{
    'coin': 'assets/images/ui/lobby/icon_coin.png',
    'spirit_jade': 'assets/images/ui/lobby/icon_spirit_jade.png',
    'settings': 'assets/images/ui/lobby/icon_settings.png',
    'shop': 'assets/images/ui/lobby/icon_shop.png',
    'mission': 'assets/images/ui/lobby/icon_mission.png',
    'pass': 'assets/images/ui/lobby/icon_pass.png',
    'package': 'assets/images/ui/lobby/icon_package.png',
    'mail': 'assets/images/ui/lobby/icon_mail.png',
    'compendium': 'assets/images/ui/lobby/icon_compendium.png',
    'records': 'assets/images/ui/lobby/icon_records.png',
    'character': 'assets/images/ui/lobby/icon_character.png',
    'combat': 'assets/images/ui/lobby/icon_combat.png',
    'challenge': 'assets/images/ui/lobby/icon_challenge.png',
    'growth': 'assets/images/ui/lobby/icon_growth.png',
    'weapon': 'assets/images/ui/lobby/icon_weapon.png',
    'relic': 'assets/images/ui/lobby/icon_relic.png',
    'companion': 'assets/images/ui/lobby/icon_companion.png',
    'crafting': 'assets/images/ui/lobby/icon_crafting.png',
  };

  static const stagePresentation = <String, String>{
    'moonlit_abandoned_office_presentation':
        'assets/images/stages/moonlit_office_card.png',
    'plague_market_presentation': 'assets/images/stages/plague_market_card.png',
  };

  static const player = <String, String>{
    'rookie_constable_player': 'assets/images/player/exorcist_dosa_128.png',
    'exorcist_dosa_atlas': 'assets/images/player/exorcist_dosa_128.png',
  };
}
