import 'package:flutter/material.dart';

import '../game/content/asset_catalog.dart';
import 'lobby_asset_frame.dart';

/// The five persistent growth shortcuts shown above primary navigation.
class LobbyQuickActions extends StatelessWidget {
  const LobbyQuickActions({
    required this.onGrowth,
    required this.onWeapon,
    required this.onRelic,
    required this.onCompanion,
    required this.onCrafting,
    super.key,
  });

  final VoidCallback onGrowth;
  final VoidCallback onWeapon;
  final VoidCallback onRelic;
  final VoidCallback onCompanion;
  final VoidCallback onCrafting;

  @override
  Widget build(BuildContext context) {
    const actions = [
      ('growth', '\uc131\uc7a5', 'growth'),
      ('weapon', '\ubb34\uae30', 'weapon'),
      ('relic', '\uc720\ubb3c', 'relic'),
      ('companion', '\ub3d9\ub8cc', 'companion'),
      ('crafting', '\uc81c\uc791', 'crafting'),
    ];
    final callbacks = [onGrowth, onWeapon, onRelic, onCompanion, onCrafting];
    return SingleChildScrollView(
      key: const Key('lobby-quick-actions'),
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < actions.length; index++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _QuickActionButton(
                id: actions[index].$1,
                label: actions[index].$2,
                iconAsset: AssetCatalog.lobbyIcons[actions[index].$3]!,
                onPressed: callbacks[index],
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.id,
    required this.label,
    required this.iconAsset,
    required this.onPressed,
  });

  final String id;
  final String label;
  final String iconAsset;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => LobbyAssetButton(
    debugId: 'lobby-quick-$id',
    semanticLabel: label,
    frameAsset: AssetCatalog.lobbyFrames['quick_action']!,
    minimumSize: const Size(68, 68),
    onPressed: onPressed,
    child: Padding(
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
        ],
      ),
    ),
  );
}
