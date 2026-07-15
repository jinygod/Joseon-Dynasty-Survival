import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/run_summary_screen.dart';
import 'package:pixel_survivor/game/models/meta_progress.dart';
import 'package:pixel_survivor/game/models/run_outcome.dart';
import 'package:pixel_survivor/game/models/run_result.dart';
import 'package:pixel_survivor/game/systems/meta_progression_service.dart';
import 'package:pixel_survivor/game/systems/progression_system.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';

void main() {
  testWidgets('summary displays earned coin and spirit jade', (tester) async {
    final before = SaveState.defaults();
    final after = before.copyWith(
      wallet: const Wallet(coin: 123, spiritJade: 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RunSummaryScreen(
          result: const RunResult(
            outcome: RunOutcome.victory,
            survivalSeconds: 300,
            kills: 200,
            level: 10,
            bossDefeated: true,
            wonWithLowHealth: false,
            weaponKillCounts: {},
            weaponLevels: {},
            spiritJadeCollected: 1,
          ),
          unlocks: ProgressionUnlocks.diff(before, after),
          settlement: RunSettlement(
            before: before,
            after: after,
            coinEarned: 123,
            spiritJadeEarned: 1,
          ),
          onStart: () {},
          onMenu: () {},
        ),
      ),
    );

    expect(find.text('이번 판 보상'), findsOneWidget);
    expect(find.text('엽전'), findsOneWidget);
    expect(find.text('+123'), findsOneWidget);
    expect(find.text('혼옥'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
  });
}
