import 'package:flutter/material.dart';
import 'package:pixel_survivor/app/joseon_ui_theme.dart';

class JoseonTabBar extends StatelessWidget {
  const JoseonTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: JoseonUiTheme.ivory,
      borderRadius: JoseonUiTheme.compactRadius,
      border: Border.all(
        color: JoseonUiTheme.gold,
        width: JoseonUiTheme.panelBorderWidth,
      ),
    ),
    child: Row(
      children: [
        for (var index = 0; index < labels.length; index++)
          Expanded(
            child: Semantics(
              selected: index == selectedIndex,
              button: true,
              child: TextButton(
                onPressed: () => onChanged(index),
                style: TextButton.styleFrom(
                  backgroundColor: index == selectedIndex
                      ? JoseonUiTheme.navy
                      : Colors.transparent,
                  foregroundColor: index == selectedIndex
                      ? JoseonUiTheme.ivory
                      : JoseonUiTheme.ink,
                  shape: const RoundedRectangleBorder(
                    borderRadius: JoseonUiTheme.compactRadius,
                  ),
                ),
                child: Text(labels[index]),
              ),
            ),
          ),
      ],
    ),
  );
}
