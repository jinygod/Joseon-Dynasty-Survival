import 'package:flutter/material.dart';

import '../game/models/run_result.dart';
import '../game/systems/progression_system.dart';

class RunSummaryScreen extends StatelessWidget {
  const RunSummaryScreen({
    required this.result,
    required this.unlocks,
    required this.onStart,
    required this.onMenu,
    super.key,
  });

  final RunResult result;
  final ProgressionUnlocks unlocks;
  final VoidCallback onStart;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Text(
                    'Run Summary',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  _StatRow(label: 'Survived', value: _formatTime()),
                  _StatRow(label: 'Kills', value: result.kills.toString()),
                  _StatRow(label: 'Level', value: result.level.toString()),
                  const SizedBox(height: 24),
                  Text('New Unlocks', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (unlocks.isEmpty)
                    const Text('None')
                  else ...[
                    _UnlockGroup(
                      label: 'Characters',
                      ids: unlocks.characterIds,
                    ),
                    _UnlockGroup(label: 'Weapons', ids: unlocks.weaponIds),
                    _UnlockGroup(label: 'Augments', ids: unlocks.augmentIds),
                  ],
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton(
                        onPressed: onStart,
                        child: const Text('Start'),
                      ),
                      OutlinedButton(
                        onPressed: onMenu,
                        child: const Text('Menu'),
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

  String _formatTime() {
    final minutes = result.survivalSeconds ~/ 60;
    final seconds = result.survivalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _UnlockGroup extends StatelessWidget {
  const _UnlockGroup({required this.label, required this.ids});

  final String label;
  final List<String> ids;

  @override
  Widget build(BuildContext context) {
    if (ids.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in ids)
                Chip(label: Text(id), visualDensity: VisualDensity.compact),
            ],
          ),
        ],
      ),
    );
  }
}
