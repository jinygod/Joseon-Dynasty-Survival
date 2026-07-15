import 'dart:async';

import 'package:flutter/material.dart';

import '../game/audio/audio_settings_controller.dart';
import '../game/audio/audio_settings_repository.dart';
import '../game/audio/flame_audio_backend.dart';
import '../game/audio/game_audio_service.dart';
import '../game/systems/save_system.dart';
import '../l10n/app_strings.dart';
import 'lobby_controller.dart';
import 'lobby_screen.dart';

class PixelSurvivorApp extends StatefulWidget {
  const PixelSurvivorApp({super.key});

  @override
  State<PixelSurvivorApp> createState() => _PixelSurvivorAppState();
}

class _PixelSurvivorAppState extends State<PixelSurvivorApp> {
  late final AudioSettingsController _audioSettingsController;
  late final GameAudioService _audioService;
  late final LobbyController _lobbyController;

  @override
  void initState() {
    super.initState();
    _audioSettingsController = AudioSettingsController(
      store: AudioSettingsRepository(),
    );
    unawaited(_audioSettingsController.load());
    _audioService = GameAudioService(
      backend: FlameAudioBackend(),
      readSettings: () => _audioSettingsController.settings,
    );
    _lobbyController = LobbyController(store: SaveSystem());
    unawaited(_lobbyController.load());
  }

  @override
  void dispose() {
    unawaited(_audioService.dispose());
    _lobbyController.dispose();
    _audioSettingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff3fbf7f)),
        splashFactory: NoSplash.splashFactory,
        useMaterial3: false,
      ),
      home: LobbyScreen(
        controller: _lobbyController,
        audioService: _audioService,
        audioSettingsController: _audioSettingsController,
      ),
    );
  }
}
