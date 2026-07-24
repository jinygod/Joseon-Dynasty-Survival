import 'package:flutter/material.dart';
import 'package:pixel_survivor/app/joseon_ui_theme.dart';

class JoseonCodexCard extends StatelessWidget {
  const JoseonCodexCard({
    super.key,
    required this.title,
    required this.description,
    required this.locked,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String description;
  final bool locked;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: locked ? '잠긴 항목, 잠김' : title,
    enabled: !locked,
    button: onTap != null,
    excludeSemantics: true,
    child: InkWell(
      onTap: locked ? null : onTap,
      borderRadius: JoseonUiTheme.panelRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: JoseonUiTheme.ivory,
          borderRadius: JoseonUiTheme.panelRadius,
          border: Border.all(
            color: locked ? JoseonUiTheme.danger : JoseonUiTheme.unlocked,
            width: JoseonUiTheme.panelBorderWidth,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(JoseonUiTheme.compactSpacing),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: JoseonUiTheme.compactSpacing),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: JoseonUiTheme.displayStyle),
                    const SizedBox(height: 4),
                    Text(description),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (locked)
                const Icon(Icons.lock, color: JoseonUiTheme.danger),
            ],
          ),
        ),
      ),
    ),
  );
}
