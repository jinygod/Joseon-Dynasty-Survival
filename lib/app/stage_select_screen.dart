import 'package:flutter/material.dart';

import '../game/content/stage_definitions.dart';

class StageSelectScreen extends StatefulWidget {
  const StageSelectScreen({
    required this.initialStageId,
    required this.onSelected,
    this.unlockedStageIds = const {moonlitAbandonedOffice},
    super.key,
  });

  final String initialStageId;
  final ValueChanged<String> onSelected;
  final Set<String> unlockedStageIds;

  @override
  State<StageSelectScreen> createState() => _StageSelectScreenState();
}

class _StageSelectScreenState extends State<StageSelectScreen> {
  late String _selectedStageId;

  @override
  void initState() {
    super.initState();
    final initial = stageDefinitionFor(widget.initialStageId).id;
    _selectedStageId = widget.unlockedStageIds.contains(initial)
        ? initial
        : stageDefinitions
                  .where((stage) => widget.unlockedStageIds.contains(stage.id))
                  .map((stage) => stage.id)
                  .firstOrNull ??
              stageDefinitions.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final selected = stageDefinitionFor(_selectedStageId);
    return Scaffold(
      appBar: AppBar(title: const Text('스테이지 선택')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    for (
                      var index = 0;
                      index < stageDefinitions.length;
                      index++
                    ) ...[
                      if (index > 0) const SizedBox(width: 12),
                      Expanded(
                        child: _StageCard(
                          stage: stageDefinitions[index],
                          unlocked: widget.unlockedStageIds.contains(
                            stageDefinitions[index].id,
                          ),
                          selected:
                              stageDefinitions[index].id == _selectedStageId,
                          onTap:
                              widget.unlockedStageIds.contains(
                                stageDefinitions[index].id,
                              )
                              ? () => setState(
                                  () => _selectedStageId =
                                      stageDefinitions[index].id,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InfoRow(
                      icon: Icons.speed,
                      text: '난이도 ${selected.riskLabel}',
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.timer_outlined,
                      text: '생존 목표 ${_clock(selected.targetSeconds)}',
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.warning_amber_rounded,
                      text: '보스 출현 ${_clock(selected.bossArrivalSeconds)}',
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      key: const Key('stage-confirm'),
                      onPressed: () => widget.onSelected(_selectedStageId),
                      icon: const Icon(Icons.check),
                      label: const Text('선택 완료'),
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

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.stage,
    required this.unlocked,
    required this.selected,
    required this.onTap,
  });

  final StageDefinition stage;
  final bool unlocked;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (stage.visualTheme) {
      StageVisualTheme.moonlit => Icons.nightlight_round,
      StageVisualTheme.plague => Icons.coronavirus_outlined,
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      color: Color(stage.backgroundColorValue),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? const Color(0xffffd66b) : const Color(0xff819081),
          width: selected ? 3 : 1,
        ),
      ),
      child: InkWell(
        key: Key('stage-${stage.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 46, color: const Color(0xffffe6a7)),
              const SizedBox(height: 10),
              Text(
                stage.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                stage.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xffd6e2d8), fontSize: 12),
              ),
              if (!unlocked) ...[
                const SizedBox(height: 8),
                Icon(
                  Icons.lock_outline,
                  key: Key('stage-lock-${stage.id}'),
                  color: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xff8f2d38)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

String _clock(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
