import 'package:flutter/material.dart';

import '../game/content/augment_definitions.dart';
import '../game/content/character_definitions.dart';
import '../game/content/weapon_definitions.dart';
import '../game/models/run_outcome.dart';
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
    final isVictory = result.outcome == RunOutcome.victory;

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
                    isVictory ? '승리' : '패배',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: isVictory ? Colors.amber.shade700 : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    result.bossDefeated ? '보스 처치' : '보스 미처치',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  _StatRow(label: '생존 시간', value: _formatTime()),
                  _StatRow(label: '처치 수', value: result.kills.toString()),
                  _StatRow(label: '도달 레벨', value: result.level.toString()),
                  if (result.weaponLevels.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text('최종 무기', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (final entry in _sortedWeaponLevels())
                      _StatRow(
                        label: _displayName(entry.key),
                        value: 'Lv ${entry.value}',
                      ),
                  ],
                  const SizedBox(height: 24),
                  Text('새로운 해금', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (unlocks.isEmpty)
                    const Text('이번 판에서 새로 해금된 항목이 없습니다.')
                  else ...[
                    _UnlockGroup(label: '캐릭터', ids: unlocks.characterIds),
                    _UnlockGroup(label: '무기', ids: unlocks.weaponIds),
                    _UnlockGroup(label: '증강', ids: unlocks.augmentIds),
                  ],
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton(
                        onPressed: onStart,
                        child: const Text('다시 시작'),
                      ),
                      OutlinedButton(
                        onPressed: onMenu,
                        child: const Text('메인 메뉴'),
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

  List<MapEntry<String, int>> _sortedWeaponLevels() {
    final entries = result.weaponLevels.entries.toList();
    entries.sort((a, b) => _displayName(a.key).compareTo(_displayName(b.key)));
    return entries;
  }
}

String _displayName(String id) {
  const localizedNames = {
    rookieConstable: '신참 포졸',
    exorcistDosa: '퇴마 도사',
    lastStand: '최후의 저항',
  };
  final localizedName = localizedNames[id];
  if (localizedName != null) return localizedName;
  for (final definition in weaponDefinitions) {
    if (definition.id == id) return definition.name;
  }
  for (final definition in augmentDefinitions) {
    if (definition.id == id) return definition.name;
  }
  for (final definition in characterDefinitions) {
    if (definition.id == id) return definition.name;
  }
  return id;
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
                Chip(
                  label: Text(_displayName(id)),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
