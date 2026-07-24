import 'package:flutter/material.dart';

import '../game/models/meta_progress.dart';
import 'joseon_panel.dart';
import 'joseon_ui_theme.dart';

/// Displays saved training progress until the training system supports edits.
class TrainingScreen extends StatelessWidget {
  const TrainingScreen({required this.progress, super.key});

  final TrainingProgress progress;

  @override
  Widget build(BuildContext context) {
    final characterIds = <String>{
      ...progress.characterRanks.keys,
      ...progress.activeCoreTraitIds.keys,
    }.toList()..sort();
    return Scaffold(
      key: const Key('training-screen'),
      appBar: AppBar(title: const Text('\uC218\uB828 \uD604\uD669')),
      backgroundColor: JoseonUiTheme.navy,
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const JoseonPanel(
              child: Text(
                '\uC218\uB828 \uAE30\uB2A5\uC740 \uC900\uBE44 \uC911\uC785\uB2C8\uB2E4. '
                '\uD604\uC7AC\uB294 \uC800\uC7A5\uB41C \uC218\uB828 \uD604\uD669\uB9CC \uC77D\uAE30 \uC804\uC6A9\uC73C\uB85C \uD45C\uC2DC\uD569\uB2C8\uB2E4.',
                key: Key('training-read-only-notice'),
              ),
            ),
            const SizedBox(height: 16),
            _RankSection(
              title: '\uACF5\uD1B5 \uC218\uB828',
              ranks: progress.commonRanks,
            ),
            for (final characterId in characterIds) ...[
              const SizedBox(height: 16),
              _CharacterSection(
                characterId: characterId,
                ranks: progress.characterRanks[characterId] ?? const {},
                activeTraitId: progress.activeCoreTraitIds[characterId],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RankSection extends StatelessWidget {
  const _RankSection({required this.title, required this.ranks});

  final String title;
  final Map<String, int> ranks;

  @override
  Widget build(BuildContext context) {
    final entries = ranks.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return JoseonPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            const Text(
              '\uAE30\uB85D\uB41C \uC218\uB828\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
            )
          else
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.key)),
                    Text('Rank ${entry.value}'),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _CharacterSection extends StatelessWidget {
  const _CharacterSection({
    required this.characterId,
    required this.ranks,
    required this.activeTraitId,
  });

  final String characterId;
  final Map<String, int> ranks;
  final String? activeTraitId;

  @override
  Widget build(BuildContext context) => JoseonPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(characterId, style: Theme.of(context).textTheme.titleLarge),
        if (activeTraitId != null) ...[
          const SizedBox(height: 6),
          Text('Active trait: $activeTraitId'),
        ],
        const SizedBox(height: 8),
        _RankSection(title: '\uCE90\uB9AD\uD130 \uC218\uB828', ranks: ranks),
      ],
    ),
  );
}
