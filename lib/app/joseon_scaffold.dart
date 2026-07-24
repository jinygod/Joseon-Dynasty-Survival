import 'package:flutter/widgets.dart';

class JoseonScaffold extends StatelessWidget {
  const JoseonScaffold({
    required this.body,
    this.topBar,
    this.bottomBar,
    this.background,
    super.key,
  });

  final Widget body;
  final Widget? topBar;
  final Widget? bottomBar;
  final Widget? background;

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: Column(
        children: [
          if (topBar != null) topBar!,
          Expanded(child: body),
          if (bottomBar != null) bottomBar!,
        ],
      ),
    );

    if (background == null) {
      return content;
    }

    return Stack(fit: StackFit.expand, children: [background!, content]);
  }
}
