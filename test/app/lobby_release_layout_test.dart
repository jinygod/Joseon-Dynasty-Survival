import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/joseon_ui_theme.dart';
import 'package:pixel_survivor/app/lobby_battle_stage.dart';
import 'package:pixel_survivor/app/lobby_primary_navigation.dart';
import 'package:pixel_survivor/app/lobby_quick_actions.dart';
import 'package:pixel_survivor/app/lobby_scene.dart';
import 'package:pixel_survivor/app/lobby_side_menu.dart';
import 'package:pixel_survivor/app/lobby_status_bar.dart';
import 'package:pixel_survivor/game/content/asset_catalog.dart';
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

  testWidgets('side menu actions expose Korean labels and forward callbacks', (
    tester,
  ) async {
    final taps = <String, int>{};
    final actions = [
      ('mail', '\uc6b0\ud3b8', AssetCatalog.lobbyIcons['mail']!),
      ('mission', '\uc784\ubb34', AssetCatalog.lobbyIcons['mission']!),
      ('pass', '\ud328\uc2a4', AssetCatalog.lobbyIcons['pass']!),
      ('package', '\ubcf4\uad00\ud568', AssetCatalog.lobbyIcons['package']!),
      ('compendium', '\ub3c4\uac10', AssetCatalog.lobbyIcons['compendium']!),
      ('records', '\uae30\ub85d', AssetCatalog.lobbyIcons['records']!),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LobbySideMenu(
            axis: Axis.vertical,
            actions: [
              for (final action in actions)
                LobbyMenuAction(
                  id: action.$1,
                  label: action.$2,
                  iconAsset: action.$3,
                  onPressed: () => taps.update(
                    action.$1,
                    (count) => count + 1,
                    ifAbsent: () => 1,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    final semantics = tester.ensureSemantics();
    for (final action in actions) {
      final button = find.byKey(Key('lobby-side-${action.$1}'));
      expect(button, findsOneWidget);
      expect(
        tester.getSemantics(button),
        matchesSemantics(label: action.$2, isButton: true, hasTapAction: true),
      );
      await tester.tap(button);
      expect(taps[action.$1], 1);
      expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    }
    semantics.dispose();
  });

  testWidgets('quick actions expose Korean labels and forward callbacks', (
    tester,
  ) async {
    final taps = <String, int>{};
    const actions = [
      ('growth', '\uc131\uc7a5'),
      ('weapon', '\ubb34\uae30'),
      ('relic', '\uc720\ubb3c'),
      ('companion', '\ub3d9\ub8cc'),
      ('crafting', '\uc81c\uc791'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LobbyQuickActions(
            onGrowth: () =>
                taps.update('growth', (count) => count + 1, ifAbsent: () => 1),
            onWeapon: () =>
                taps.update('weapon', (count) => count + 1, ifAbsent: () => 1),
            onRelic: () =>
                taps.update('relic', (count) => count + 1, ifAbsent: () => 1),
            onCompanion: () => taps.update(
              'companion',
              (count) => count + 1,
              ifAbsent: () => 1,
            ),
            onCrafting: () => taps.update(
              'crafting',
              (count) => count + 1,
              ifAbsent: () => 1,
            ),
          ),
        ),
      ),
    );

    final semantics = tester.ensureSemantics();
    for (final action in actions) {
      final button = find.byKey(Key('lobby-quick-${action.$1}'));
      expect(button, findsOneWidget);
      expect(
        tester.getSemantics(button),
        matchesSemantics(label: action.$2, isButton: true, hasTapAction: true),
      );
      await tester.tap(button);
      expect(taps[action.$1], 1);
    }
    semantics.dispose();
  });

  testWidgets('primary navigation forwards callbacks and emphasizes combat', (
    tester,
  ) async {
    final taps = <String, int>{};
    const actions = [
      ('lobby', '\ub85c\ube44'),
      ('character', '\uc778\ubb3c'),
      ('combat', '\uc804\ud22c'),
      ('challenge', '\ub3c4\uc804'),
      ('shop', '\uc0c1\uc810'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LobbyPrimaryNavigation(
            onLobby: () =>
                taps.update('lobby', (count) => count + 1, ifAbsent: () => 1),
            onCharacter: () => taps.update(
              'character',
              (count) => count + 1,
              ifAbsent: () => 1,
            ),
            onCombat: () =>
                taps.update('combat', (count) => count + 1, ifAbsent: () => 1),
            onChallenge: () => taps.update(
              'challenge',
              (count) => count + 1,
              ifAbsent: () => 1,
            ),
            onShop: () =>
                taps.update('shop', (count) => count + 1, ifAbsent: () => 1),
          ),
        ),
      ),
    );

    final semantics = tester.ensureSemantics();
    for (final action in actions) {
      final button = find.byKey(Key('lobby-primary-${action.$1}'));
      expect(button, findsOneWidget);
      expect(
        tester.getSemantics(button),
        matchesSemantics(label: action.$2, isButton: true, hasTapAction: true),
      );
      await tester.tap(button);
      expect(taps[action.$1], 1);
    }
    expect(
      tester.getSize(find.byKey(const Key('lobby-primary-combat'))).height,
      greaterThan(
        tester.getSize(find.byKey(const Key('lobby-primary-character'))).height,
      ),
    );
    final activeFrame = tester.widget<Image>(
      find.byKey(const Key('lobby-primary-lobby-active-frame')),
    );
    expect(
      activeFrame.image,
      AssetImage(AssetCatalog.lobbyFrames['quick_action']!),
    );
    semantics.dispose();
  });
}
