import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'joseon_game_button.dart';
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
      semanticLabel: '설정',
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
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: 260, child: titlePlaque),
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
  Widget build(BuildContext context) {
    return Container(
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
  Widget build(BuildContext context) {
    return DecoratedBox(
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
            const _ResourceMedal(
              icon: Icons.military_tech_outlined,
              label: '수련 단계 0',
              color: JoseonUiTheme.crimson,
            ),
            const SizedBox(width: 7),
            _ResourceMedal(
              icon: Icons.paid_outlined,
              label: '엽전 $coin',
              color: JoseonUiTheme.gold,
            ),
            const SizedBox(width: 7),
            _ResourceMedal(
              icon: Icons.diamond_outlined,
              label: '혼옥 $spiritJade',
              color: JoseonUiTheme.jade,
            ),
            const SizedBox(width: 7),
            premiumEntry,
          ],
        ),
      ),
    );
  }
}

class _ResourceMedal extends StatelessWidget {
  const _ResourceMedal({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.fromLTRB(5, 3, 10, 3),
      decoration: BoxDecoration(
        color: const Color(0xff171a20),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: const Color(0xffffe4a0), width: 1.5),
            ),
            child: Icon(icon, color: JoseonUiTheme.ink, size: 18),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              fontFamily: JoseonUiTheme.bodyFontFamily,
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
