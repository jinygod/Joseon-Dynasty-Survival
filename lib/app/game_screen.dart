import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'first_run_tutorial_overlay.dart';
import 'game_hud.dart';
import 'level_up_overlay.dart';
import 'pause_menu_overlay.dart';
import 'run_summary_screen.dart';
import '../game/models/player_slot.dart';
import '../game/models/run_result.dart';
import '../game/models/vector_input.dart';
import '../game/pixel_survivor_game.dart';
import '../game/systems/progression_system.dart';
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
    this.showFirstRunTutorial = false,
    this.tutorialProgressRepository,
    super.key,
  });

  final RunTelemetryService? telemetryService;
  final TelemetryRepository? telemetryRepository;
  final TelemetryExportService? telemetryExportService;
  final UtcClock? now;
  final PixelSurvivorGame? game;
  final bool showFirstRunTutorial;
  final TutorialProgressRepository? tutorialProgressRepository;

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
  late final DateTime _runStartedAtUtc;
  bool _handledRunEnd = false;

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
    _runStartedAtUtc = (widget.now ?? DateTime.now)().toUtc();
    _game =
        widget.game ??
        PixelSurvivorGame(
          playerSlot: const PlayerSlot(
            index: 0,
            characterId: 'rookie_constable',
          ),
          onRunEnded: _handleRunEnded,
        );
    _game.pauseWhenBackgrounded = false;
    if (widget.showFirstRunTutorial) {
      _game.pauseEngine();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _game.updateMovementInput(VectorInput.zero);
    super.dispose();
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
    if (!_game.canPauseRun ||
        _game.overlays.isActive(_pauseOverlayId) ||
        _game.overlays.isActive(_tutorialOverlayId)) {
      return;
    }
    _game.updateMovementInput(VectorInput.zero);
    _game.pauseEngine();
    _game.overlays.add(_pauseOverlayId);
  }

  void _resumeGame() {
    if (!_game.canPauseRun || _game.overlays.isActive(_tutorialOverlayId)) {
      return;
    }
    _game.overlays.remove(_pauseOverlayId);
    _game.resumeEngine();
  }

  void _restartGame() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const GameScreen()),
    );
  }

  void _exitToMenu() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _completeTutorial() async {
    try {
      await _tutorialProgressRepository.markCompleted();
    } on Object {
      // A storage failure must not trap the player behind onboarding.
    }
    if (!mounted || !_game.canPauseRun) return;
    _game.overlays.remove(_tutorialOverlayId);
    _game.resumeEngine();
  }

  void _handleRunEnded(RunResult result) {
    if (_handledRunEnd) {
      return;
    }

    _handledRunEnd = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final saveSystem = SaveSystem();
      const progressionSystem = ProgressionSystem();
      final before = await saveSystem.load();
      final after = progressionSystem.applyRunResult(before, result);
      await saveSystem.save(after);
      final unlocks = ProgressionUnlocks.diff(before, after);
      final telemetry = await _telemetryService.record(
        result,
        startedAtUtc: _runStartedAtUtc,
      );

      if (!mounted) {
        return;
      }

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => RunSummaryScreen(
            result: result,
            unlocks: unlocks,
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
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(builder: (_) => const GameScreen()),
              );
            },
            onMenu: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pauseGame();
      },
      child: GameWidget<PixelSurvivorGame>(
        game: _game,
        overlayBuilderMap: {
          'hud': (_, game) => GameHud(source: game, onPause: _pauseGame),
          PixelSurvivorGame.levelUpOverlayId: (_, game) => LevelUpOverlay(
            choices: game.pendingLevelUpChoices,
            onChoiceSelected: game.applyLevelUpChoice,
          ),
          _pauseOverlayId: (_, _) => PauseMenuOverlay(
            onResume: _resumeGame,
            onRestart: _restartGame,
            onExitToMenu: _exitToMenu,
          ),
          _tutorialOverlayId: (_, _) => FirstRunTutorialOverlay(
            onCompleted: () {
              _completeTutorial();
            },
          ),
        },
        initialActiveOverlays: [
          'hud',
          if (widget.showFirstRunTutorial) _tutorialOverlayId,
        ],
      ),
    );
  }
}
