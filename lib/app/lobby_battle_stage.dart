import 'package:flutter/material.dart';

import '../game/content/asset_catalog.dart';
import '../game/content/character_definitions.dart';
import '../game/content/stage_definitions.dart';
import 'joseon_game_button.dart';
import 'joseon_ui_theme.dart';

/// The Joseon command-hall stage used to preview and launch a run.
class LobbyBattleStage extends StatelessWidget {
  const LobbyBattleStage({
    required this.characterId,
    required this.characterName,
    required this.stage,
    required this.bestSeconds,
    required this.launching,
    required this.saving,
    required this.onDeploy,
    super.key,
  });

  final String characterId;
  final String characterName;
  final StageDefinition stage;
  final int bestSeconds;
  final bool launching;
  final bool saving;
  final VoidCallback onDeploy;

  @override
  Widget build(BuildContext context) {
    final busy = launching || saving;
    return SizedBox(
      key: const Key('lobby-stage-hero'),
      height: 522,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff193d3a), Color(0xff102927)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: JoseonUiTheme.gold, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x88000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                AssetCatalog.lobby['government_office']!,
                key: const Key('lobby-stage-background-image'),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                filterQuality: FilterQuality.high,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, 0.45, 0.72, 1],
                    colors: [
                      Color(0x26000000),
                      Color(0x12000000),
                      Color(0x52040a12),
                      Color(0xa6040a12),
                    ],
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxHeight < 420) {
                    return _WideStageContent(
                      characterId: characterId,
                      characterName: characterName,
                      stage: stage,
                      bestSeconds: bestSeconds,
                      launching: launching,
                      busy: busy,
                      onDeploy: onDeploy,
                    );
                  }
                  return _TallStageContent(
                    characterId: characterId,
                    characterName: characterName,
                    stage: stage,
                    bestSeconds: bestSeconds,
                    launching: launching,
                    busy: busy,
                    onDeploy: onDeploy,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TallStageContent extends StatelessWidget {
  const _TallStageContent({
    required this.characterId,
    required this.characterName,
    required this.stage,
    required this.bestSeconds,
    required this.launching,
    required this.busy,
    required this.onDeploy,
  });

  final String characterId;
  final String characterName;
  final StageDefinition stage;
  final int bestSeconds;
  final bool launching;
  final bool busy;
  final VoidCallback onDeploy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        children: [
          _StageHeading(stage: stage, bestSeconds: bestSeconds),
          const Spacer(),
          _CharacterPresentation(
            characterId: characterId,
            characterName: characterName,
          ),
          const Spacer(),
          _DeployCommand(launching: launching, busy: busy, onDeploy: onDeploy),
        ],
      ),
    );
  }
}

class _WideStageContent extends StatelessWidget {
  const _WideStageContent({
    required this.characterId,
    required this.characterName,
    required this.stage,
    required this.bestSeconds,
    required this.launching,
    required this.busy,
    required this.onDeploy,
  });

  final String characterId;
  final String characterName;
  final StageDefinition stage;
  final int bestSeconds;
  final bool launching;
  final bool busy;
  final VoidCallback onDeploy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _StageHeading(
              stage: stage,
              bestSeconds: bestSeconds,
              compact: true,
            ),
          ),
          const SizedBox(width: 12),
          _CharacterPresentation(
            characterId: characterId,
            characterName: characterName,
            compact: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Center(
              child: _DeployCommand(
                launching: launching,
                busy: busy,
                onDeploy: onDeploy,
                width: 180,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageHeading extends StatelessWidget {
  const _StageHeading({
    required this.stage,
    required this.bestSeconds,
    this.compact = false,
  });

  final StageDefinition stage;
  final int bestSeconds;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 18,
            vertical: compact ? 3 : 5,
          ),
          decoration: BoxDecoration(
            color: const Color(0xee8f2d38),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: JoseonUiTheme.gold, width: 1.5),
          ),
          child: Text(
            '오늘의 출진',
            maxLines: 1,
            style: TextStyle(
              fontFamily: JoseonUiTheme.displayFontFamily,
              color: Colors.white,
              fontSize: compact ? 15 : 17,
              letterSpacing: .6,
            ),
          ),
        ),
        SizedBox(height: compact ? 4 : 7),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            stage.name,
            maxLines: 1,
            style: TextStyle(
              fontFamily: JoseonUiTheme.displayFontFamily,
              color: Colors.white,
              fontSize: compact ? 25 : 29,
              letterSpacing: .8,
              shadows: const [
                Shadow(
                  color: Colors.black,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
        Text(
          '최고 기록 ${_clock(bestSeconds)}',
          maxLines: 1,
          style: TextStyle(
            fontFamily: JoseonUiTheme.bodyFontFamily,
            color: const Color(0xffffe6a7),
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _CharacterPresentation extends StatelessWidget {
  const _CharacterPresentation({
    required this.characterId,
    required this.characterName,
    this.compact = false,
  });

  final String characterId;
  final String characterName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LobbyCharacterArt(
          characterId: characterId,
          dimension: compact ? 132 : 154,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            characterName,
            maxLines: 1,
            style: TextStyle(
              fontFamily: JoseonUiTheme.displayFontFamily,
              color: Colors.white,
              fontSize: compact ? 18 : 20,
              letterSpacing: .5,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeployCommand extends StatelessWidget {
  const _DeployCommand({
    required this.launching,
    required this.busy,
    required this.onDeploy,
    this.width = 230,
  });

  final bool launching;
  final bool busy;
  final VoidCallback onDeploy;
  final double width;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: busy,
      child: Opacity(
        opacity: busy ? .68 : 1,
        child: JoseonGameButton(
          key: const Key('lobby-deploy'),
          debugId: 'lobby-deploy',
          semanticLabel: launching ? '출진 준비 중' : '출진',
          minimumSize: Size(width, 76),
          faceGradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xffffdb57), Color(0xffd89a1e)],
          ),
          depthColor: const Color(0xff6d351f),
          borderColor: JoseonUiTheme.ink,
          onPressed: onDeploy,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: JoseonUiTheme.ink,
                  size: 25,
                ),
                const SizedBox(width: 8),
                Text(
                  launching ? '출진 준비 중' : '출진',
                  style: const TextStyle(
                    fontFamily: JoseonUiTheme.bodyFontFamily,
                    color: JoseonUiTheme.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LobbyCharacterArt extends StatelessWidget {
  const _LobbyCharacterArt({
    required this.characterId,
    required this.dimension,
  });

  final String characterId;
  final double dimension;

  @override
  Widget build(BuildContext context) {
    final path =
        AssetCatalog.characters[characterId] ??
        AssetCatalog.characters[rookieConstable]!;
    final usesAtlas = path.endsWith('_128.png');
    return SizedBox.square(
      key: const Key('lobby-character-art'),
      dimension: dimension,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0x3348d7a1),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0xaa000000),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: usesAtlas
            ? ClipOval(
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: dimension * 4,
                  maxWidth: dimension * 4,
                  minHeight: dimension * 4,
                  maxHeight: dimension * 4,
                  child: Image.asset(
                    path,
                    width: dimension * 4,
                    height: dimension * 4,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset(
                  path,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
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
