import 'package:flutter/material.dart';

import '../game/content/asset_catalog.dart';
import 'lobby_asset_frame.dart';

/// The primary destinations for the landscape lobby.
class LobbyPrimaryNavigation extends StatelessWidget {
  const LobbyPrimaryNavigation({
    required this.onLobby,
    required this.onCharacter,
    required this.onCombat,
    required this.onChallenge,
    required this.onShop,
    super.key,
  });

  final VoidCallback onLobby;
  final VoidCallback onCharacter;
  final VoidCallback onCombat;
  final VoidCallback onChallenge;
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    const actions = [
      ('lobby', '\ub85c\ube44', 'compendium', true),
      ('character', '\uc778\ubb3c', 'character', false),
      ('combat', '\uc804\ud22c', 'combat', false),
      ('challenge', '\ub3c4\uc804', 'challenge', false),
      ('shop', '\uc0c1\uc810', 'shop', false),
    ];
    final callbacks = [onLobby, onCharacter, onCombat, onChallenge, onShop];
    return SingleChildScrollView(
      key: const Key('lobby-primary-navigation'),
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < actions.length; index++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _PrimaryNavigationButton(
                id: actions[index].$1,
                label: actions[index].$2,
                iconAsset: AssetCatalog.lobbyIcons[actions[index].$3]!,
                selected: actions[index].$4,
                emphasized: actions[index].$1 == 'combat',
                onPressed: callbacks[index],
              ),
            ),
        ],
      ),
    );
  }
}

class _PrimaryNavigationButton extends StatelessWidget {
  const _PrimaryNavigationButton({
    required this.id,
    required this.label,
    required this.iconAsset,
    required this.selected,
    required this.emphasized,
    required this.onPressed,
  });

  final String id;
  final String label;
  final String iconAsset;
  final bool selected;
  final bool emphasized;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final size = emphasized ? const Size(88, 82) : const Size(66, 66);
    return LobbyAssetButton(
      debugId: 'lobby-primary-$id',
      semanticLabel: label,
      frameAsset: AssetCatalog.lobbyFrames['primary_navigation']!,
      minimumSize: size,
      onPressed: onPressed,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (selected)
            Image.asset(
              AssetCatalog.lobbyFrames['quick_action']!,
              key: Key('lobby-primary-$id-active-frame'),
              fit: BoxFit.fill,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: Image.asset(iconAsset, fit: BoxFit.contain)),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xffffe6a7),
                    fontFamily: 'GowunBatang',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (selected)
                  const Text(
                    '\ud604\uc7ac',
                    maxLines: 1,
                    style: TextStyle(
                      color: Color(0xffffe6a7),
                      fontFamily: 'GowunBatang',
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
