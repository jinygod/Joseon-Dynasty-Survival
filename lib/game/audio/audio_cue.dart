enum AudioChannel { music, sfx, ui }

enum AudioCue {
  menuMusic,
  battleMusic,
  bossMusic,
  victoryMusic,
  defeatMusic,
  hwandoAttack,
  hwandoMasterAttack,
  talismanMasterAttack,
  sealingSlash,
  bowAttack,
  talismanAttack,
  bombAttack,
  playerHit,
  criticalHit,
  enemyDeath,
  experiencePickup,
  levelUp,
  bossWarning,
  uiConfirm,
  uiBack,
}

abstract final class AudioCueCatalog {
  static AudioChannel channelFor(AudioCue cue) => switch (cue) {
    AudioCue.menuMusic ||
    AudioCue.battleMusic ||
    AudioCue.bossMusic ||
    AudioCue.victoryMusic ||
    AudioCue.defeatMusic => AudioChannel.music,
    AudioCue.uiConfirm || AudioCue.uiBack => AudioChannel.ui,
    _ => AudioChannel.sfx,
  };
}
