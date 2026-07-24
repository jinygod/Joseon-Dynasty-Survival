import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/joseon_buttons.dart';
import 'package:pixel_survivor/app/joseon_panel.dart';
import 'package:pixel_survivor/app/run_summary_screen.dart';
import 'package:pixel_survivor/app/weapon_star_rating.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/models/run_outcome.dart';
import 'package:pixel_survivor/game/models/run_result.dart';
import 'package:pixel_survivor/game/systems/progression_system.dart';

void main() {
  testWidgets('summary uses shared surface and keeps navigation callbacks', (
    tester,
  ) async {
    var starts = 0;
    var menus = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: RunSummaryScreen(
          result: const RunResult(
            outcome: RunOutcome.defeat,
            survivalSeconds: 75,
            kills: 119,
            level: 6,
            bossDefeated: false,
            wonWithLowHealth: false,
            weaponKillCounts: {},
            weaponLevels: {},
          ),
          unlocks: const ProgressionUnlocks(),
          onStart: () => starts += 1,
          onMenu: () => menus += 1,
        ),
      ),
    );

    expect(find.byType(JoseonPanel), findsOneWidget);
    expect(find.byType(JoseonPrimaryButton), findsOneWidget);
    expect(find.byType(JoseonSecondaryButton), findsOneWidget);
    await tester.tap(find.byKey(const Key('result-retry')));
    expect(starts, 1);
    await tester.tap(find.byKey(const Key('result-menu')));
    expect(menus, 0);
  });

  testWidgets('level six weapon result renders mastery stars and metrics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RunSummaryScreen(
          result: const RunResult(
            outcome: RunOutcome.defeat,
            survivalSeconds: 75,
            kills: 119,
            level: 6,
            bossDefeated: false,
            wonWithLowHealth: false,
            weaponKillCounts: {hwandoSlash: 87},
            weaponLevels: {hwandoSlash: 6},
            weaponDamageTotals: {hwandoSlash: 4200},
          ),
          unlocks: const ProgressionUnlocks(),
          onStart: () {},
          onMenu: () {},
        ),
      ),
    );

    expect(find.byType(WeaponStarRating), findsOneWidget);
    expect(find.byKey(const Key('filled-star-4')), findsOneWidget);
    expect(find.byKey(const Key('filled-star-5')), findsNothing);
    expect(find.text('통달'), findsOneWidget);
    expect(find.textContaining('4200'), findsOneWidget);
    expect(find.textContaining('87'), findsOneWidget);
  });
}
