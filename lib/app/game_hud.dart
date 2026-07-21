import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'game_hud_source.dart';
import 'virtual_joystick.dart';

class GameHud extends StatefulWidget {
  const GameHud({
    required this.source,
    this.onPause,
    this.uiScale = 1,
    super.key,
  });

  final GameHudSource source;
  final VoidCallback? onPause;
  final double uiScale;

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
    final rewardSource = widget.source is RewardCollectionHudSource
        ? widget.source as RewardCollectionHudSource
        : null;
    final scale = widget.uiScale;
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Stack(
          children: [
            if (rewardSource?.rewardCollectionSecondsRemaining
                case final seconds?)
              Positioned(
                top: 150,
                left: 0,
                right: 0,
                child: Center(
                  child: _RewardCollectionNotice(
                    seconds: seconds,
                    retrying: rewardSource!.isSpiritJadeSaveRetrying,
                    uiScale: scale,
                  ),
                ),
              ),
            Positioned(
              top: 8,
              left: 16,
              right: 16,
              child: _TopHud(source: widget.source, uiScale: scale),
            ),
            Positioned(
              left: 18,
              bottom: 18,
              child: VirtualJoystick(
                onInputChanged: widget.source.updateMovementInput,
                size: 120 * scale,
                deadZone: 10 * scale,
              ),
            ),
            if (widget.onPause case final onPause?)
              Positioned(
                top: 8,
                left: 8,
                child: IconButton.filledTonal(
                  key: const Key('hud-pause'),
                  tooltip: '일시정지',
                  onPressed: onPause,
                  iconSize: 24 * scale,
                  padding: EdgeInsets.all(8 * scale),
                  constraints: BoxConstraints(
                    minWidth: 48 * scale,
                    minHeight: 48 * scale,
                  ),
                  icon: const Icon(Icons.pause),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopHud extends StatelessWidget {
  const _TopHud({required this.source, required this.uiScale});

  final GameHudSource source;
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    final notice = source.combatNotice;
    final showNotice =
        notice != null && source.combatNoticeSecondsRemaining > 0;
    final showStreak = source.killStreak > 1;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (source.bossHealthFraction case final health?) ...[
          Center(
            child: FractionallySizedBox(
              key: const Key('boss-warning'),
              widthFactor: 0.65,
              child: BossHealthBar(
                name: source.bossName ?? AppStrings.genericBoss,
                healthFraction: health,
                uiScale: uiScale,
              ),
            ),
          ),
          SizedBox(height: 8 * uiScale),
        ],
        KeyedSubtree(
          key: const Key('hud-status'),
          child: _StatusBar(source: source, uiScale: uiScale),
        ),
        if (showNotice) ...[
          SizedBox(height: 8 * uiScale),
          Semantics(
            key: const Key('combat-notice'),
            liveRegion: true,
            label: '전투 알림 $notice',
            excludeSemantics: true,
            child: Center(
              child: _CombatNotice(label: notice, uiScale: uiScale),
            ),
          ),
        ],
        if (showStreak) ...[
          SizedBox(height: 4 * uiScale),
          Semantics(
            key: const Key('kill-streak'),
            liveRegion: true,
            label: '${source.killStreak} 연속 처치',
            excludeSemantics: true,
            child: Text(
              '${source.killStreak} 연속 처치',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xffffd166),
                fontSize: 13 * uiScale,
                fontWeight: FontWeight.w800,
                shadows: const [
                  Shadow(color: Color(0xff101820), blurRadius: 3),
                ],
              ),
            ),
          ),
        ],
        if (source.weaponLevelLabels.isNotEmpty) ...[
          SizedBox(height: 8 * uiScale),
          Align(
            alignment: Alignment.topRight,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 220 * uiScale),
              child: KeyedSubtree(
                key: const Key('weapon-list'),
                child: _WeaponList(
                  labels: source.weaponLevelLabels,
                  uiScale: uiScale,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CombatNotice extends StatelessWidget {
  const _CombatNotice({required this.label, required this.uiScale});

  final String label;
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 240 * uiScale),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xff2f1b25).withValues(alpha: 0.9),
          border: Border.all(color: const Color(0xffffd166)),
          borderRadius: BorderRadius.circular(8 * uiScale),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 14 * uiScale,
            vertical: 7 * uiScale,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xfffff1b8),
              fontSize: 16 * uiScale,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardCollectionNotice extends StatelessWidget {
  const _RewardCollectionNotice({
    required this.seconds,
    required this.retrying,
    required this.uiScale,
  });

  final double seconds;
  final bool retrying;
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    final label = retrying
        ? '혼옥 저장 재시도 중'
        : '혼옥 수거 ${seconds.ceil().clamp(0, 3)}초';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xff2f1b25).withValues(alpha: 0.9),
        border: Border.all(color: const Color(0xffffd166), width: 2 * uiScale),
        borderRadius: BorderRadius.circular(10 * uiScale),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 18 * uiScale,
          vertical: 10 * uiScale,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: const Color(0xfffff1b8),
            fontSize: 18 * uiScale,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.source, required this.uiScale});

  final GameHudSource source;
  final double uiScale;

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
          border: Border.all(
            color: const Color(0xfff4ead2),
            width: 1.5 * uiScale,
          ),
          borderRadius: BorderRadius.circular(8 * uiScale),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 14 * uiScale,
            vertical: 10 * uiScale,
          ),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 16 * uiScale,
            runSpacing: 6 * uiScale,
            children: [
              _HudValue(
                label: AppStrings.hudTime,
                value: '$minutes:$seconds',
                uiScale: uiScale,
              ),
              _HudValue(
                label: AppStrings.hudHealth,
                value: source.playerHealthLabel,
                uiScale: uiScale,
              ),
              _HudValue(
                label: AppStrings.hudLevel,
                value: '${source.playerLevel}',
                uiScale: uiScale,
              ),
              _HudValue(
                label: AppStrings.hudExperience,
                value:
                    '${source.currentExperience}/${source.experienceToNextLevel}',
                uiScale: uiScale,
              ),
              _HudValue(
                label: AppStrings.hudEnemies,
                value: '${source.enemyCount}',
                uiScale: uiScale,
              ),
              _HudValue(
                label: AppStrings.hudKills,
                value: '${source.kills}',
                uiScale: uiScale,
              ),
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
    this.uiScale = 1,
    super.key,
  });

