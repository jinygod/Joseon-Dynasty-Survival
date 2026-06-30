import 'package:flutter/material.dart';

import '../game/systems/level_up_system.dart';

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
    final theme = Theme.of(context);

    return Material(
      color: Colors.black.withValues(alpha: 0.58),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Level Up',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: const Color(0xfff4ead2),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      for (final choice in choices)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: _LevelUpChoiceButton(
                              choice: choice,
                              onPressed: () => onChoiceSelected(choice),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelUpChoiceButton extends StatelessWidget {
  const _LevelUpChoiceButton({required this.choice, required this.onPressed});

  final LevelUpChoice choice;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final typeLabel = switch (choice.type) {
      LevelUpChoiceType.weapon => 'Weapon',
      LevelUpChoiceType.augment => 'Augment',
    };

    return SizedBox(
      height: 148,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          alignment: Alignment.centerLeft,
          backgroundColor: const Color(0xfff4ead2),
          foregroundColor: const Color(0xff17202a),
          padding: const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              typeLabel.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              choice.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Lv ${choice.currentLevel} -> ${choice.nextLevel}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
