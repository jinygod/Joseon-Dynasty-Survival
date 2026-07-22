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
      if (mounted) setState(() {});
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
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Stack(
          children: [
            if (rewardSource?.rewardCollectionSecondsRemaining
                case final seconds?)
              Positioned(
                top: 118,
                left: 0,
                right: 0,
                child: Center(
                  child: _RewardCollectionNotice(
                    seconds: seconds,
                    retrying: rewardSource!.isSpiritJadeSaveRetrying,
                    uiScale: widget.uiScale,
                  ),
                ),
              ),
            Positioned(
              top: widget.source.bossHealthFraction == null ? 8 : 6,
              left: 64,
              right: 12,
              child: _TopHud(source: widget.source, uiScale: widget.uiScale),
            ),
            Positioned(
              left: 18,
              bottom: 18,
              child: VirtualJoystick(
                onInputChanged: widget.source.updateMovementInput,
                size: 104,
                deadZone: 9,
                idleOpacity: 0.35,
                activeOpacity: 0.55,
              ),
            ),
            if (widget.onPause case final onPause?)
              Positioned(
                top: 8,
                left: 8,
                child: Semantics(
                  button: true,
                  label: 'Pause game',
                  child: SizedBox.square(
                    key: const Key('hud-pause'),
                    dimension: 48,
                    child: IconButton.filledTonal(
                      tooltip: 'Pause game',
                      onPressed: onPause,
                      iconSize: 22,
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.pause),
                    ),
                  ),
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
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (source.bossHealthFraction case final health?) ...[
          Align(
            alignment: Alignment.center,
            child: FractionallySizedBox(
              key: const Key('boss-warning'),
              widthFactor: 0.88,
              child: BossHealthBar(
                name: source.bossName ?? AppStrings.genericBoss,
                healthFraction: health,
                uiScale: uiScale,
              ),
            ),
          ),
          const SizedBox(height: 5),
        ],
        KeyedSubtree(
          key: const Key('hud-status'),
          child: _StatusBar(source: source),
        ),
        if (showNotice) ...[
          const SizedBox(height: 6),
          Semantics(
            key: const Key('combat-notice'),
            liveRegion: true,
            label: 'Combat notice $notice',
            excludeSemantics: true,
            child: _CombatNotice(label: notice),
          ),
        ],
        if (showStreak) ...[
          const SizedBox(height: 3),
          Semantics(
            key: const Key('kill-streak'),
            liveRegion: true,
            label: '${source.killStreak} ${AppStrings.hudKills}',
            excludeSemantics: true,
            child: Text(
              '${source.killStreak} ${AppStrings.hudKills}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xffffd166),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                shadows: [Shadow(color: Color(0xff101820), blurRadius: 3)],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.source});

  static const _panelColor = Color(0xe8101820);
  final GameHudSource source;

  @override
  Widget build(BuildContext context) {
    final elapsed = Duration(seconds: source.elapsedSeconds.floor());
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final healthFraction = _fractionFromLabel(source.playerHealthLabel);
    final xpFraction = source.experienceToNextLevel <= 0
        ? 0.0
        : (source.currentExperience / source.experienceToNextLevel)
              .clamp(0, 1)
              .toDouble();
    final statusLabel =
        '${AppStrings.hudTime} $minutes:$seconds, '
        '${AppStrings.hudHealth} ${source.playerHealthLabel}, '
        '${AppStrings.hudLevel} ${source.playerLevel}, '
        '${AppStrings.hudExperience} '
        '${source.currentExperience}/${source.experienceToNextLevel}, '
        '${AppStrings.hudEnemies} ${source.enemyCount}, '
        '${AppStrings.hudKills} ${source.kills}';

    return Semantics(
      container: true,
      label: statusLabel,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 292),
        child: SizedBox(
          height: 88,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _panelColor,
              border: Border.all(color: const Color(0xfff4ead2), width: 1.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
              child: ExcludeSemantics(
                child: Column(
                  children: [
                    SizedBox(
                      height: 17,
                      child: Row(
                        children: [
                          Expanded(
                            child: _FittedHudText(
                              '$minutes:$seconds  '
                              '${AppStrings.hudLevel} ${source.playerLevel}',
                              color: const Color(0xfffff1b8),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: _FittedHudText(
                              '${source.enemyCount} / ${source.kills}',
                              color: const Color(0xff9fb3c8),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    _MeterBar(
                      key: const Key('hud-health-bar'),
                      value: healthFraction,
                      color: const Color(0xffef5b5b),
                      trackColor: const Color(0xff48242d),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 32,
                      child: Row(
                        children: [
                          Expanded(
                            child: _MeterBar(
                              key: const Key('hud-xp-bar'),
                              value: xpFraction,
                              color: const Color(0xff5cc8ff),
                              trackColor: const Color(0xff1a3b50),
                              label:
                                  '${source.currentExperience}/${source.experienceToNextLevel}',
                            ),
                          ),
                          const SizedBox(width: 6),
                          KeyedSubtree(
                            key: const Key('weapon-list'),
                            child: _WeaponSlots(
                              labels: source.weaponLevelLabels.take(3).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MeterBar extends StatelessWidget {
  const _MeterBar({
    required this.value,
    required this.color,
    required this.trackColor,
    this.label,
    super.key,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: SizedBox(
        height: 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4.5),
          child: DecoratedBox(
            decoration: BoxDecoration(color: trackColor),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: value.clamp(0, 1),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4.5),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeaponSlots extends StatelessWidget {
  const _WeaponSlots({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          if (index > 0) const SizedBox(width: 4),
          _WeaponSlot(index: index, label: labels[index]),
        ],
      ],
    );
  }
}

class _WeaponSlot extends StatelessWidget {
  const _WeaponSlot({required this.index, required this.label});

  final int index;
  final String label;

  @override
  Widget build(BuildContext context) {
    const colors = [Color(0xffd9f7ff), Color(0xffffd6aa), Color(0xffe8c5ff)];
    final level = _levelFromLabel(label);
    return Semantics(
      label: label,
      child: SizedBox.square(
        key: Key('hud-weapon-slot-$index'),
        dimension: 32,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xff172633),
            border: Border.all(color: colors[index % colors.length]),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  [
                    Icons.gesture,
                    Icons.auto_awesome,
                    Icons.track_changes,
                  ][index % 3],
                  size: 17,
                  color: colors[index % colors.length],
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: 13,
                  height: 13,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xff101820),
                    shape: BoxShape.circle,
                  ),
                  child: FittedBox(
                    child: Text(
                      '$level',
                      style: const TextStyle(
                        color: Color(0xfffff1b8),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FittedHudText extends StatelessWidget {
  const _FittedHudText(
    this.text, {
    required this.color,
    this.fontWeight = FontWeight.w700,
    this.textAlign = TextAlign.start,
  });

  final String text;
  final Color color;
  final FontWeight fontWeight;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: textAlign == TextAlign.end
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Text(
        text,
        maxLines: 1,
        textAlign: textAlign,
        style: TextStyle(color: color, fontSize: 12, fontWeight: fontWeight),
      ),
    );
  }
}

class _CombatNotice extends StatelessWidget {
  const _CombatNotice({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xff2f1b25).withValues(alpha: 0.9),
          border: Border.all(color: const Color(0xffffd166)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xfffff1b8),
              fontSize: 16,
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
        ? 'Saving reward again'
        : 'Collecting reward ${seconds.ceil().clamp(0, 3)}s';
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

double _fractionFromLabel(String label) {
  final match = RegExp(r'(\\d+)\\s*/\\s*(\\d+)').firstMatch(label);
  if (match == null) return 1;
  final current = double.tryParse(match.group(1)!) ?? 0;
  final maximum = double.tryParse(match.group(2)!) ?? 0;
  if (maximum <= 0) return 0;
  return (current / maximum).clamp(0, 1);
}

int _levelFromLabel(String label) {
  final matches = RegExp(r'\\d+').allMatches(label);
  if (matches.isEmpty) return 1;
  return int.tryParse(matches.last.group(0)!) ?? 1;
}
