import 'package:flutter/material.dart';

import '../game/content/asset_catalog.dart';

/// The single illustrated backdrop for the release lobby.
class LobbyScene extends StatelessWidget {
  const LobbyScene({
    required this.characterId,
    required this.foreground,
    super.key,
  });

  final String characterId;
  final Widget foreground;

  @override
  Widget build(BuildContext context) {
    final characterAsset =
        AssetCatalog.lobbyCharacters[characterId] ??
        AssetCatalog.lobbyCharacters['rookie_constable']!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final characterHeight = (constraints.maxHeight * .52).clamp(
          48.0,
          constraints.maxHeight * .56,
        );
        return Stack(
          key: const Key('lobby-scene-stack'),
          fit: StackFit.expand,
          children: [
            Image.asset(
              AssetCatalog.lobbyScene['night_palace_landscape']!,
              key: const Key('lobby-scene-background'),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
            const DecoratedBox(
              key: Key('lobby-scene-edge-gradient'),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0x66020a16),
                    Color(0x08020a16),
                    Color(0x08020a16),
                    Color(0x66020a16),
                  ],
                ),
              ),
            ),
            Align(
              key: const Key('lobby-character-shadow'),
              alignment: const Alignment(0, .52),
              child: Image.asset(
                AssetCatalog.lobbyScene['character_shadow']!,
                width: characterHeight * .88,
                fit: BoxFit.contain,
              ),
            ),
            Align(
              key: const Key('lobby-character-art'),
              alignment: const Alignment(0, .25),
              child: SizedBox(
                height: characterHeight,
                child: Image.asset(
                  characterAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            KeyedSubtree(
              key: const Key('lobby-scene-foreground'),
              child: foreground,
            ),
          ],
        );
      },
    );
  }
}
