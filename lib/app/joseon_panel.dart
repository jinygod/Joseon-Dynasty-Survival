import 'package:flutter/material.dart';
import 'package:pixel_survivor/app/joseon_ui_theme.dart';

class JoseonPanel extends StatelessWidget {
  const JoseonPanel({
    super.key,
    required this.child,
    this.padding,
    this.semanticsLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        color: JoseonUiTheme.ivory,
        borderRadius: JoseonUiTheme.panelRadius,
        border: Border.all(
          color: JoseonUiTheme.gold,
          width: JoseonUiTheme.panelBorderWidth,
        ),
      ),
      child: Padding(
        padding:
            padding ?? const EdgeInsets.all(JoseonUiTheme.compactSpacing * 2),
        child: child,
      ),
    );
    return semanticsLabel == null
        ? panel
        : Semantics(label: semanticsLabel, child: panel);
  }
}
