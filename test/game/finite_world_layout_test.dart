import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/world/finite_world_layout.dart';
import 'package:pixel_survivor/game/world/world_chunk_coordinate.dart';
import 'package:pixel_survivor/game/world/world_runtime_config.dart';

void main() {
  final config = WorldRuntimeConfig.standard;

  test('layout generates deterministic row-major finite world geometry', () {
    final first = FiniteWorldLayout.generate(
      stageId: 'moonlit_courtyard',
      seed: 73,
      config: config,
    );
    final second = FiniteWorldLayout.generate(
      stageId: 'moonlit_courtyard',
      seed: 73,
      config: config,
    );

    expect(first.worldBounds, config.worldBounds);
    expect(first.chunks, hasLength(40));
    expect(first.chunkBounds, hasLength(40));
    expect(first.chunks.first.coordinate, const WorldChunkCoordinate(0, 0));
    expect(first.chunks.last.coordinate, const WorldChunkCoordinate(3, 9));
    expect(
      first.chunks.map((chunk) => chunk.coordinate),
      second.chunks.map((chunk) => chunk.coordinate),
    );
    expect(
      first.chunks.map((chunk) => chunk.layoutSeed),
      second.chunks.map((chunk) => chunk.layoutSeed),
    );
    expect(first.chunks.where((chunk) => chunk.isBoundary), hasLength(24));
  });

  test('layout exposes required immutable anchor collections', () {
    final layout = FiniteWorldLayout.generate(
      stageId: 'moonlit_courtyard',
      seed: 73,
      config: config,
    );

    expect(layout.boundaryDecorationAnchors, hasLength(96));
    expect(layout.landmarkAnchors, hasLength(6));
    expect(layout.reservedChestAnchors, hasLength(8));
    expect(
      () => layout.chunks.add(layout.chunks.first),
      throwsUnsupportedError,
    );
    expect(
      () => layout.chunkBounds[const WorldChunkCoordinate(0, 0)] =
          layout.worldBounds,
      throwsUnsupportedError,
    );
  });

  test('anchors stay within their valid world and chunk regions', () {
    final layout = FiniteWorldLayout.generate(
      stageId: 'moonlit_courtyard',
      seed: 73,
      config: config,
    );
    final anchorPositions = <String>{};

    for (final anchor in layout.boundaryDecorationAnchors) {
      final bounds = layout.chunkBounds[anchor.coordinate]!;
      expect(bounds.contains(anchor.position), isTrue);
      expect(
        anchor.position.dx,
        inInclusiveRange(24, layout.worldBounds.right - 24),
      );
      expect(
        anchor.position.dy,
        inInclusiveRange(24, layout.worldBounds.bottom - 24),
      );
    }
    for (final anchor in [
      ...layout.landmarkAnchors,
      ...layout.reservedChestAnchors,
    ]) {
      final bounds = layout.chunkBounds[anchor.coordinate]!;
      expect(anchor.coordinate.x, inInclusiveRange(1, 2));
      expect(anchor.coordinate.y, inInclusiveRange(1, 8));
      expect(
        anchor.position.dx,
        inInclusiveRange(bounds.left + 64, bounds.right - 64),
      );
      expect(
        anchor.position.dy,
        inInclusiveRange(bounds.top + 64, bounds.bottom - 64),
      );
      expect(
        anchorPositions.add('${anchor.position.dx},${anchor.position.dy}'),
        isTrue,
      );
    }
  });

  test('bounded chunk lookup rejects positions outside the world', () {
    final layout = FiniteWorldLayout.generate(
      stageId: 'moonlit_courtyard',
      seed: 73,
      config: config,
    );

    expect(layout.containsWorldPosition(Vector2(0, 0)), isTrue);
    expect(layout.containsWorldPosition(Vector2(2048, 5120)), isFalse);
    expect(
      layout.chunkAt(Vector2(1025, 2561)),
      const WorldChunkCoordinate(2, 5),
    );
    expect(() => layout.chunkAt(Vector2(2048, 1)), throwsRangeError);
    expect(() => layout.chunkAt(Vector2(double.infinity, 1)), throwsRangeError);
  });
}
