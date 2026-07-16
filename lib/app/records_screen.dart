import 'package:flutter/material.dart';

import '../game/content/character_definitions.dart';
import '../game/models/meta_history.dart';
import '../game/systems/meta_history_service.dart';
import '../game/systems/save_system.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({required this.state, this.historyService, super.key});

  final SaveState state;
  final MetaHistoryService? historyService;

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  late final Future<List<WeaponUsageRecord>> _weaponUsage;

  @override
  void initState() {
    super.initState();
    _weaponUsage = (widget.historyService ?? MetaHistoryService())
        .loadWeaponUsage();
  }

  @override
  Widget build(BuildContext context) {
    final records = <({IconData icon, String label})>[
      (icon: Icons.sports_kabaddi, label: '누적 처치 ${widget.state.totalKills}'),
      (
        icon: Icons.timer_outlined,
        label: '최고 생존 ${_clock(widget.state.bestSurvivalSeconds)}',
      ),
      (icon: Icons.military_tech, label: '보스 격파 ${widget.state.bossDefeats}'),
      (
        icon: Icons.flag_outlined,
        label: '달성 목표 ${widget.state.completedGoalIds.length}',
      ),
      (
        icon: Icons.auto_awesome,
        label: '해금 무기 ${widget.state.unlockedWeaponIds.length}',
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('기록')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final record in records)
                    _SummaryCard(icon: record.icon, label: record.label),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionTitle('캐릭터별 승리'),
              const SizedBox(height: 8),
              for (final character in characterDefinitions)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(
                      '${character.name} '
                      '${widget.state.characterVictoryCounts[character.id] ?? 0}승',
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const _SectionTitle('무기 사용 기록'),
              const SizedBox(height: 8),
              FutureBuilder<List<WeaponUsageRecord>>(
                future: _weaponUsage,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final usage = snapshot.data ?? const [];
                  if (usage.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          '아직 저장된 무기 사용 기록이 없습니다.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final record in usage)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.auto_awesome),
                            title: Text(record.weaponName),
                            subtitle: Text(
                              '사용 ${record.usageRuns}판 · '
                              '처치 ${record.kills} · '
                              '피해 ${_number(record.damage)}',
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SizedBox(
      width: width >= 800 ? 230 : (width - 42) / 2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xff8f2d38)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
  );
}

String _clock(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
