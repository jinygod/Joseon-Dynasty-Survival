import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/models/vector_input.dart';

class VirtualJoystick extends StatefulWidget {
  const VirtualJoystick({
    required this.onInputChanged,
    this.size = 120,
    this.deadZone = 10,
    this.idleOpacity = 0.35,
    this.activeOpacity = 0.55,
    super.key,
  }) : assert(idleOpacity >= 0 && idleOpacity <= 1),
       assert(activeOpacity >= 0 && activeOpacity <= 1);

  final ValueChanged<VectorInput> onInputChanged;
  final double size;
  final double deadZone;
  final double idleOpacity;
  final double activeOpacity;

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  int? _activePointer;
  Offset? _activeCenter;
  Offset _thumbOffset = Offset.zero;

  void _updateInput(Offset localPosition) {
    final center = _activeCenter;
    if (center == null) return;
    final radius = widget.size / 2;
    final delta = localPosition - center;
    final distance = delta.distance;

    if (distance < widget.deadZone) {
      setState(() => _thumbOffset = Offset.zero);
      widget.onInputChanged(VectorInput.zero);
      return;
    }

    final clampedDistance = math.min(distance, radius);
    final direction = delta / distance;
    setState(() => _thumbOffset = direction * clampedDistance);
    widget.onInputChanged(
      VectorInput(
        direction.dx * clampedDistance / radius,
        direction.dy * clampedDistance / radius,
      ),
    );
  }

  void _release(int pointer) {
    if (_activePointer != pointer) return;
    _activePointer = null;
    setState(() {
      _activeCenter = null;
      _thumbOffset = Offset.zero;
    });
    widget.onInputChanged(VectorInput.zero);
  }

  @override
  void dispose() {
    if (_activePointer != null) {
      widget.onInputChanged(VectorInput.zero);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final idleCenter = Offset(
          constraints.maxWidth / 2,
          constraints.maxHeight - widget.size / 2 - 18,
        );
        final center = _activeCenter ?? idleCenter;
        return SizedBox.expand(
          key: const Key('virtual-joystick'),
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
              if (_activePointer != null) return;
              setState(() {
                _activePointer = event.pointer;
                _activeCenter = event.localPosition;
                _thumbOffset = Offset.zero;
              });
              widget.onInputChanged(VectorInput.zero);
            },
            onPointerMove: (event) {
              if (_activePointer == event.pointer) {
                _updateInput(event.localPosition);
              }
            },
            onPointerUp: (event) => _release(event.pointer),
            onPointerCancel: (event) => _release(event.pointer),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: center.dx - widget.size / 2,
                  top: center.dy - widget.size / 2,
                  child: SizedBox.square(
                    key: const Key('virtual-joystick-base'),
                    dimension: widget.size,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xfff4ead2).withValues(
                          alpha: _activePointer == null
                              ? widget.idleOpacity
                              : widget.activeOpacity,
                        ),
                        border: Border.all(
                          color: const Color(
                            0xfff4ead2,
                          ).withValues(alpha: 0.55),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Transform.translate(
                          offset: _thumbOffset,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(
                                0xff5cc8ff,
                              ).withValues(alpha: 0.85),
                              border: Border.all(
                                color: const Color(0xff101820),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
