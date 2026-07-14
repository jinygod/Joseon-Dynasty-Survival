import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/models/vector_input.dart';
import 'game_hud_source.dart';

class GameHud extends StatefulWidget {
  const GameHud({required this.source, super.key});

  final GameHudSource source;

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
            if (widget.source.bossHealthFraction case final health?)
              Positioned(
                top: 8,
                left: 160,
                right: 160,
                child: BossHealthBar(
                  name: widget.source.bossName ?? 'Boss',
                  healthFraction: health,
                ),
              ),
            Positioned(
              top: widget.source.bossHealthFraction == null ? 12 : 62,
              left: 16,
              right: 16,
              child: _StatusBar(source: widget.source),
            ),
            Positioned(
              top: widget.source.bossHealthFraction == null ? 68 : 118,
              right: 16,
              width: 220,
              child: _WeaponList(labels: widget.source.weaponLevelLabels),
            ),
            Positioned(
              left: 18,
              bottom: 18,
              child: _DeveloperMovePad(
                onInputChanged: widget.source.updateMovementInput,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.source});

  final GameHudSource source;

  @override
  Widget build(BuildContext context) {
    final elapsed = Duration(seconds: source.elapsedSeconds.floor());
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
              _HudValue(label: 'HP', value: source.playerHealthLabel),
              _HudValue(label: 'Level', value: '${source.playerLevel}'),
              _HudValue(
                label: 'XP',
                value:
                    '${source.currentExperience}/${source.experienceToNextLevel}',
              ),
              _HudValue(label: 'Enemies', value: '${source.enemyCount}'),
              _HudValue(label: 'Kills', value: '${source.kills}'),
            ],
          ),
        ),
      ),
    );
  }
}

class BossHealthBar extends StatelessWidget {
  const BossHealthBar({
    required this.name,
    required this.healthFraction,
    super.key,
  });

  final String name;
  final double healthFraction;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xfff4ead2),
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
            shadows: [Shadow(color: Color(0xff101820), blurRadius: 3)],
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: healthFraction.clamp(0, 1).toDouble(),
          minHeight: 10,
          backgroundColor: const Color(0xff2f1b25),
          color: const Color(0xffd1495b),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

class _WeaponList extends StatelessWidget {
  const _WeaponList({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xff101820).withValues(alpha: 0.78),
        border: Border.all(color: const Color(0xff9fb3c8)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final label in labels)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xfff4ead2),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
          ],
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
