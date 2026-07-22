import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/level_up_overlay.dart';
import 'package:pixel_survivor/game/systems/level_up_system.dart';

void main() {
  const choices = <LevelUpChoice>[
    LevelUpChoice(
      id: 'long_weapon',
      displayName: '바람을 가르는 긴 이름의 환도',
      effectDescription: '두 번 연속 베고 마지막 검기가 주변의 표식까지 폭발시킵니다.',
      type: LevelUpChoiceType.weapon,
      currentLevel: 2,
      nextLevel: 3,
    ),
    LevelUpChoice(
      id: 'long_augment',
      displayName: '외공력 갑옷',
      effectDescription: '받는 피해가 감소하고 밀려나는 거리가 줄어들어 전열을 유지합니다.',
      type: LevelUpChoiceType.augment,
      currentLevel: 0,
      nextLevel: 1,
    ),
    LevelUpChoice(
      id: 'long_powder',
      displayName: '고화력 화약통',
      effectDescription: '폭발 범위가 넓어지고 결계 안의 적에게 추가 연쇄 폭발을 일으킵니다.',
      type: LevelUpChoiceType.augment,
      currentLevel: 4,
      nextLevel: 5,
    ),
  ];

  testWidgets('portrait choices use wide cards and show complete Korean copy', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    LevelUpChoice? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: LevelUpOverlay(
          choices: choices,
          onChoiceSelected: (choice) => selected = choice,
        ),
      ),
    );

    expect(find.byKey(const Key('level-up-title')), findsOneWidget);
    for (var index = 0; index < choices.length; index += 1) {
      expect(find.text(choices[index].displayName), findsOneWidget);
      expect(find.text(choices[index].effectDescription), findsOneWidget);
      expect(
        tester.getSize(find.byKey(Key('level-up-choice-$index'))).width,
        greaterThan(300),
      );
    }
    await tester.tap(find.byKey(const Key('level-up-choice-1')));
    expect(selected, choices[1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide choices remain in one three-card row', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(844, 390);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: LevelUpOverlay(choices: choices, onChoiceSelected: (_) {}),
      ),
    );

    final tops = [
      for (var index = 0; index < choices.length; index += 1)
        tester.getTopLeft(find.byKey(Key('level-up-choice-$index'))).dy,
    ];
    expect(tops.toSet(), hasLength(1));
    expect(tester.takeException(), isNull);
  });
}
