import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game_hud.dart';
import 'level_up_overlay.dart';
import 'run_summary_screen.dart';
import '../game/models/player_slot.dart';
import '../game/models/run_result.dart';
import '../game/pixel_survivor_game.dart';
import '../game/systems/progression_system.dart';
import '../game/systems/run_telemetry_service.dart';
import '../game/systems/save_system.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({this.telemetryService, this.now, super.key});

  final RunTelemetryService? telemetryService;
  final UtcClock? now;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final PixelSurvivorGame _game;
  late final RunTelemetryService _telemetryService;
  late final DateTime _runStartedAtUtc;
  bool _handledRunEnd = false;

  @override
  void initState() {
    super.initState();
    _telemetryService = widget.telemetryService ?? RunTelemetryService();
    _runStartedAtUtc = (widget.now ?? DateTime.now)().toUtc();
    _game = PixelSurvivorGame(
      playerSlot: const PlayerSlot(index: 0, characterId: 'rookie_constable'),
      onRunEnded: _handleRunEnded,
    );
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
      await _telemetryService.record(result, startedAtUtc: _runStartedAtUtc);

      if (!mounted) {
        return;
      }

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => RunSummaryScreen(
            result: result,
            unlocks: unlocks,
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
    return GameWidget<PixelSurvivorGame>(
      game: _game,
      overlayBuilderMap: {
        'hud': (_, game) => GameHud(source: game),
        PixelSurvivorGame.levelUpOverlayId: (_, game) => LevelUpOverlay(
          choices: game.pendingLevelUpChoices,
          onChoiceSelected: game.applyLevelUpChoice,
        ),
      },
      initialActiveOverlays: const ['hud'],
    );
  }
}
