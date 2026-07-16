import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/account/account_controller.dart';
import '../backend/account/account_service.dart';
import '../backend/account/account_session.dart';
import '../backend/account/supabase_account_service.dart';
import '../backend/backend_config.dart';
import '../backend/economy/google_play_purchase_gateway.dart';
import '../backend/economy/purchase_controller.dart';
import '../backend/economy/purchase_retry_store.dart';
import '../backend/economy/supabase_economy_repository.dart';
import '../backend/progress/progress_sync_controller.dart';
import '../backend/progress/cloud_progress_repository.dart';
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
    this.purchaseController,
    this.saveStore,
    this.cloudProgressRepository,
    super.key,
  });

  final BackendConfig backendConfig;
  final AccountService? accountService;
  final Future<void> Function()? clearPaidCache;
  final PurchaseController? purchaseController;
  final SaveStore? saveStore;
  final CloudProgressRepository? cloudProgressRepository;

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
  PurchaseController? _purchaseController;
  GooglePlayPurchaseGateway? _purchaseGateway;
  late final SaveStore _saveStore;
  bool _disposed = false;
  bool _purchaseInitializing = false;
  bool _purchaseInitializationFailed = false;

  static const _androidPackageName = String.fromEnvironment(
    'ANDROID_PACKAGE_NAME',
    defaultValue: 'com.pixel.survivor.pixel_survivor',
  );

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
    _saveStore = widget.saveStore ?? SaveSystem();
    _lobbyController = LobbyController(store: _saveStore);
    unawaited(_lobbyController.load());
    if (widget.backendConfig.enabled) {
      _initializeBackend();
    }
  }

  void _initializeBackend() {
    _accountController = AccountController(
      config: widget.backendConfig,
      service: widget.accountService ?? SupabaseAccountService(),
      clearLocalState: () async {
        await _progressSyncController?.invalidateSession();
        await _lobbyController.clearAccountLocalState();
      },
      clearPaidCache: () async {
        await _purchaseController?.onAccountChanged(
          const AccountSession.signedOut(),
        );
        await widget.clearPaidCache?.call();
      },
      onAuthStateObserved: (session) {
        final sync = _progressSyncController;
        if (sync != null) unawaited(sync.invalidateSession());
        final purchase = _purchaseController;
        if (purchase != null) unawaited(purchase.onAccountChanged(session));
      },
    );
    _progressSyncController = ProgressSyncController(
      readAccount: () => _accountController!.syncSession,
      store: _saveStore,
      repository:
          widget.cloudProgressRepository ?? SupabaseCloudProgressRepository(),
    );
    _lobbyController.progressSyncController = _progressSyncController;
    _accountController!.onPermanentAccount = () async {
      await _lobbyController.syncNow();
      await _purchaseController?.onAccountChanged(
        _accountController!.syncSession,
      );
    };
    unawaited(_accountController!.initialize());
    unawaited(_initializePurchasesSafely());
  }

  Future<void> _initializePurchasesSafely() async {
    if (_disposed || _purchaseInitializing || _purchaseController != null) {
      return;
    }
    _purchaseInitializing = true;
    try {
      await _initializePurchases();
      _purchaseInitializationFailed = false;
    } on Object catch (error) {
      debugPrint('Premium purchase initialization unavailable: $error');
      _purchaseInitializationFailed = true;
      if (widget.purchaseController == null) {
        _purchaseController?.dispose();
      }
      _purchaseController = null;
      await _purchaseGateway?.dispose();
      _purchaseGateway = null;
    } finally {
      _purchaseInitializing = false;
      if (!_disposed && mounted) setState(() {});
    }
  }

  Future<void> _initializePurchases() async {
    final injected = widget.purchaseController;
    if (injected != null) {
      _purchaseController = injected;
    } else {
      final preferences = await SharedPreferences.getInstance();
      if (_disposed) return;
      _purchaseGateway = GooglePlayPurchaseGateway();
      _purchaseController = PurchaseController(
        gateway: _purchaseGateway!,
        repository: SupabaseEconomyRepository(Supabase.instance.client),
        retryStore: SharedPreferencesPurchaseRetryStore(preferences),
        sessionProvider: () =>
            _accountController?.syncSession ?? const AccountSession.signedOut(),
        packageName: _androidPackageName,
      );
    }
    if (_disposed) return;
    await _purchaseController!.start();
  }

  @override
  void dispose() {
    _disposed = true;
    _audioSettingsAudioBinding.dispose();
    unawaited(_audioService.dispose());
    _accountController?.dispose();
    _progressSyncController?.dispose();
    if (widget.purchaseController == null) {
      _purchaseController?.dispose();
      unawaited(_purchaseGateway?.dispose());
    }
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
        purchaseController: _purchaseController,
        onPurchaseInitializationRetry: _purchaseInitializationFailed
            ? () => unawaited(_initializePurchasesSafely())
            : null,
      ),
    );
  }
}
