import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/stage_visual_spec.dart';

void main() {
  const bounds = Rect.fromLTWH(-64, -64, 384, 256);
  const spec = StageVisualSpec(
    stageId: 'test_stage',
    seedSalt: 0x531A6E,
    tileAssetKey: 'tiles.png',
    decalAssetKey: 'decals.png',
    propAssetKey: 'props.png',
  );

  test('same stage and seed produce identical placements', () {
    final a = StageLayout.build(spec, seed: 3107, bounds: bounds);
    final b = StageLayout.build(spec, seed: 3107, bounds: bounds);

    expect(a.tiles, b.tiles);
    expect(a.decorations, b.decorations);
  });

  test('different seeds vary optional placements while retaining coverage', () {
    final a = StageLayout.build(spec, seed: 3107, bounds: bounds);
    final b = StageLayout.build(spec, seed: 3108, bounds: bounds);

    expect(a.tiles, isNot(b.tiles));
    expect(a.tiles, hasLength(12));
    expect(b.tiles, hasLength(12));
    expect(a.decorations, isNot(b.decorations));
  });

  test('tile coverage includes the full bounds', () {
    final layout = StageLayout.build(spec, seed: 3107, bounds: bounds);

    for (final point in <Offset>[
      bounds.topLeft,
      bounds.topRight - const Offset(.01, 0),
      bounds.bottomLeft - const Offset(0, .01),
      bounds.bottomRight - const Offset(.01, .01),
    ]) {
      expect(
        layout.tiles.any((tile) => tile.bounds.contains(point)),
        isTrue,
        reason: 'expected $point to be covered',
      );
    }
  });

  test('props remain within the edge band', () {
    final layout = StageLayout.build(spec, seed: 3107, bounds: bounds);

    for (final prop in layout.props) {
      expect(
        prop.position.dx <= bounds.left + spec.edgeBand ||
            prop.position.dx >= bounds.right - spec.edgeBand ||
            prop.position.dy <= bounds.top + spec.edgeBand ||
            prop.position.dy >= bounds.bottom - spec.edgeBand,
        isTrue,
      );
    }
  });

  test('placement collections are unmodifiable', () {
    final layout = StageLayout.build(spec, seed: 3107, bounds: bounds);

    expect(() => layout.tiles.add(layout.tiles.first), throwsUnsupportedError);
    expect(
      () => layout.decorations.add(layout.decorations.first),
      throwsUnsupportedError,
    );
    expect(() => layout.props.add(layout.props.first), throwsUnsupportedError);
  });
}
