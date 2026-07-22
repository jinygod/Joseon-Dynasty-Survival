import 'package:flutter/material.dart';

import 'joseon_ui_theme.dart';

/// A tactile, raised button with a visible lower depth layer.
class JoseonGameButton extends StatefulWidget {
  const JoseonGameButton({
    required this.debugId,
    required this.onPressed,
    required this.semanticLabel,
    required this.minimumSize,
    required this.child,
    this.faceGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xff3b806e), JoseonUiTheme.jade],
    ),
    this.depthColor = const Color(0xff12473c),
    this.borderColor = JoseonUiTheme.gold,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    super.key,
  });

  final String debugId;
  final VoidCallback onPressed;
  final Gradient faceGradient;
  final Color depthColor;
  final Color borderColor;
  final BorderRadius borderRadius;
  final Size minimumSize;
  final String semanticLabel;
  final Widget child;

  @override
  State<JoseonGameButton> createState() => _JoseonGameButtonState();
}

class _JoseonGameButtonState extends State<JoseonGameButton> {
  static const _pressDepth = 4.0;

  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final targetSize = Size(
      widget.minimumSize.width < 64 ? 64 : widget.minimumSize.width,
      widget.minimumSize.height < 72 ? 72 : widget.minimumSize.height,
    );
    final faceHeight = targetSize.height - _pressDepth;
    final pressOffset = faceHeight > 0 ? _pressDepth / faceHeight : 0.0;

    return SizedBox(
      width: targetSize.width,
      height: targetSize.height,
      child: Semantics(
        button: true,
        label: widget.semanticLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: widget.onPressed,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                top: _pressDepth,
                child: DecoratedBox(
                  key: Key('${widget.debugId}-depth'),
                  decoration: BoxDecoration(
                    color: widget.depthColor,
                    borderRadius: widget.borderRadius,
                    border: Border.all(color: widget.borderColor, width: 2),
                  ),
                ),
              ),
              Positioned.fill(
                bottom: _pressDepth,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 70),
                  curve: Curves.easeOut,
                  offset: Offset(0, _pressed ? pressOffset : 0),
                  child: DecoratedBox(
                    key: Key('${widget.debugId}-face'),
                    decoration: BoxDecoration(
                      gradient: widget.faceGradient,
                      borderRadius: widget.borderRadius,
                      border: Border.all(color: widget.borderColor, width: 2),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 3,
                          left: 8,
                          right: 8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: const Color(0x66ffffff),
                            ),
                            child: const SizedBox(height: 2),
                          ),
                        ),
                        Center(child: widget.child),
                      ],
                    ),
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
