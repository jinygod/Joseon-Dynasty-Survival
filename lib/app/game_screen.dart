import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'first_run_tutorial_overlay.dart';
import 'game_hud.dart';
import 'level_up_overlay.dart';
import 'pause_menu_overlay.dart';
import 'run_summary_screen.dart';
import 'world_debug_overlay.dart';
import '../game/models/player_slot.dart';
import '../game/audio/audio_settings_controller.dart';
import '../game/audio/audio_settings_repository.dart';
import '../game/audio/audio_cue.dart';
import '../game/audio/game_audio_service.dart';
import '../game/models/run_result.dart';
import '../game/models/run_telemetry.dart';
import '../game/models/vector_input.dart';
import '../game/components/spirit_jade_component.dart';
import '../game/content/stage_definitions.dart';
import '../game/content/playtest_content_policy.dart';
import '../game/pixel_survivor_game.dart';
import '../game/systems/progression_system.dart';
import '../game/systems/meta_progression_service.dart';
import '../game/systems/playtest_session_repository.dart';
import '../game/systems/run_telemetry_service.dart';
import '../game/systems/save_system.dart';
import '../game/systems/telemetry_export_service.dart';
import '../game/systems/telemetry_repository.dart';
import '../game/systems/tutorial_progress_repository.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    this.telemetryService,
    this.telemetryRepository,
    this.telemetryExportService,
    this.now,
    this.game,
    this.playerSlot = const PlayerSlot(
      index: 0,
      characterId: 'rookie_constable',
    ),
    this.stageId = moonlitAbandonedOffice,
    this.showFirstRunTutorial = false,
    this.tutorialProgressRepository,
    this.audioSettingsController,
    this.audioService,
    this.metaProgressionService,
    this.playtestSessionRepository,
    this.syncProgress,
    this.loadVisualAssets = true,
    super.key,
  });

  final RunTelemetryService? telemetryService;
  final TelemetryRepository? telemetryRepository;
  final TelemetryExportService? telemetryExportService;
  final UtcClock? now;
  final PixelSurvivorGame? game;
  final PlayerSlot playerSlot;
  final String stageId;
  final bool showFirstRunTutorial;
  final TutorialProgressRepository? tutorialProgressRepository;
  final AudioSettingsController? audioSettingsController;
  final GameAudioService? audioService;
  final MetaProgressionService? metaProgressionService;
  final PlaytestSessionRepository? playtestSessionRepository;
  final Future<void> Function()? syncProgress;
  final bool loadVisualAssets;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  static const _pauseOverlayId = 'pauseMenu';
  static const _tutorialOverlayId = 'firstRunTutorial';

  late final PixelSurvivorGame _game;
  late final RunTelemetryService _telemetryService;
  late final TelemetryRepository _telemetryRepository;
  late final TelemetryExportService _telemetryExportService;
  late final TutorialProgressRepository _tutorialProgressRepository;
  late final AudioSettingsController _audioSettingsController;
  late final MetaProgressionService _metaProgressionService;
  late final PlaytestSessionRepository _playtestSessionRepository;
  late final bool _ownsAudioSettingsController;
  late final DateTime _runStartedAtUtc;
  bool _handledRunEnd = false;
  RunResult? _settlementFailure;
  bool _settlingRewards = false;
  RunSettlement? _completedSettlement;
  RunTelemetry? _recordedTelemetry;
  bool _gameReady = false;
  bool _disposed = false;
  bool _replacementStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _telemetryService = widget.telemetryService ?? RunTelemetryService();
    _telemetryRepository = widget.telemetryRepository ?? TelemetryRepository();
    _telemetryExportService =
        widget.telemetryExportService ?? TelemetryExportService();
    _tutorialProgressRepository =
        widget.tutorialProgressRepository ?? TutorialProgressRepository();
    _metaProgressionService =
        widget.metaProgressionService ??
        MetaProgressionService(saveStore: SaveSystem());
    _playtestSessionRepository =
        widget.playtestSessionRepository ?? PlaytestSessionRepository();
    _ownsAudioSettingsController = widget.audioSettingsController == null;
    _audioSettingsController =
        widget.audioSettingsController ??
        AudioSettingsController(store: AudioSettingsRepository());
    unawaited(_audioSettingsController.load());
    _runStartedAtUtc = (widget.now ?? DateTime.now)().toUtc();
    final injectedGame = widget.game;
    if (injectedGame != null) {
      _game = injectedGame;
      _finishGameInitialization();
    } else {
      unawaited(_initializeGame());
    }
  }

  Future<void> _initializeGame() async {
    var ordinal = 1;
    PlaytestRunReservation? reservation;
    try {
      reservation = await _playtestSessionRepository.reserveRun();
      ordinal = reservation.ordinal;
    } on Object {
      // Playtest counting must never prevent a run from starting.
    }
    if (_disposed) {
      await reservation?.cancel();
      return;
    }
    _game = PixelSurvivorGame(
      playerSlot: widget.playerSlot,
      stageId: widget.stageId,
      onRunEnded: _handleRunEnded,
      onAudioCue: _playAudio,
      persistSpiritJade: _persistSpiritJade,
      pickupIdPrefix: _runStartedAtUtc.microsecondsSinceEpoch.toString(),
      contentPolicy: const PlaytestContentPolicy(
        unlockAllBaseWeapons: bool.fromEnvironment(
          'PLAYTEST_UNLOCK_ALL_BASE_WEAPONS',
          defaultValue: kDebugMode,
        ),
      ),
      isRepeatRun: ordinal > 1,
      loadVisualAssets: widget.loadVisualAssets,
    );
    reservation?.confirm();
    _finishGameInitialization();
    if (mounted) setState(() {});
  }

  void _finishGameInitialization() {
    _gameReady = true;
    _audioSettingsController.addListener(_applyAccessibilitySettings);
    _applyAccessibilitySettings();
    unawaited(_loadFirstBossRewardAvailability());
    _game.pauseWhenBackgrounded = false;
    if (widget.showFirstRunTutorial) {
      _game.pauseEngine();
    }
    _playAudio(AudioCue.battleMusic);
  }

  @override
  void dispose() {
    _disposed = true;
    final gameWasReady = _gameReady;
    _gameReady = false;
    WidgetsBinding.instance.removeObserver(this);
    _audioSettingsController.removeListener(_applyAccessibilitySettings);
    if (gameWasReady) _game.updateMovementInput(VectorInput.zero);
    final audio = widget.audioService;
    if (audio != null) unawaited(audio.stopNonMusic());
    if (_ownsAudioSettingsController) _audioSettingsController.dispose();
    super.dispose();
  }

  void _applyAccessibilitySettings() {
    if (!_gameReady) return;
    final settings = _audioSettingsController.settings;
    _game.applyAccessibilitySettings(
      screenShakeEnabled: settings.screenShakeEnabled,
      damageNumbersEnabled: settings.damageNumbersEnabled,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _pauseGame();
      case AppLifecycleState.resumed:
        break;
    }
  }

  void _pauseGame() {
    if (!_gameReady) return;
    if (!_game.canPauseRun ||
        _game.overlays.isActive(_pauseOverlayId) ||
        _game.overlays.isActive(_tutorialOverlayId)) {
      return;
    }
    _game.updateMovementInput(VectorInput.zero);
    _game.pauseEngine();
    _game.overlays.add(_pauseOverlayId);
    final audio = widget.audioService;
    if (audio != null) unawaited(audio.pauseAll());
  }

  void _resumeGame() {
    if (!_gameReady) return;
    if (!_game.canPauseRun || _game.overlays.isActive(_tutorialOverlayId)) {
      return;
    }
    _game.overlays.remove(_pauseOverlayId);
    _game.resumeEngine();
    final audio = widget.audioService;
    if (audio != null) unawaited(audio.resumeAll());
  }

  void _restartGame() {
    if (_replacementStarted || _disposed) return;
    _replacementStarted = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(
          playerSlot: widget.playerSlot,
          stageId: widget.stageId,
          audioService: widget.audioService,
          audioSettingsController: widget.audioSettingsController,
          metaProgressionService: _metaProgressionService,
          playtestSessionRepository: _playtestSessionRepository,
          syncProgress: widget.syncProgress,
          loadVisualAssets: widget.loadVisualAssets,
        ),
      ),
    );
  }

  void _exitToMenu() {
    _playAudio(AudioCue.uiBack);
    _playAudio(AudioCue.menuMusic);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _completeTutorial() async {
    try {
      await _tutorialProgressRepository.markCompleted();
    } on Object {
      // A storage failure must not trap the player behind onboarding.
    }
    if (!mounted || !_gameReady || !_game.canPauseRun) return;
    _game.overlays.remove(_tutorialOverlayId);
    _game.resumeEngine();
    final audio = widget.audioService;
    if (audio != null) unawaited(audio.resumeAll());
  }

  void _handleRunEnded(RunResult result) {
    if (_handledRunEnd) {
      return;
    }

    _handledRunEnd = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_settleAndNavigate(result));
    });
  }

  Future<void> _loadFirstBossRewardAvailability() async {
    try {
      final available = await _metaProgressionService
          .loadFirstBossRewardAvailability();
      if (mounted && !_disposed && _gameReady) {
        _game.firstBossRewardAvailable = available;
      }
    } on Object {
      if (mounted && !_disposed && _gameReady) {
        _game.firstBossRewardAvailable = false;
      }
    }
  }

  Future<bool> _persistSpiritJade(SpiritJadePickup pickup) async {
    await _metaProgressionService.collectSpiritJade(
      pickupId: pickup.pickupId,
      claimsFirstBossReward: pickup.claimsFirstBossReward,
    );
    return true;
  }

  Future<void> _settleAndNavigate(RunResult result) async {
    if (_settlingRewards) return;
    setState(() {
      _settlingRewards = true;
      _settlementFailure = null;
    });
    try {
      final settlement =
          _completedSettlement ??
          await _metaProgressionService.settleRun(
            result,
            characterId: widget.playerSlot.characterId,
          );
      _completedSettlement = settlement;
      final syncProgress = widget.syncProgress;
      if (syncProgress != null) unawaited(syncProgress());
      final unlocks = ProgressionUnlocks.diff(
        settlement.before,
        settlement.after,
      );
      final telemetry = _recordedTelemetry ?? await _recordTelemetry(result);
      _recordedTelemetry = telemetry;

      if (!mounted) {
        return;
      }

      final navigator = Navigator.of(context);
      final playerSlot = widget.playerSlot;
      final stageId = widget.stageId;
      final audioService = widget.audioService;
      final audioSettingsController = widget.audioSettingsController;
      final metaProgressionService = _metaProgressionService;
      await navigator.pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => RunSummaryScreen(
            result: result,
            unlocks: unlocks,
            settlement: settlement,
            onFeedbackSubmitted: telemetry == null
                ? null
                : (feedback) async {
                    final updated = await _telemetryRepository.updateFeedback(
                      telemetry.runId,
                      feedback,
                    );
                    if (!updated) {
                      throw StateError('Recorded run was not found');
                    }
                  },
            onCopyRunJson: telemetry == null
                ? null
                : () => _telemetryExportService.copyRun(telemetry.runId),
            onExportAllJson: telemetry == null
                ? null
                : _telemetryExportService.exportAll,
            onStart: () {
              if (_replacementStarted) return;
              _replacementStarted = true;
              navigator.pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => GameScreen(
                    playerSlot: playerSlot,
                    stageId: stageId,
                    audioService: audioService,
                    audioSettingsController: audioSettingsController,
                    metaProgressionService: metaProgressionService,
                    playtestSessionRepository: _playtestSessionRepository,
                    syncProgress: syncProgress,
                    loadVisualAssets: widget.loadVisualAssets,
                  ),
                ),
              );
            },
            onMenu: () {
              if (audioService != null) {
                unawaited(audioService.play(AudioCue.uiBack));
                unawaited(audioService.play(AudioCue.menuMusic));
              }
              navigator.popUntil((route) => route.isFirst);
            },
          ),
        ),
      );
    } on Object {
      if (!mounted) return;
      setState(() {
        _settlingRewards = false;
        _settlementFailure = result;
      });
    }
  }

  Future<RunTelemetry?> _recordTelemetry(RunResult result) async {
    try {
      return await _telemetryService.record(
        result,
        startedAtUtc: _runStartedAtUtc,
      );
    } on Object {
      return null;
    }
  }

  void _playAudio(AudioCue cue) {
    final audio = widget.audioService;
    if (audio != null) unawaited(audio.play(cue));
  }

  @override
  Widget build(BuildContext context) {
    if (!_gameReady) {
      return const ColoredBox(
        color: Color(0xff101820),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pauseGame();
      },
      child: Stack(
        children: [
          GameWidget<PixelSurvivorGame>(
            game: _game,
            overlayBuilderMap: {
              'hud': (_, game) => ListenableBuilder(
                listenable: _audioSettingsController,
                builder: (_, _) => GameHud(
                  source: game,
                  onPause: _pauseGame,
                  uiScale: _audioSettingsController.settings.uiScale.factor,
                ),
              ),
              PixelSurvivorGame.levelUpOverlayId: (_, game) => LevelUpOverlay(
                choices: game.pendingLevelUpChoices,
                onChoiceSelected: game.applyLevelUpChoice,
              ),
              _pauseOverlayId: (_, _) => PauseMenuOverlay(
                settingsController: _audioSettingsController,
                onResume: _resumeGame,
                onRestart: _restartGame,
                onExitToMenu: _exitToMenu,
              ),
              _tutorialOverlayId: (_, _) => FirstRunTutorialOverlay(
                onCompleted: () {
                  _completeTutorial();
                },
              ),
              if (kDebugMode)
                'worldDebug': (_, game) => WorldDebugOverlay(source: game),
            },
            initialActiveOverlays: [
              'hud',
              if (kDebugMode) 'worldDebug',
              if (widget.showFirstRunTutorial) _tutorialOverlayId,
            ],
          ),
          if (_settlementFailure != null || _settlingRewards)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _settlementFailure == null
                                ? '보상 저장 중'
                                : '보상 저장에 실패했습니다',
                          ),
                          if (_settlementFailure case final failed?) ...[
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => _settleAndNavigate(failed),
                              child: const Text('다시 시도'),
                            ),
                          ] else ...[
                            const SizedBox(height: 12),
                            const CircularProgressIndicator(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
