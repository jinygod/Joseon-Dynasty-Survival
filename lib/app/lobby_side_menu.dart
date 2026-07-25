import 'package:flutter/material.dart';

import '../game/content/asset_catalog.dart';
import 'lobby_asset_frame.dart';

/// One command displayed in a release-lobby command rail.
class LobbyMenuAction {
  const LobbyMenuAction({
    required this.id,
    required this.label,
    required this.iconAsset,
    required this.onPressed,
  });

  final String id;
  final String label;
  final String iconAsset;
  final VoidCallback onPressed;
}

/// Raster-backed lobby commands arranged as a vertical or compact horizontal rail.
class LobbySideMenu extends StatelessWidget {
  const LobbySideMenu({required this.actions, required this.axis, super.key});

  final List<LobbyMenuAction> actions;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final action in actions)
        Padding(
          padding: const EdgeInsets.all(3),
          child: _LobbySideMenuButton(action: action),
        ),
    ];
    return SingleChildScrollView(
      key: Key('lobby-side-menu-${axis.name}'),
      scrollDirection: axis,
      child: axis == Axis.vertical
          ? Column(mainAxisSize: MainAxisSize.min, children: items)
          : Row(mainAxisSize: MainAxisSize.min, children: items),
    );
  }
}

class _LobbySideMenuButton extends StatelessWidget {
  const _LobbySideMenuButton({required this.action});

  final LobbyMenuAction action;

  @override
  Widget build(BuildContext context) => LobbyAssetButton(
    debugId: 'lobby-side-${action.id}',
    semanticLabel: action.label,
    frameAsset: AssetCatalog.lobbyFrames['side_command']!,
    minimumSize: const Size(64, 64),
    onPressed: action.onPressed,
    child: _LobbyCommandContents(
      label: action.label,
      iconAsset: action.iconAsset,
    ),
  );
}

class _LobbyCommandContents extends StatelessWidget {
  const _LobbyCommandContents({required this.label, required this.iconAsset});

  final String label;
  final String iconAsset;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
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
  );
}
