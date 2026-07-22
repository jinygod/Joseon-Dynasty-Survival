import 'audio_cue.dart';

class AudioAssetDefinition {
  const AudioAssetDefinition({required this.path, this.loop = false});

  final String path;
  final bool loop;
}

abstract final class AudioAssetCatalog {
  static const assets = <AudioCue, AudioAssetDefinition>{
    AudioCue.menuMusic: AudioAssetDefinition(
      path: 'audio/music/menu.ogg',
      loop: true,
    ),
    AudioCue.battleMusic: AudioAssetDefinition(
      path: 'audio/music/battle.ogg',
      loop: true,
    ),
    AudioCue.bossMusic: AudioAssetDefinition(
      path: 'audio/music/boss.ogg',
      loop: true,
    ),
    AudioCue.victoryMusic: AudioAssetDefinition(
      path: 'audio/music/victory.ogg',
    ),
    AudioCue.defeatMusic: AudioAssetDefinition(path: 'audio/music/defeat.ogg'),
    AudioCue.hwandoAttack: AudioAssetDefinition(path: 'audio/sfx/hwando.ogg'),
    AudioCue.hwandoMasterAttack: AudioAssetDefinition(
      path: 'audio/sfx/critical.ogg',
    ),
    AudioCue.talismanMasterAttack: AudioAssetDefinition(
      path: 'audio/sfx/talisman.ogg',
    ),
    AudioCue.gakgungMasterAttack: AudioAssetDefinition(
      path: 'audio/sfx/critical.ogg',
    ),
    AudioCue.sealingSlash: AudioAssetDefinition(path: 'audio/sfx/hwando.ogg'),
    AudioCue.bowAttack: AudioAssetDefinition(path: 'audio/sfx/bow.ogg'),
    AudioCue.talismanAttack: AudioAssetDefinition(
      path: 'audio/sfx/talisman.ogg',
    ),
    AudioCue.bombAttack: AudioAssetDefinition(path: 'audio/sfx/bomb.ogg'),
    AudioCue.playerHit: AudioAssetDefinition(path: 'audio/sfx/player_hit.ogg'),
    AudioCue.criticalHit: AudioAssetDefinition(path: 'audio/sfx/critical.ogg'),
    AudioCue.enemyDeath: AudioAssetDefinition(
      path: 'audio/sfx/enemy_death.ogg',
    ),
    AudioCue.experiencePickup: AudioAssetDefinition(
      path: 'audio/sfx/experience.ogg',
    ),
    AudioCue.levelUp: AudioAssetDefinition(path: 'audio/sfx/level_up.ogg'),
    AudioCue.bossWarning: AudioAssetDefinition(
      path: 'audio/sfx/boss_warning.ogg',
    ),
    AudioCue.uiConfirm: AudioAssetDefinition(path: 'audio/ui/confirm.ogg'),
    AudioCue.uiBack: AudioAssetDefinition(path: 'audio/ui/back.ogg'),
  };

  static AudioAssetDefinition forCue(AudioCue cue) => assets[cue]!;
}
