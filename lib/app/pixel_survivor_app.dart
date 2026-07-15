import 'dart:async';

import 'package:flutter/material.dart';

import '../game/audio/audio_settings_controller.dart';
import '../game/audio/audio_settings_repository.dart';
import '../game/audio/flame_audio_backend.dart';
import '../game/audio/game_audio_service.dart';
import '../l10n/app_strings.dart';
import 'main_menu_screen.dart';

class PixelSurvivorApp extends StatefulWidget {
  const PixelSurvivorApp({super.key});

  @override
  State<PixelSurvivorApp> createState() => _PixelSurvivorAppState();
}

class _PixelSurvivorAppState extends State<PixelSurvivorApp> {
  late final AudioSettingsController _audioSettingsController;
  late final GameAudioService _audioService;

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
  }

  @override
  void dispose() {
    unawaited(_audioService.dispose());
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
      home: MainMenuScreen(
        audioService: _audioService,
        audioSettingsController: _audioSettingsController,
      ),
    );
  }
}
