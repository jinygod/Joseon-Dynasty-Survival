import 'package:flutter/material.dart';
import 'package:pixel_survivor/app/joseon_ui_theme.dart';

class JoseonResourceChip extends StatelessWidget {
  const JoseonResourceChip({
    super.key,
    required this.label,
    required this.value,
    this.leading,
  });

  final String label;
  final String value;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label $value',
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: JoseonUiTheme.navy,
        borderRadius: JoseonUiTheme.compactRadius,
        border: Border.all(
          color: JoseonUiTheme.gold,
          width: JoseonUiTheme.panelBorderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: JoseonUiTheme.compactSpacing,
          vertical: 4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 4)],
            Text(label, style: const TextStyle(color: JoseonUiTheme.ivory)),
            const SizedBox(width: JoseonUiTheme.compactSpacing),
            Text(
              value,
              style: const TextStyle(
                color: JoseonUiTheme.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
