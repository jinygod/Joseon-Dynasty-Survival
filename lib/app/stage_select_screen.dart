import 'package:flutter/material.dart';

import '../game/content/stage_definitions.dart';

class StageSelectScreen extends StatefulWidget {
  const StageSelectScreen({required this.onStart, super.key});

  final ValueChanged<String> onStart;

  @override
  State<StageSelectScreen> createState() => _StageSelectScreenState();
}

class _StageSelectScreenState extends State<StageSelectScreen> {
  String _selectedStageId = stageDefinitions.first.id;

  @override
  Widget build(BuildContext context) {
    final selected = stageDefinitions.firstWhere(
      (stage) => stage.id == _selectedStageId,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('스테이지 선택')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 18, 32, 24),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  color: const Color(0xff1d3344),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xffe7c66b), width: 3),
                  ),
                  child: InkWell(
                    key: Key('stage-${selected.id}'),
                    onTap: () => setState(() => _selectedStageId = selected.id),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.nightlight_round,
                            size: 64,
                            color: Color(0xffffe6a7),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            selected.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            selected.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xffd6e2ea),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InfoRow(
                      icon: Icons.timer_outlined,
                      text: '생존 목표 ${_clock(selected.targetSeconds)}',
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(
                      icon: Icons.warning_amber_rounded,
                      text: '보스 출현 ${_clock(selected.bossArrivalSeconds)}',
                    ),
                    const SizedBox(height: 14),
                    const _InfoRow(
                      icon: Icons.flag_outlined,
                      text: '보스 처치 시 승리',
                    ),
                    const SizedBox(height: 26),
                    FilledButton.icon(
                      key: const Key('stage-start'),
                      onPressed: () => widget.onStart(_selectedStageId),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('전투 시작'),
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
