import 'dart:async';

import 'package:flutter/material.dart';

import '../backend/account/account_controller.dart';
import '../backend/account/account_service.dart';
import '../backend/account/supabase_account_service.dart';
import '../backend/backend_config.dart';
import '../backend/progress/progress_sync_controller.dart';
import '../backend/progress/supabase_cloud_progress_repository.dart';
import '../game/audio/audio_settings_controller.dart';
import '../game/audio/audio_settings_repository.dart';
import '../game/audio/flame_audio_backend.dart';
import '../game/audio/game_audio_service.dart';
import '../game/systems/save_system.dart';
import '../l10n/app_strings.dart';
import 'audio_settings_audio_binding.dart';
import 'lobby_controller.dart';
import 'lobby_screen.dart';

class PixelSurvivorApp extends StatefulWidget {
  const PixelSurvivorApp({
    this.backendConfig = const BackendConfig.disabled(),
    this.accountService,
    this.clearPaidCache,
    super.key,
  });

  final BackendConfig backendConfig;
  final AccountService? accountService;
  final Future<void> Function()? clearPaidCache;

  @override
  State<PixelSurvivorApp> createState() => _PixelSurvivorAppState();
}

class _PixelSurvivorAppState extends State<PixelSurvivorApp> {
  late final AudioSettingsController _audioSettingsController;
  late final GameAudioService _audioService;
  late final AudioSettingsAudioBinding _audioSettingsAudioBinding;
  late final LobbyController _lobbyController;
  AccountController? _accountController;
  ProgressSyncController? _progressSyncController;
  late final SaveStore _saveStore;

  @override
  void initState() {
    super.initState();
    _audioSettingsController = AudioSettingsController(
      store: AudioSettingsRepository(),
    );
    _audioService = GameAudioService(
      backend: FlameAudioBackend(),
      readSettings: () => _audioSettingsController.settings,
    );
    _audioSettingsAudioBinding = AudioSettingsAudioBinding(
      controller: _audioSettingsController,
      service: _audioService,
    );
    unawaited(_audioSettingsController.load());
    _saveStore = SaveSystem();
    _lobbyController = LobbyController(store: _saveStore);
    unawaited(_lobbyController.load());
    if (widget.backendConfig.enabled) {
      _accountController = AccountController(
        config: widget.backendConfig,
        service: widget.accountService ?? SupabaseAccountService(),
        clearLocalState: () async {
          await _progressSyncController?.invalidateSession();
          await _lobbyController.clearAccountLocalState();
        },
        clearPaidCache: widget.clearPaidCache,
      );
      _progressSyncController = ProgressSyncController(
        readAccount: () => _accountController!.syncSession,
        store: _saveStore,
        repository: SupabaseCloudProgressRepository(),
      );
      _lobbyController.progressSyncController = _progressSyncController;
      _accountController!.onPermanentAccount = _lobbyController.syncNow;
      unawaited(_accountController!.initialize());
    }
  }

  @override
  void dispose() {
    _audioSettingsAudioBinding.dispose();
    unawaited(_audioService.dispose());
    _accountController?.dispose();
    _progressSyncController?.dispose();
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
        accountController: _accountController,
        progressSyncController: _progressSyncController,
      ),
    );
  }
}
