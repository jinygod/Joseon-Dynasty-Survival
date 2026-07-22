import 'package:flutter/material.dart';

import '../game/systems/level_up_system.dart';
import '../l10n/app_strings.dart';

class LevelUpOverlay extends StatelessWidget {
  const LevelUpOverlay({
    required this.choices,
    required this.onChoiceSelected,
    super.key,
  });

  final List<LevelUpChoice> choices;
  final ValueChanged<LevelUpChoice> onChoiceSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xdd10151f),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 600;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 20,
                vertical: 14,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 28,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _ChoiceTitleRibbon(),
                    const SizedBox(height: 14),
                    if (compact)
                      for (var index = 0; index < choices.length; index++) ...[
                        if (index > 0) const SizedBox(height: 10),
                        _LevelUpChoiceCard(
                          index: index,
                          choice: choices[index],
                          compact: true,
                          onPressed: () => onChoiceSelected(choices[index]),
                        ),
                      ]
                    else
                      SizedBox(
                        height: 250,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (
                              var index = 0;
                              index < choices.length;
                              index++
                            ) ...[
                              if (index > 0) const SizedBox(width: 12),
                              Expanded(
                                child: _LevelUpChoiceCard(
                                  index: index,
                                  choice: choices[index],
                                  compact: false,
                                  onPressed: () =>
                                      onChoiceSelected(choices[index]),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      '원하는 성장을 선택하세요',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .78),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChoiceTitleRibbon extends StatelessWidget {
  const _ChoiceTitleRibbon();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('level-up-title'),
      width: 286,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffffdf35), Color(0xffffae19)],
        ),
        border: Border.all(color: const Color(0xff271b12), width: 2),
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Text(
        '성장 선택',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xff26180d),
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -.4,
        ),
      ),
    );
  }
}

class _LevelUpChoiceCard extends StatelessWidget {
  const _LevelUpChoiceCard({
    required this.index,
    required this.choice,
    required this.compact,
    required this.onPressed,
  });

  final int index;
  final LevelUpChoice choice;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isWeapon = choice.type == LevelUpChoiceType.weapon;
    final accent = isWeapon ? const Color(0xffffca28) : const Color(0xff8bd13e);
    final typeLabel = isWeapon ? AppStrings.weapon : AppStrings.augment;
    final details = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          choice.displayName,
          key: Key('level-up-choice-name-$index'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          AppStrings.levelRange(
            current: choice.currentLevel,
            next: choice.nextLevel,
          ),
          style: TextStyle(
            color: accent,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          choice.effectDescription,
          key: Key('level-up-choice-effect-$index'),
          style: const TextStyle(
            color: Color(0xffeef2f8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.28,
          ),
        ),
        const SizedBox(height: 9),
        _LevelPips(level: choice.nextLevel, accent: accent),
      ],
    );

    return Semantics(
      button: true,
      label: '$typeLabel ${choice.displayName} ${choice.effectDescription}',
      child: Material(
        key: Key('level-up-choice-$index'),
        color: const Color(0xff303847),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: accent, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: compact ? 154 : 226),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Text(
                    typeLabel,
                    textAlign: compact ? TextAlign.left : TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xff21170c),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: compact
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ChoiceMedallion(
                              isWeapon: isWeapon,
                              accent: accent,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: details),
                          ],
                        )
                      : Column(
                          children: [
                            _ChoiceMedallion(
                              isWeapon: isWeapon,
                              accent: accent,
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: details,
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

class _ChoiceMedallion extends StatelessWidget {
  const _ChoiceMedallion({required this.isWeapon, required this.accent});

  final bool isWeapon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xff18212d),
        border: Border.all(color: accent, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isWeapon ? Icons.gps_fixed : Icons.auto_awesome,
        color: accent,
        size: 30,
      ),
    );
  }
}

class _LevelPips extends StatelessWidget {
  const _LevelPips({required this.level, required this.accent});

  final int level;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 1; index <= 6; index++) ...[
          if (index > 1) const SizedBox(width: 4),
          Container(
            width: 15,
            height: 5,
            decoration: BoxDecoration(
              color: index <= level ? accent : const Color(0xff151b24),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ],
    );
  }
}
