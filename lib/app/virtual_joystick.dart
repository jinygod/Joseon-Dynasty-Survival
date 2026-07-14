import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/models/vector_input.dart';

class VirtualJoystick extends StatefulWidget {
  const VirtualJoystick({
    required this.onInputChanged,
    this.size = 120,
    this.deadZone = 10,
    super.key,
  });

  final ValueChanged<VectorInput> onInputChanged;
  final double size;
  final double deadZone;

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  int? _activePointer;
  Offset _thumbOffset = Offset.zero;

  void _updateInput(Offset localPosition) {
    final radius = widget.size / 2;
    final center = Offset(radius, radius);
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
    setState(() => _thumbOffset = Offset.zero);
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
    return SizedBox.square(
      key: const Key('virtual-joystick'),
      dimension: widget.size,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          if (_activePointer != null) return;
          _activePointer = event.pointer;
          _updateInput(event.localPosition);
        },
        onPointerMove: (event) {
          if (_activePointer == event.pointer) {
            _updateInput(event.localPosition);
          }
        },
        onPointerUp: (event) => _release(event.pointer),
        onPointerCancel: (event) => _release(event.pointer),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xfff4ead2).withValues(alpha: 0.16),
            border: Border.all(
              color: const Color(0xfff4ead2).withValues(alpha: 0.55),
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
                  color: const Color(0xff5cc8ff).withValues(alpha: 0.85),
                  border: Border.all(color: const Color(0xff101820), width: 2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
