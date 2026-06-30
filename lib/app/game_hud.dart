import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/models/vector_input.dart';
import '../game/pixel_survivor_game.dart';

class GameHud extends StatefulWidget {
  const GameHud({required this.game, super.key});

  final PixelSurvivorGame game;

  @override
  State<GameHud> createState() => _GameHudState();
}

class _GameHudState extends State<GameHud> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: _StatusBar(game: widget.game),
            ),
            Positioned(
              left: 18,
              bottom: 18,
              child: _DeveloperMovePad(
                onInputChanged: widget.game.updateMovementInput,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.game});

  final PixelSurvivorGame game;

  @override
  Widget build(BuildContext context) {
    final elapsed = Duration(seconds: game.elapsedSeconds.floor());
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Align(
      alignment: Alignment.topRight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xff101820).withValues(alpha: 0.78),
          border: Border.all(color: const Color(0xfff4ead2), width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 16,
            runSpacing: 6,
            children: [
              _HudValue(label: 'Time', value: '$minutes:$seconds'),
              _HudValue(label: 'HP', value: game.playerHealthLabel),
              _HudValue(label: 'Level', value: '${game.playerLevel}'),
              _HudValue(
                label: 'XP',
                value: '${game.currentExperience}/${game.experienceToNextLevel}',
              ),
              _HudValue(label: 'Enemies', value: '${game.enemyCount}'),
              _HudValue(label: 'Kills', value: '${game.kills}'),
              _HudValue(label: 'Weapon', value: game.currentWeaponLabel),
            ],
          ),
        ),
      ),
    );
  }
}

class _HudValue extends StatelessWidget {
  const _HudValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: '$label ',
        style: const TextStyle(
          color: Color(0xff9fb3c8),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Color(0xfff4ead2),
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _DeveloperMovePad extends StatefulWidget {
  const _DeveloperMovePad({required this.onInputChanged});

  final ValueChanged<VectorInput> onInputChanged;

  @override
  State<_DeveloperMovePad> createState() => _DeveloperMovePadState();
}

class _DeveloperMovePadState extends State<_DeveloperMovePad> {
  static const double _padSize = 112;
  static const double _deadZone = 8;

  Offset _thumbOffset = Offset.zero;

  void _updateInput(Offset localPosition) {
    const center = Offset(_padSize / 2, _padSize / 2);
    final delta = localPosition - center;
    const radius = _padSize / 2;
    final distance = math.min(delta.distance, radius);
    final normalized = delta.distance == 0
        ? Offset.zero
        : Offset(delta.dx / radius, delta.dy / radius);

    setState(() {
      _thumbOffset = delta.distance == 0
          ? Offset.zero
          : Offset(
              delta.dx / delta.distance * distance,
              delta.dy / delta.distance * distance,
            );
    });

    if (delta.distance < _deadZone) {
      widget.onInputChanged(VectorInput.zero);
      return;
    }

    widget.onInputChanged(VectorInput(normalized.dx, normalized.dy));
  }

  void _resetInput() {
    setState(() {
      _thumbOffset = Offset.zero;
    });
    widget.onInputChanged(VectorInput.zero);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: _padSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) => _updateInput(details.localPosition),
        onPanUpdate: (details) => _updateInput(details.localPosition),
        onPanEnd: (_) => _resetInput(),
        onPanCancel: _resetInput,
        onTapDown: (details) => _updateInput(details.localPosition),
        onTapUp: (_) => _resetInput(),
        onTapCancel: _resetInput,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xfff4ead2).withValues(alpha: 0.16),
            border: Border.all(
              color: const Color(0xfff4ead2).withValues(alpha: 0.55),
              width: 2,
            ),
          ),
          child: Center(
            child: Transform.translate(
              offset: _thumbOffset,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xff5cc8ff).withValues(alpha: 0.85),
                  border: Border.all(color: const Color(0xff101820), width: 2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
