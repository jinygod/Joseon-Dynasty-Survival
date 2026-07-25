import 'package:flutter/material.dart';

/// A raster-framed lobby control with a shallow, tactile press response.
class LobbyAssetButton extends StatefulWidget {
  const LobbyAssetButton({
    required this.debugId,
    required this.semanticLabel,
    required this.frameAsset,
    required this.onPressed,
    required this.child,
    this.minimumSize = const Size(48, 48),
    super.key,
  });

  final String debugId;
  final String semanticLabel;
  final String frameAsset;
  final VoidCallback onPressed;
  final Widget child;
  final Size minimumSize;

  @override
  State<LobbyAssetButton> createState() => _LobbyAssetButtonState();
}

class _LobbyAssetButtonState extends State<LobbyAssetButton> {
  static const _pressDepth = 2.0;
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final targetSize = Size(
      widget.minimumSize.width < 48 ? 48 : widget.minimumSize.width,
      widget.minimumSize.height < 48 ? 48 : widget.minimumSize.height,
    );
    final pressOffset = _pressDepth / targetSize.height;

    return SizedBox(
      width: targetSize.width,
      height: targetSize.height,
      child: Semantics(
        key: Key(widget.debugId),
        button: true,
        container: true,
        excludeSemantics: true,
        label: widget.semanticLabel,
        onTap: widget.onPressed,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: widget.onPressed,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: targetSize.width * .72,
                  height: _pressDepth + 3,
                  child: DecoratedBox(
                    key: Key('lobby-asset-button-shadow-${widget.debugId}'),
                    decoration: BoxDecoration(
                      color: const Color(0x99000000),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              AnimatedSlide(
                duration: const Duration(milliseconds: 70),
                curve: Curves.easeOut,
                offset: Offset(0, _pressed ? pressOffset : 0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      widget.frameAsset,
                      key: Key('${widget.debugId}-frame'),
                      fit: BoxFit.fill,
                    ),
                    Center(child: widget.child),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
