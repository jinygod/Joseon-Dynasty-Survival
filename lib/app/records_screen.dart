import 'package:flutter/material.dart';

import '../game/systems/save_system.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({required this.state, super.key});

  final SaveState state;

  @override
  Widget build(BuildContext context) {
    final records = <({IconData icon, String label})>[
      (icon: Icons.sports_kabaddi, label: '누적 처치 ${state.totalKills}'),
      (
        icon: Icons.timer_outlined,
        label: '최고 생존 ${_clock(state.bestSurvivalSeconds)}',
      ),
      (icon: Icons.military_tech, label: '보스 격파 ${state.bossDefeats}'),
      (
        icon: Icons.flag_outlined,
        label: '달성 목표 ${state.completedGoalIds.length}',
      ),
      (
        icon: Icons.auto_awesome,
        label: '해금 무기 ${state.unlockedWeaponIds.length}',
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('기록')),
      body: SafeArea(
        child: GridView.count(
          padding: const EdgeInsets.all(24),
          crossAxisCount: MediaQuery.sizeOf(context).width >= 800 ? 3 : 2,
          childAspectRatio: 2.5,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            for (final record in records)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(record.icon, color: const Color(0xff8f2d38)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          record.label,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _clock(int totalSeconds) {
  final minutes = totalSeconds ~/ 60;
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
