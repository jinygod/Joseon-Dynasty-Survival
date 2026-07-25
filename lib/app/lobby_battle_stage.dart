import 'package:flutter/material.dart';

import '../game/content/asset_catalog.dart';
import '../game/content/stage_definitions.dart';
import 'joseon_ui_theme.dart';
import 'lobby_asset_frame.dart';

/// Deployment information rendered over the lobby's shared full-scene art.
class LobbyBattleStage extends StatelessWidget {
  const LobbyBattleStage({
    required this.characterId,
    required this.characterName,
    required this.stage,
    required this.bestSeconds,
    required this.launching,
    required this.saving,
    required this.onDeploy,
    this.shortLandscape = false,
    super.key,
  });

  final String characterId;
  final String characterName;
  final StageDefinition stage;
  final int bestSeconds;
  final bool launching;
  final bool saving;
  final VoidCallback onDeploy;
  final bool shortLandscape;

  @override
  Widget build(BuildContext context) {
    final busy = launching || saving;
    return SizedBox(
      key: const Key('lobby-stage-hero'),
      height: shortLandscape ? 148 : 176,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = shortLandscape || constraints.maxWidth < 460;
          final plaque = _StagePlaque(
            characterName: characterName,
            stage: stage,
            bestSeconds: bestSeconds,
            compact: compact,
          );
          final deploy = _DeployCommand(
            launching: launching,
            busy: busy,
            compact: shortLandscape,
            onDeploy: onDeploy,
          );
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [plaque, deploy],
          );
        },
      ),
    );
  }
}

class _StagePlaque extends StatelessWidget {
  const _StagePlaque({
    required this.characterName,
    required this.stage,
    required this.bestSeconds,
    required this.compact,
  });

  final String characterName;
  final StageDefinition stage;
  final int bestSeconds;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('lobby-stage-plaque'),
      width: compact ? 276 : 330,
      height: compact ? 78 : 96,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            AssetCatalog.lobbyFrames['stage_plaque']!,
            fit: BoxFit.fill,
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 26,
              vertical: compact ? 6 : 12,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  characterName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: JoseonUiTheme.bodyFontFamily,
                    color: const Color(0xffffe6a7),
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  stage.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: JoseonUiTheme.displayFontFamily,
                    color: Colors.white,
                    fontSize: compact ? 18 : 22,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
                Text(
                  '최고 기록 ${_clock(bestSeconds)}',
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: JoseonUiTheme.bodyFontFamily,
                    color: const Color(0xffffe6a7),
                    fontSize: compact ? 11 : 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeployCommand extends StatelessWidget {
  const _DeployCommand({
    required this.launching,
    required this.busy,
    required this.compact,
    required this.onDeploy,
  });

  final bool launching;
  final bool busy;
  final bool compact;
  final VoidCallback onDeploy;

  @override
  Widget build(BuildContext context) {
    final label = launching
        ? '\uCD9C\uC9C4 \uC900\uBE44 \uC911'
        : '\uCD9C\uC9C4';
    return Opacity(
      opacity: busy ? .68 : 1,
      child: IgnorePointer(
        ignoring: busy,
        child: LobbyAssetButton(
          debugId: 'lobby-deploy',
          semanticLabel: label,
          frameAsset: AssetCatalog.lobbyFrames['deploy']!,
          minimumSize: compact ? const Size(168, 64) : const Size(180, 72),
          onPressed: onDeploy,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: JoseonUiTheme.bodyFontFamily,
              color: const Color(0xfffff1c4),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              shadows: const [Shadow(color: Color(0xff201108), blurRadius: 3)],
            ),
          ),
        ),
      ),
    );
  }
}

String _clock(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
