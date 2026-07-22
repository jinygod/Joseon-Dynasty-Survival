import 'package:flutter/material.dart';

import 'joseon_game_button.dart';
import 'joseon_ui_theme.dart';

/// The shared lobby navigation actions, without taking ownership of navigation.
class LobbyNavigationDock extends StatelessWidget {
  const LobbyNavigationDock({
    required this.onStagePressed,
    required this.onCharacterPressed,
    required this.onCompendiumPressed,
    required this.onRecordsPressed,
    super.key,
  });

  final VoidCallback onStagePressed;
  final VoidCallback onCharacterPressed;
  final VoidCallback onCompendiumPressed;
  final VoidCallback onRecordsPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff24243f), Color(0xff33251f)],
        ),
        border: Border(top: BorderSide(color: JoseonUiTheme.gold, width: 3)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: Row(
            children: [
              _DockItem(
                debugId: 'lobby-stage',
                icon: Icons.map_outlined,
                label: '지도',
                medalColor: JoseonUiTheme.jade,
                onPressed: onStagePressed,
              ),
              _DockItem(
                debugId: 'lobby-character',
                icon: Icons.person_outline,
                label: '인물',
                medalColor: JoseonUiTheme.crimson,
                onPressed: onCharacterPressed,
              ),
              _DockItem(
                debugId: 'lobby-compendium',
                icon: Icons.menu_book_outlined,
                label: '도감',
                medalColor: const Color(0xff536fa8),
                onPressed: onCompendiumPressed,
              ),
              _DockItem(
                debugId: 'lobby-records',
                icon: Icons.emoji_events_outlined,
                label: '기록',
                medalColor: const Color(0xff9b6a34),
                onPressed: onRecordsPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.debugId,
    required this.icon,
    required this.label,
    required this.medalColor,
    required this.onPressed,
  });

  final String debugId;
  final IconData icon;
  final String label;
  final Color medalColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: JoseonGameButton(
          key: Key(debugId),
          debugId: debugId,
          semanticLabel: label,
          minimumSize: const Size(64, 72),
          onPressed: onPressed,
          faceGradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [medalColor.withValues(alpha: .96), medalColor],
          ),
          depthColor: Color.alphaBlend(const Color(0x77000000), medalColor),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 27,
                height: 27,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: JoseonUiTheme.paper,
                  border: Border.fromBorderSide(
                    BorderSide(color: JoseonUiTheme.gold, width: 2),
                  ),
                ),
                child: Icon(icon, size: 17, color: JoseonUiTheme.ink),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: JoseonUiTheme.bodyFontFamily,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
