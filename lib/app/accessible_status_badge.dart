import 'package:flutter/material.dart';

class AccessibleStatusBadge extends StatelessWidget {
  const AccessibleStatusBadge({
    required this.icon,
    required this.label,
    this.semanticsLabel,
    this.foregroundColor,
    this.backgroundColor,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? semanticsLabel;
  final Color? foregroundColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = foregroundColor ?? scheme.onSurface;
    return Semantics(
      label: semanticsLabel ?? label,
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor ?? scheme.surfaceContainerHighest,
          border: Border.all(color: foreground, width: 1.5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
