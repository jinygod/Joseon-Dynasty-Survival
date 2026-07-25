import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/lobby_feature_notice.dart';

void main() {
  test('resolves the approved copy for every lobby feature', () {
    const cases = <(
      LobbyFeature,
      String,
      String,
    )>[
      (LobbyFeature.mail, '전령의 소식', '전령이 새로운 소식을 모으고 있습니다.'),
      (LobbyFeature.mission, '임무서', '관아에서 오늘의 임무서를 정리하고 있습니다.'),
      (LobbyFeature.pass, '승급 준비', '새 승급 보상이 도착할 때까지 잠시 기다려 주십시오.'),
      (LobbyFeature.package, '보급품', '상단이 새로운 보급품을 들여오고 있습니다.'),
      (LobbyFeature.ranking, '무예 명부', '전국의 무예 기록을 한데 모으고 있습니다.'),
      (LobbyFeature.relic, '봉인된 유물', '감정이 끝난 유물부터 차례로 공개됩니다.'),
      (LobbyFeature.companion, '인연', '함께 싸울 인연을 찾고 있습니다.'),
      (LobbyFeature.crafting, '대장간', '대장간의 화로를 달구고 있습니다.'),
      (LobbyFeature.challenge, '봉인된 시련', '봉인된 시련의 문이 아직 열리지 않았습니다.'),
    ];

    for (final entry in cases) {
      final copy = copyForLobbyFeature(entry.$1);
      expect(copy.title, entry.$2);
      expect(copy.body, entry.$3);
    }
  });

  testWidgets('crafting opens the approved forge notice and dismisses', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _NoticeHarness()));
    await tester.tap(find.byKey(const Key('open-crafting-notice')));
    await tester.pumpAndSettle();

    expect(find.text('대장간'), findsOneWidget);
    expect(find.text('대장간의 화로를 달구고 있습니다.'), findsOneWidget);
    expect(find.byKey(const Key('lobby-feature-notice')), findsOneWidget);

    await tester.tap(find.byKey(const Key('lobby-feature-notice-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lobby-feature-notice')), findsNothing);
  });
}

class _NoticeHarness extends StatelessWidget {
  const _NoticeHarness();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GestureDetector(
          key: const Key('open-crafting-notice'),
          onTap: () => showLobbyFeatureNotice(context, LobbyFeature.crafting),
          child: const Text('제작'),
        ),
      ),
    );
  }
}
