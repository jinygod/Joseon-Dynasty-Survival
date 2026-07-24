import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/virtual_joystick.dart';
import 'package:pixel_survivor/game/models/vector_input.dart';

void main() {
  testWidgets('floating joystick uses each pointer down as its origin', (
    tester,
  ) async {
    final inputs = <VectorInput>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            key: const Key('battle-area'),
            width: 390,
            height: 700,
            child: VirtualJoystick(onInputChanged: inputs.add),
          ),
        ),
      ),
    );
    final areaTopLeft = tester.getTopLeft(find.byKey(const Key('battle-area')));
    final base = find.byKey(const Key('virtual-joystick-base'));

    expect(tester.getCenter(base).dx, closeTo(areaTopLeft.dx + 195, 0.1));
    final firstOrigin = areaTopLeft + const Offset(80, 400);
    final first = await tester.startGesture(firstOrigin, pointer: 1);
    await tester.pump();
    expect(inputs.last, VectorInput.zero);
    expect(tester.getCenter(base), firstOrigin);
    await first.moveBy(const Offset(60, 0));
    expect(inputs.last.x, closeTo(1, 0.001));
    await first.up();
    await tester.pump();
    expect(inputs.last, VectorInput.zero);

    final secondOrigin = areaTopLeft + const Offset(300, 300);
    final second = await tester.startGesture(secondOrigin, pointer: 2);
    await tester.pump();
    expect(tester.getCenter(base), secondOrigin);
    await second.up();
    await tester.pump();
    expect(tester.getCenter(base).dx, closeTo(areaTopLeft.dx + 195, 0.1));
  });

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

  testWidgets('joystick becomes more visible while the player steers', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(child: VirtualJoystick(onInputChanged: (_) {})),
      ),
    );
    final joystick = find.byKey(const Key('virtual-joystick'));
    expect(_joystickFillAlpha(tester, joystick), closeTo(0.22, 0.001));

    final gesture = await tester.startGesture(tester.getCenter(joystick));
    await gesture.moveBy(const Offset(24, 0));
    await tester.pump();

    expect(_joystickFillAlpha(tester, joystick), closeTo(0.55, 0.001));
    await gesture.up();
  });
}

double _joystickFillAlpha(WidgetTester tester, Finder joystick) {
  final decoration = tester.widget<DecoratedBox>(
    find.descendant(of: joystick, matching: find.byType(DecoratedBox)).first,
  );
  return (decoration.decoration as BoxDecoration).color!.a;
}
