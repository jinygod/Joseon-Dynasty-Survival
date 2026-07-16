import '../../app/game_settings_repository.dart';

export '../../app/game_settings_repository.dart'
    show GameSettingsRepository, GameSettingsStore;

typedef AudioSettingsStore = GameSettingsStore;

class AudioSettingsRepository extends GameSettingsRepository {
  AudioSettingsRepository({super.preferences});

  static const musicVolumeKey = GameSettingsRepository.legacyMusicVolumeKey;
  static const sfxVolumeKey = GameSettingsRepository.legacySfxVolumeKey;
  static const vibrationEnabledKey =
      GameSettingsRepository.legacyVibrationEnabledKey;
}
