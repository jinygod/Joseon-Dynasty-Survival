import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/joseon_ui_theme.dart';
import 'package:pixel_survivor/app/lobby_battle_stage.dart';
import 'package:pixel_survivor/app/lobby_scene.dart';
import 'package:pixel_survivor/app/lobby_status_bar.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';

void main() {
  testWidgets(
    'status bar keeps resource values, raster frames, and controls accessible',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: JoseonUiTheme.create(),
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: LobbyStatusBar(
                coin: 1200,
                spiritJade: 34,
                trainingRank: '\uac80\uc218',
                premiumEntry: GestureDetector(
                  onTap: () {},
                  child: const Text('\uc81c\ud488 \uc0c1\uc810'),
                ),
                onSettings: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('1200'), findsOneWidget);
      expect(find.text('34'), findsOneWidget);
      expect(find.text('\uac80\uc218'), findsOneWidget);
      expect(find.byKey(const Key('lobby-profile-frame')), findsOneWidget);
      expect(find.byKey(const Key('lobby-resource-frame')), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(const Key('lobby-settings'))),
        matchesSemantics(
          label: '\uc124\uc815',
          isButton: true,
          hasTapAction: true,
        ),
      );

      for (final finder in [
        find.byKey(const Key('lobby-settings')),
        find.descendant(
          of: find.byKey(const Key('lobby-premium-entry')),
          matching: find.byType(GestureDetector),
        ),
      ]) {
        final size = tester.getSize(finder);
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
    },
  );

  testWidgets(
    'scene keeps one backdrop and character ahead of deployment controls',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: JoseonUiTheme.create(),
          home: Scaffold(
            body: SizedBox.expand(
              child: LobbyScene(
                characterId: 'rookie_constable',
                foreground: LobbyBattleStage(
                  characterId: 'rookie_constable',
                  characterName: 'New constable',
                  stage: stageDefinitions.first,
                  bestSeconds: 75,
                  launching: false,
                  saving: false,
                  onDeploy: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('lobby-scene-background')), findsOneWidget);
      expect(find.byKey(const Key('lobby-character-shadow')), findsOneWidget);
      expect(find.byKey(const Key('lobby-character-art')), findsOneWidget);
      expect(find.byKey(const Key('lobby-stage-plaque')), findsOneWidget);
      expect(find.byKey(const Key('lobby-deploy')), findsOneWidget);
      expect(
        find.byKey(const Key('lobby-stage-background-image')),
        findsNothing,
      );

      final stackChildren = tester
          .widget<Stack>(find.byKey(const Key('lobby-scene-stack')))
          .children;
      expect(
        stackChildren.indexWhere(
          (child) => child.key == const Key('lobby-scene-background'),
        ),
        lessThan(
          stackChildren.indexWhere(
            (child) => child.key == const Key('lobby-character-art'),
          ),
        ),
      );
      expect(
        stackChildren.indexWhere(
          (child) => child.key == const Key('lobby-character-art'),
        ),
        lessThan(
          stackChildren.indexWhere(
            (child) => child.key == const Key('lobby-scene-foreground'),
          ),
        ),
      );
    },
  );
}
