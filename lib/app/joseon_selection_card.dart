import 'package:flutter/material.dart';
import 'package:pixel_survivor/app/joseon_ui_theme.dart';

class JoseonSelectionCard extends StatelessWidget {
  const JoseonSelectionCard({
    super.key,
    required this.selected,
    required this.locked,
    required this.semanticsLabel,
    required this.child,
    this.onTap,
  });

  final bool selected;
  final bool locked;
  final String semanticsLabel;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticsLabel,
    selected: selected,
    enabled: !locked,
    button: onTap != null,
    excludeSemantics: true,
    child: InkWell(
      onTap: locked ? null : onTap,
      borderRadius: JoseonUiTheme.panelRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: locked
              ? JoseonUiTheme.ivory.withValues(alpha: 0.55)
              : JoseonUiTheme.ivory,
          borderRadius: JoseonUiTheme.panelRadius,
          border: Border.all(
            color: selected ? JoseonUiTheme.gold : JoseonUiTheme.ivory,
            width: selected ? 2 : JoseonUiTheme.panelBorderWidth,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(JoseonUiTheme.compactSpacing),
          child: Stack(
            children: [
              child,
              if (selected)
                const Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(
                    Icons.check_circle,
                    key: Key('selection-check'),
                    color: JoseonUiTheme.gold,
                  ),
                ),
              if (locked)
                const Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(Icons.lock, color: JoseonUiTheme.danger),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
