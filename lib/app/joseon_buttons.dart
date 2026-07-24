import 'package:flutter/material.dart';
import 'package:pixel_survivor/app/joseon_ui_theme.dart';

class JoseonPrimaryButton extends StatelessWidget {
  const JoseonPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => _JoseonButton(
    label: label,
    onPressed: onPressed,
    leading: leading,
    backgroundColor: JoseonUiTheme.navy,
    foregroundColor: JoseonUiTheme.ivory,
    borderColor: JoseonUiTheme.gold,
  );
}

class JoseonSecondaryButton extends StatelessWidget {
  const JoseonSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => _JoseonButton(
    label: label,
    onPressed: onPressed,
    leading: leading,
    backgroundColor: JoseonUiTheme.ivory,
    foregroundColor: JoseonUiTheme.navy,
    borderColor: JoseonUiTheme.gold,
  );
}

class _JoseonButton extends StatelessWidget {
  const _JoseonButton({
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    this.leading,
    this.borderColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Widget? leading;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: JoseonUiTheme.compactSpacing,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: JoseonUiTheme.compactRadius,
        side: BorderSide(
          color: borderColor ?? backgroundColor,
          width: JoseonUiTheme.panelBorderWidth,
        ),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: JoseonUiTheme.compactSpacing),
        ],
        Text(label),
      ],
    ),
  );
}
