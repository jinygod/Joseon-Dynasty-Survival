import 'dart:async';

import 'package:flutter/material.dart';

import '../game/content/weapon_definitions.dart';
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
              left: 0,
              right: 0,
              child: _TopHud(
                source: widget.source,
                uiScale: widget.uiScale,
                leadingClearance: widget.onPause == null ? 8 : 64,
              ),
            ),
            Positioned.fill(
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
                child: _PauseButton(onPressed: onPause),
              ),
          ],
        ),
      ),
    );
  }
}

class _PauseButton extends StatelessWidget {
  const _PauseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: AppStrings.pauseGame,
      child: ExcludeSemantics(
        child: SizedBox.square(
          key: const Key('hud-pause'),
          dimension: 48,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xe8101820),
                  border: Border.all(
                    color: const Color(0xfff4ead2),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const CustomPaint(
                  key: Key('hud-pause-glyph'),
                  painter: _PauseGlyphPainter(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PauseGlyphPainter extends CustomPainter {
  const _PauseGlyphPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xfffff1b8);
    final height = size.height * 0.42;
    final top = (size.height - height) / 2;
    final width = size.width * 0.12;
    final gap = size.width * 0.12;
    final left = (size.width - width * 2 - gap) / 2;
    final radius = Radius.circular(width / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(left, top, width, height), radius),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left + width + gap, top, width, height),
        radius,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PauseGlyphPainter oldDelegate) => false;
}

class _TopHud extends StatelessWidget {
  const _TopHud({
    required this.source,
    required this.uiScale,
    required this.leadingClearance,
  });

  final GameHudSource source;
  final double uiScale;
  final double leadingClearance;

  @override
  Widget build(BuildContext context) {
    final notice = source.combatNotice;
    final showNotice =
        notice != null && source.combatNoticeSecondsRemaining > 0;
    final showStreak = source.killStreak > 1;
    return Padding(
      padding: EdgeInsets.only(left: leadingClearance, right: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
              label: '${AppStrings.combatNotice} $notice',
              excludeSemantics: true,
              child: _CombatNotice(label: notice),
            ),
          ],
          if (showStreak) ...[
            const SizedBox(height: 3),
            Semantics(
              key: const Key('kill-streak'),
              liveRegion: true,
              label: '${source.killStreak} ${AppStrings.killStreak}',
              excludeSemantics: true,
              child: Center(
                child: Text(
                  '${source.killStreak} ${AppStrings.killStreak}',
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
            ),
          ],
        ],
      ),
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
        '${AppStrings.hudKills} ${source.kills}';

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: statusLabel,
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
            child: Column(
              children: [
                SizedBox(
                  height: 28,
                  child: ExcludeSemantics(
                    child: Row(
                      children: [
                        Container(
                          height: 28,
                          constraints: const BoxConstraints(minWidth: 58),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xffffe08a), Color(0xffc88719)],
                            ),
                            border: Border.all(
                              color: const Color(0xfffff1b8),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(7),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x66000000),
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${AppStrings.hudLevel} ${source.playerLevel}',
                              key: const Key('hud-player-level'),
                              style: const TextStyle(
                                color: Color(0xff24170a),
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Center(
                                child: _MeterBar(
                                  key: const Key('hud-xp-bar'),
                                  value: xpFraction,
                                  color: const Color(0xff43bff5),
                                  fillGradient: const LinearGradient(
                                    colors: [
                                      Color(0xffd9fbff),
                                      Color(0xff43bff5),
                                      Color(0xff2284db),
                                    ],
                                  ),
                                  trackColor: const Color(0xff122f4b),
                                  fillKey: const Key('hud-xp-fill'),
                                  height: 16,
                                  showLeadingCap: true,
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 7),
                                  child: Text(
                                    '${source.currentExperience}/${source.experienceToNextLevel}',
                                    key: const Key('hud-xp-value'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      shadows: [
                                        Shadow(
                                          color: Color(0xff07121d),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  height: 38,
                  child: Row(
                    children: [
                      Expanded(
                        child: ExcludeSemantics(
                          child: Column(
                            children: [
                              SizedBox(
                                height: 17,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _FittedHudText(
                                        '$minutes:$seconds',
                                        color: const Color(0xfffff1b8),
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    SizedBox(
                                      width: 64,
                                      height: 17,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          '${source.kills}',
                                          key: const Key('hud-kills-value'),
                                          style: const TextStyle(
                                            color: Color(0xff9fb3c8),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
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
                                fillKey: const Key('hud-health-fill'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
    );
  }
}

class _MeterBar extends StatelessWidget {
  const _MeterBar({
    required this.value,
    required this.color,
    required this.trackColor,
    this.fillKey,
    this.fillGradient,
    this.height = 9,
    this.showLeadingCap = false,
    super.key,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final Key? fillKey;
  final Gradient? fillGradient;
  final double height;
  final bool showLeadingCap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: DecoratedBox(
          decoration: BoxDecoration(color: trackColor),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0, 1),
              child: DecoratedBox(
                key: fillKey,
                decoration: BoxDecoration(
                  color: fillGradient == null ? color : null,
                  gradient: fillGradient,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
                child: showLeadingCap
                    ? const Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 3,
                          child: ColoredBox(color: Color(0xfff2ffff)),
                        ),
                      )
                    : null,
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
    final level = _levelFromLabel(label);
    final style = _weaponMarkStyleForLabel(label);
    final color = switch (style) {
      _WeaponMarkStyle.hwando => const Color(0xffd9f7ff),
      _WeaponMarkStyle.talisman => const Color(0xffffd6aa),
      _WeaponMarkStyle.projectile => const Color(0xffe8c5ff),
    };
    return Semantics(
      container: true,
      label: label,
      excludeSemantics: true,
      child: SizedBox.square(
        key: Key('hud-weapon-slot-$index'),
        dimension: 32,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xff172633),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Stack(
            children: [
              Center(
                child: CustomPaint(
                  key: Key('hud-weapon-mark-$index-${style.name}'),
                  size: const Size.square(17),
                  painter: _WeaponMarkPainter(style: style, color: color),
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
                      key: Key('hud-weapon-level-$index'),
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

enum _WeaponMarkStyle { hwando, talisman, projectile }

const _weaponMarkStyleById = <String, _WeaponMarkStyle>{
  hwandoSlash: _WeaponMarkStyle.hwando,
  talismanThrow: _WeaponMarkStyle.talisman,
  gakgungShot: _WeaponMarkStyle.projectile,
};

const _weaponIdAliases = <String, List<String>>{
  hwandoSlash: ['hwando slash', 'hwando'],
  talismanThrow: ['talisman throw', 'talisman'],
  gakgungShot: ['gakgung shot', 'gakgung', 'bow shot'],
};

_WeaponMarkStyle _weaponMarkStyleForLabel(String label) {
  final normalized = label.toLowerCase();
  for (final definition in weaponDefinitions) {
    if (normalized.contains(definition.name.toLowerCase())) {
      return _weaponMarkStyleById[definition.id] ?? _WeaponMarkStyle.projectile;
    }
  }
  for (final entry in _weaponIdAliases.entries) {
    if (entry.value.any(normalized.contains)) {
      return _weaponMarkStyleById[entry.key] ?? _WeaponMarkStyle.projectile;
    }
  }
  return _WeaponMarkStyle.projectile;
}

class _WeaponMarkPainter extends CustomPainter {
  const _WeaponMarkPainter({required this.style, required this.color});

  final _WeaponMarkStyle style;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (style) {
      case _WeaponMarkStyle.hwando:
        canvas.drawLine(
          Offset(size.width * .22, size.height * .78),
          Offset(size.width * .78, size.height * .22),
          paint,
        );
        canvas.drawLine(
          Offset(size.width * .52, size.height * .78),
          Offset(size.width * .78, size.height * .52),
          paint..strokeWidth = 1.4,
        );
        return;
      case _WeaponMarkStyle.talisman:
        paint.style = PaintingStyle.fill;
        final talisman = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: size.width * .5,
            height: size.height * .7,
          ),
          const Radius.circular(2),
        );
        canvas.drawRRect(talisman, paint);
        paint.color = const Color(0xff172633);
        paint.strokeWidth = 1.3;
        canvas.drawLine(
          Offset(size.width * .37, size.height * .38),
          Offset(size.width * .63, size.height * .62),
          paint,
        );
        return;
      case _WeaponMarkStyle.projectile:
        paint.style = PaintingStyle.fill;
        final path = Path()
          ..moveTo(size.width * .57, size.height * .08)
          ..lineTo(size.width * .18, size.height * .56)
          ..lineTo(size.width * .47, size.height * .56)
          ..lineTo(size.width * .38, size.height * .92)
          ..lineTo(size.width * .82, size.height * .38)
          ..lineTo(size.width * .55, size.height * .38)
          ..close();
        canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeaponMarkPainter oldDelegate) =>
      oldDelegate.style != style || oldDelegate.color != color;
}

class _FittedHudText extends StatelessWidget {
  const _FittedHudText(
    this.text, {
    required this.color,
    this.fontWeight = FontWeight.w700,
  });

  final String text;
  final Color color;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        maxLines: 1,
        textAlign: TextAlign.start,
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
        ? AppStrings.savingRewardAgain
        : AppStrings.collectingReward(seconds.ceil().clamp(0, 3));
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
  final match = RegExp(r'(\d+)\s*/\s*(\d+)').firstMatch(label);
  if (match == null) return 1;
  final current = double.tryParse(match.group(1)!) ?? 0;
  final maximum = double.tryParse(match.group(2)!) ?? 0;
  if (maximum <= 0) return 0;
  return (current / maximum).clamp(0, 1);
}

int _levelFromLabel(String label) {
  final matches = RegExp(r'\d+').allMatches(label);
  if (matches.isEmpty) return 1;
  return int.tryParse(matches.last.group(0)!) ?? 1;
}
