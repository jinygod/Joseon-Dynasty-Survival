import 'package:flutter/material.dart';

import '../game/content/asset_catalog.dart';
import 'lobby_asset_frame.dart';

/// The compact release-lobby status strip for profile, resources and commands.
class LobbyStatusBar extends StatelessWidget {
  const LobbyStatusBar({
    required this.coin,
    required this.spiritJade,
    required this.trainingRank,
    required this.premiumEntry,
    required this.onSettings,
    super.key,
  });

  final int coin;
  final int spiritJade;
  final String trainingRank;
  final Widget premiumEntry;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      height: 56,
      width: constraints.maxWidth,
      child: Row(
        children: [
          const SizedBox(width: 56, child: _ProfileFrame()),
          const SizedBox(width: 4),
          Expanded(
            child: _ResourceFrame(
              coin: coin,
              spiritJade: spiritJade,
              trainingRank: trainingRank,
            ),
          ),
          const SizedBox(width: 4),
          ConstrainedBox(
            key: const Key('lobby-premium-entry'),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: SizedBox(width: 48, height: 48, child: premiumEntry),
          ),
          const SizedBox(width: 4),
          LobbyAssetButton(
            debugId: 'lobby-settings',
            semanticLabel: '\uc124\uc815',
            frameAsset: AssetCatalog.lobbyFrames['side_command']!,
            onPressed: onSettings,
            child: Image.asset(
              AssetCatalog.lobbyIcons['settings']!,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ProfileFrame extends StatelessWidget {
  const _ProfileFrame();

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        AssetCatalog.lobbyFrames['profile']!,
        key: const Key('lobby-profile-frame'),
        fit: BoxFit.fill,
      ),
      const Center(child: Icon(Icons.person_outline, color: Colors.white)),
    ],
  );
}

class _ResourceFrame extends StatelessWidget {
  const _ResourceFrame({
    required this.coin,
    required this.spiritJade,
    required this.trainingRank,
  });

  final int coin;
  final int spiritJade;
  final String trainingRank;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        AssetCatalog.lobbyFrames['resource']!,
        key: const Key('lobby-resource-frame'),
        fit: BoxFit.fill,
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            _ValueSlot(value: trainingRank),
            _ValueSlot(value: '$coin'),
            _ValueSlot(value: '$spiritJade'),
          ],
        ),
      ),
    ],
  );
}

class _ValueSlot extends StatelessWidget {
  const _ValueSlot({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.center,
      child: Text(
        value,
        maxLines: 1,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