  final String name;
  final double healthFraction;
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xfff4ead2),
            fontSize: 14 * uiScale,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
            shadows: const [Shadow(color: Color(0xff101820), blurRadius: 3)],
          ),
        ),
        SizedBox(height: 4 * uiScale),
        LinearProgressIndicator(
          value: healthFraction.clamp(0, 1).toDouble(),
          minHeight: 10 * uiScale,
          backgroundColor: const Color(0xff2f1b25),
          color: const Color(0xffd1495b),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

class _WeaponList extends StatelessWidget {
  const _WeaponList({required this.labels, required this.uiScale});

  final List<String> labels;
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xff101820).withValues(alpha: 0.78),
        border: Border.all(color: const Color(0xff9fb3c8)),
        borderRadius: BorderRadius.circular(6 * uiScale),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 12 * uiScale,
          vertical: 8 * uiScale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final label in labels)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 2 * uiScale),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xfff4ead2),
                    fontSize: 13 * uiScale,
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
  const _HudValue({
    required this.label,
    required this.value,
    required this.uiScale,
  });

  final String label;
  final String value;
  final double uiScale;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: '$label ',
        style: TextStyle(
          color: const Color(0xff9fb3c8),
          fontSize: 12 * uiScale,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        children: [
          TextSpan(
            text: value,
            style: TextStyle(
              color: const Color(0xfff4ead2),
              fontSize: 14 * uiScale,
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
