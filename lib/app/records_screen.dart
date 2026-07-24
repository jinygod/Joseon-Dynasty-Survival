import 'package:flutter/material.dart';

import '../game/content/asset_catalog.dart';
import '../game/content/character_definitions.dart';
import '../game/models/meta_history.dart';
import '../game/systems/meta_history_service.dart';
import '../game/systems/save_system.dart';
import 'joseon_codex_card.dart';
import 'joseon_ui_theme.dart';
import 'missing_asset_placeholder.dart';

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
              GridView.count(
                key: const Key('records-summary-grid'),
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 112,
                children: [
                  for (final record in records)
                    _SummaryCard(icon: record.icon, label: record.label),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionTitle('캐릭터별 승리'),
              const SizedBox(height: 8),
              for (final character in characterDefinitions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: JoseonCodexCard(
                    title:
                        '${character.name} ${widget.state.characterVictoryCounts[character.id] ?? 0}승',
                    description: '',
                    locked: false,
                    leading: _CatalogThumbnail(
                      assetPath: AssetCatalog.characters[character.id],
                      assetKey: character.id,
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
                    return const JoseonCodexCard(
                      title: '아직 저장된 무기 사용 기록이 없습니다.',
                      description: '',
                      locked: false,
                    );
                  }
                  return Column(
                    children: [
                      for (final record in usage)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: JoseonCodexCard(
                            title: record.weaponName,
                            description:
                                '사용 ${record.usageRuns}판 · '
                                '처치 ${record.kills} · 피해 ${_number(record.damage)}',
                            locked: false,
                            leading: _CatalogThumbnail(
                              assetPath: AssetCatalog.weapons[record.weaponId],
                              assetKey: record.weaponId,
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
    final splitAt = label.lastIndexOf(' ');
    final supportingLabel = label.substring(0, splitAt);
    final value = label.substring(splitAt + 1);
    return Semantics(
      label: '$supportingLabel $value',
      child: DecoratedBox(
        key: const Key('record-summary-card'),
        decoration: BoxDecoration(
          color: JoseonUiTheme.ivory,
          borderRadius: JoseonUiTheme.panelRadius,
          border: Border.all(
            color: JoseonUiTheme.unlocked,
            width: JoseonUiTheme.panelBorderWidth,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(JoseonUiTheme.compactSpacing),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xff8f2d38)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      key: const Key('record-summary-value'),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      supportingLabel,
                      key: const Key('record-summary-label'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogThumbnail extends StatelessWidget {
  const _CatalogThumbnail({required this.assetPath, required this.assetKey});

  final String? assetPath;
  final String assetKey;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 36,
    height: 36,
    child: assetPath == null
        ? MissingAssetPlaceholder(assetKey: assetKey)
        : Image.asset(
            assetPath!,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                MissingAssetPlaceholder(assetKey: assetKey),
          ),
  );
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
