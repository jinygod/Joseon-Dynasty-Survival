import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/run_summary_screen.dart';
import 'package:pixel_survivor/game/content/augment_definitions.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/models/run_outcome.dart';
import 'package:pixel_survivor/game/models/run_feedback.dart';
import 'package:pixel_survivor/game/models/run_result.dart';
import 'package:pixel_survivor/game/systems/progression_system.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';

void main() {
  test('applies run result statistics and evaluates unlocks', () {
    final save = SaveState.defaults().copyWith(
      bestSurvivalSeconds: 90,
      totalKills: 250,
      levelReachedInRun: 7,
    );
    const result = RunResult(
      outcome: RunOutcome.defeat,
      survivalSeconds: 240,
      kills: 80,
      level: 12,
      bossDefeated: true,
      wonWithLowHealth: false,
      weaponKillCounts: {hwandoSlash: 50, gakgungShot: 30},
      weaponLevels: {},
    );

    final updated = const ProgressionSystem().applyRunResult(save, result);

    expect(updated.bestSurvivalSeconds, 240);
    expect(updated.totalKills, 330);
    expect(updated.levelReachedInRun, 12);
    expect(updated.bossDefeats, 1);
    expect(updated.lowHealthWinCount, 0);
    expect(updated.unlockedCharacterIds, contains(exorcistDosa));
    expect(
      updated.unlockedWeaponIds,
      containsAll([talismanThrow, jangseungWard]),
    );
    expect(updated.unlockedAugmentIds, contains(rapidReload));
  });

  test('keeps best run metrics when a shorter lower-level run is applied', () {
    final save = SaveState.defaults().copyWith(
      bestSurvivalSeconds: 300,
      totalKills: 20,
      levelReachedInRun: 15,
      bossDefeats: 2,
    );
    const result = RunResult(
      outcome: RunOutcome.defeat,
      survivalSeconds: 120,
      kills: 10,
      level: 8,
      bossDefeated: false,
      wonWithLowHealth: false,
      weaponKillCounts: {},
      weaponLevels: {},
    );

    final updated = const ProgressionSystem().applyRunResult(save, result);

    expect(updated.bestSurvivalSeconds, 300);
    expect(updated.totalKills, 30);
    expect(updated.levelReachedInRun, 15);
    expect(updated.bossDefeats, 2);
  });

  test('low health win unlocks last stand', () {
    const result = RunResult(
      outcome: RunOutcome.defeat,
      survivalSeconds: 60,
      kills: 5,
      level: 2,
      bossDefeated: false,
      wonWithLowHealth: true,
      weaponKillCounts: {},
      weaponLevels: {},
    );

    final updated = const ProgressionSystem().applyRunResult(
      SaveState.defaults(),
      result,
    );

    expect(updated.lowHealthWinCount, 1);
    expect(updated.unlockedAugmentIds, contains(lastStand));
  });

  test('diff contains only newly unlocked content ids', () {
    final before = SaveState.defaults().copyWith(
      unlockedWeaponIds: {hwandoSlash, gakgungShot, talismanThrow},
    );
    final after = before.copyWith(
      unlockedCharacterIds: {rookieConstable, exorcistDosa},
      unlockedWeaponIds: {
        hwandoSlash,
        gakgungShot,
        talismanThrow,
        thunderCrashBomb,
      },
      unlockedAugmentIds: {martialTraining, quickStep, rapidReload, lastStand},
    );

    final unlocks = ProgressionUnlocks.diff(before, after);

    expect(unlocks.characterIds, [exorcistDosa]);
    expect(unlocks.weaponIds, [thunderCrashBomb]);
    expect(unlocks.augmentIds, [lastStand, rapidReload]);
    expect(unlocks.isEmpty, isFalse);
  });

  test('run result exposes explicit victory outcome and weapon levels', () {
    const result = RunResult(
      outcome: RunOutcome.victory,
      survivalSeconds: 300,
      kills: 100,
      level: 10,
      bossDefeated: true,
      wonWithLowHealth: false,
      weaponKillCounts: {},
      weaponLevels: {hwandoSlash: 5},
    );

    expect(result.outcome, RunOutcome.victory);
    expect(result.weaponLevels[hwandoSlash], 5);
  });

  testWidgets('run summary shows stats and newly unlocked ids', (tester) async {
    const result = RunResult(
      outcome: RunOutcome.victory,
      survivalSeconds: 125,
      kills: 42,
      level: 6,
      bossDefeated: true,
      wonWithLowHealth: false,
      weaponKillCounts: {},
      weaponLevels: {},
    );
    const unlocks = ProgressionUnlocks(
      characterIds: [exorcistDosa],
      weaponIds: [talismanThrow],
      augmentIds: [lastStand],
    );
    var started = false;
    var openedMenu = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: RunSummaryScreen(
          result: result,
          unlocks: unlocks,
          onStart: () => started = true,
          onMenu: () => openedMenu = true,
        ),
      ),
    );

    expect(find.text('02:05'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('퇴마 도사'), findsOneWidget);
    expect(find.text('부적 투척'), findsOneWidget);
    expect(find.text('최후의 저항'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '다시 시작'));
    await tester.tap(find.widgetWithText(OutlinedButton, '메인 메뉴'));

    expect(started, isTrue);
    expect(openedMenu, isFalse);
  });

  testWidgets('result navigation commits only the first rapid action', (
    tester,
  ) async {
    const result = RunResult(
      outcome: RunOutcome.defeat,
      survivalSeconds: 90,
      kills: 10,
      level: 3,
      bossDefeated: false,
      wonWithLowHealth: false,
      weaponKillCounts: {},
      weaponLevels: {},
    );
    var retries = 0;
    var menus = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: RunSummaryScreen(
          result: result,
          unlocks: const ProgressionUnlocks(),
          onStart: () => retries += 1,
          onMenu: () => menus += 1,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('result-retry')));
    await tester.tap(find.byKey(const Key('result-retry')));
    await tester.tap(find.byKey(const Key('result-menu')));
    await tester.pump();

    expect(retries, 1);
    expect(menus, 0);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('result-retry')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('result-menu')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('menu double tap cannot trigger retry', (tester) async {
    const result = RunResult(
      outcome: RunOutcome.victory,
      survivalSeconds: 300,
      kills: 80,
      level: 10,
      bossDefeated: true,
      wonWithLowHealth: false,
      weaponKillCounts: {},
      weaponLevels: {},
    );
    var retries = 0;
    var menus = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: RunSummaryScreen(
          result: result,
          unlocks: const ProgressionUnlocks(),
          onStart: () => retries += 1,
          onMenu: () => menus += 1,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('result-menu')));
    await tester.tap(find.byKey(const Key('result-menu')));
    await tester.tap(find.byKey(const Key('result-retry')));

    expect(menus, 1);
    expect(retries, 0);
  });

  testWidgets('victory summary shows boss result and final build', (
    tester,
  ) async {
    const result = RunResult(
      outcome: RunOutcome.victory,
      survivalSeconds: 301,
      kills: 96,
      level: 11,
      bossDefeated: true,
      wonWithLowHealth: false,
      weaponKillCounts: {},
      weaponLevels: {hwandoSlash: 5, gakgungShot: 3},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RunSummaryScreen(
          result: result,
          unlocks: const ProgressionUnlocks(),
          onStart: () {},
          onMenu: () {},
        ),
      ),
    );

    expect(find.text('승리'), findsOneWidget);
    expect(find.text('보스 처치'), findsOneWidget);
    expect(find.text('환도 베기'), findsOneWidget);
    expect(find.textContaining('레벨 5'), findsOneWidget);
    expect(find.text('각궁 사격'), findsOneWidget);
    expect(find.textContaining('레벨 3'), findsOneWidget);
  });

  testWidgets('defeat summary distinguishes an unfinished boss fight', (
    tester,
  ) async {
    const result = RunResult(
      outcome: RunOutcome.defeat,
      survivalSeconds: 285,
      kills: 72,
      level: 9,
      bossDefeated: false,
      wonWithLowHealth: false,
      weaponKillCounts: {},
      weaponLevels: {hwandoSlash: 4},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RunSummaryScreen(
          result: result,
          unlocks: const ProgressionUnlocks(),
          onStart: () {},
          onMenu: () {},
        ),
      ),
    );

    expect(find.text('패배'), findsOneWidget);
    expect(find.text('보스 미처치'), findsOneWidget);
    expect(find.text('04:45'), findsOneWidget);
  });

  testWidgets('summary shows weapon level damage and kills', (tester) async {
    const result = RunResult(
      outcome: RunOutcome.victory,
      survivalSeconds: 300,
      kills: 52,
      level: 10,
      bossDefeated: true,
      wonWithLowHealth: false,
      weaponKillCounts: {hwandoSlash: 42, gakgungShot: 10},
      weaponLevels: {hwandoSlash: 5, gakgungShot: 3},
      weaponDamageTotals: {hwandoSlash: 1234.6, gakgungShot: 500},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RunSummaryScreen(
          result: result,
          unlocks: const ProgressionUnlocks(),
          onStart: () {},
          onMenu: () {},
        ),
      ),
    );

    expect(find.text('환도 베기'), findsOneWidget);
    expect(find.text('레벨 5 · 피해 1235 · 처치 42'), findsOneWidget);
    expect(find.text('각궁 사격'), findsOneWidget);
    expect(find.text('레벨 3 · 피해 500 · 처치 10'), findsOneWidget);
  });

  testWidgets('feedback requires structured answers and submits exact values', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1600);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    RunFeedback? submitted;
    const result = RunResult(
      outcome: RunOutcome.defeat,
      survivalSeconds: 180,
      kills: 50,
      level: 6,
      bossDefeated: false,
      wonWithLowHealth: false,
      weaponKillCounts: {},
      weaponLevels: {},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: RunSummaryScreen(
          result: result,
          unlocks: const ProgressionUnlocks(),
          onStart: () {},
          onMenu: () {},
          onFeedbackSubmitted: (feedback) async => submitted = feedback,
        ),
      ),
    );
    final submitFinder = find.byKey(const Key('feedback-submit'));
    await tester.ensureVisible(submitFinder);

    expect(tester.widget<FilledButton>(submitFinder).onPressed, isNull);
    await tester.tap(find.byKey(const Key('fun-rating-4')));
    await tester.tap(find.byKey(const Key('difficulty-rating-3')));
    await tester.tap(find.byKey(const Key('retry-yes')));
    await tester.enterText(
      find.byKey(const Key('feedback-comment')),
      '  보스가 재미있음  ',
    );
    await tester.pump();
    await tester.ensureVisible(submitFinder);
    await tester.tap(submitFinder);
    await tester.pump();

    expect(submitted?.funRating, 4);
    expect(submitted?.difficultyRating, 3);
    expect(submitted?.retryIntent, isTrue);
    expect(submitted?.comment, '보스가 재미있음');
    expect(find.text('피드백 저장 완료'), findsOneWidget);
  });

  testWidgets('summary copy and export actions report success', (tester) async {
    var copies = 0;
    var exports = 0;
    const result = RunResult(
      outcome: RunOutcome.victory,
      survivalSeconds: 300,
      kills: 100,
      level: 10,
      bossDefeated: true,
      wonWithLowHealth: false,
      weaponKillCounts: {},
      weaponLevels: {},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: RunSummaryScreen(
          result: result,
          unlocks: const ProgressionUnlocks(),
          onStart: () {},
          onMenu: () {},
          onCopyRunJson: () async {
            copies += 1;
            return true;
          },
          onExportAllJson: () async {
            exports += 1;
            return true;
          },
        ),
      ),
    );

    final copyFinder = find.byKey(const Key('copy-run-json'));
    await tester.ensureVisible(copyFinder);
    await tester.tap(copyFinder);
    await tester.pump();
    expect(find.text('이 판 기록을 복사했습니다.'), findsOneWidget);

    final exportFinder = find.byKey(const Key('export-all-json'));
    await tester.ensureVisible(exportFinder);
    await tester.tap(exportFinder);
    await tester.pump();
    expect(find.text('전체 기록 내보내기를 열었습니다.'), findsOneWidget);
    expect(copies, 1);
    expect(exports, 1);
  });
}
