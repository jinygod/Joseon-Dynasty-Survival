import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/virtual_joystick.dart';
import 'package:pixel_survivor/game/models/vector_input.dart';

void main() {
  testWidgets('joystick applies dead zone clamps radius and resets', (
    tester,
  ) async {
    final inputs = <VectorInput>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Center(child: VirtualJoystick(onInputChanged: inputs.add)),
      ),
    );
    final center = tester.getCenter(find.byKey(const Key('virtual-joystick')));
    final gesture = await tester.startGesture(center, pointer: 1);

    await gesture.moveTo(center + const Offset(5, 0));
    expect(inputs.last, VectorInput.zero);
    await gesture.moveTo(center + const Offset(60, 0));
    expect(inputs.last.x, closeTo(1, 0.001));
    expect(inputs.last.y, closeTo(0, 0.001));
    await gesture.moveTo(center + const Offset(120, 120));
    expect(
      math.sqrt(inputs.last.x * inputs.last.x + inputs.last.y * inputs.last.y),
      lessThanOrEqualTo(1.0001),
    );

    await gesture.up();
    expect(inputs.last, VectorInput.zero);
  });

  testWidgets('joystick ignores every non-owner pointer event', (tester) async {
    final inputs = <VectorInput>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Center(child: VirtualJoystick(onInputChanged: inputs.add)),
      ),
    );
    final center = tester.getCenter(find.byKey(const Key('virtual-joystick')));
    final owner = await tester.startGesture(center, pointer: 1);
    await owner.moveTo(center + const Offset(60, 0));
    final ownerInput = inputs.last;
    final second = await tester.startGesture(center, pointer: 2);

    await second.moveTo(center + const Offset(-60, 0));
    await second.up();

    expect(inputs.last.x, ownerInput.x);
    expect(inputs.last.y, ownerInput.y);
    await owner.up();
    expect(inputs.last, VectorInput.zero);
  });
}
