import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'joseon_game_button.dart';
import 'joseon_resource_chip.dart';
import 'joseon_ui_theme.dart';

/// The lobby's title, resources, and primary settings command.
class LobbyTopCommandBar extends StatelessWidget {
  const LobbyTopCommandBar({
    required this.coin,
    required this.spiritJade,
    required this.premiumEntry,
    required this.onSettings,
    super.key,
  });

  final int coin;
  final int spiritJade;
  final Widget premiumEntry;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final titlePlaque = _TitlePlaque();
    final resourceRibbon = _ResourceRibbon(
      coin: coin,
      spiritJade: spiritJade,
      premiumEntry: premiumEntry,
    );
    final settingsButton = JoseonGameButton(
      key: const Key('lobby-settings'),
      debugId: 'lobby-settings',
      semanticLabel: '\uC124\uC815',
      minimumSize: const Size(64, 72),
      borderRadius: BorderRadius.circular(32),
      faceGradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xfffff8e6), Color(0xffd9bd79)],
      ),
      depthColor: const Color(0xff6b452d),
      borderColor: JoseonUiTheme.ink,
      onPressed: onSettings,
      child: const Icon(
        Icons.settings_outlined,
        color: JoseonUiTheme.ink,
        size: 28,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          final titleWidth = constraints.maxWidth > 900 ? 260.0 : 180.0;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: titleWidth, child: titlePlaque),
              const SizedBox(width: 12),
              Expanded(child: resourceRibbon),
              const SizedBox(width: 12),
              settingsButton,
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: titlePlaque),
                const SizedBox(width: 10),
                settingsButton,
              ],
            ),
            const SizedBox(height: 8),
            resourceRibbon,
          ],
        );
      },
    );
  }
}

class _TitlePlaque extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    key: const Key('lobby-title-plaque'),
    constraints: const BoxConstraints(minHeight: 64),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
    decoration: BoxDecoration(
      color: JoseonUiTheme.paper,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      border: Border.all(color: JoseonUiTheme.ink, width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x55000000),
          blurRadius: 7,
          offset: Offset(0, 4),
        ),
        BoxShadow(color: JoseonUiTheme.gold, offset: Offset(0, 3)),
      ],
    ),
    child: const Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          AppStrings.appTitle,
          maxLines: 1,
          style: TextStyle(
            fontFamily: JoseonUiTheme.displayFontFamily,
            color: JoseonUiTheme.ink,
            fontSize: 27,
            letterSpacing: 1.1,
          ),
        ),
      ),
    ),
  );
}

class _ResourceRibbon extends StatelessWidget {
  const _ResourceRibbon({
    required this.coin,
    required this.spiritJade,
    required this.premiumEntry,
  });

  final int coin;
  final int spiritJade;
  final Widget premiumEntry;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const Key('lobby-resource-ribbon'),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xff24243f), Color(0xff352720)],
      ),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: JoseonUiTheme.gold, width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 5,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          const JoseonResourceChip(
            leading: Icon(Icons.military_tech_outlined, size: 18),
            label: '\uC791\uC704',
            value: '0',
          ),
          const SizedBox(width: 7),
          JoseonResourceChip(
            leading: const Icon(Icons.paid_outlined, size: 18),
            label: '\uC5FD\uC804 $coin',
            value: '',
          ),
          const SizedBox(width: 7),
          JoseonResourceChip(
            leading: const Icon(Icons.diamond_outlined, size: 18),
            label: '\uD63C\uC625 $spiritJade',
            value: '',
          ),
          const SizedBox(width: 7),
          premiumEntry,
        ],
      ),
    ),
  );
}
