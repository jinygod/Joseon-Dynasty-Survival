import 'dart:collection';
import 'dart:convert';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:pixel_survivor/game/world/world_chunk_coordinate.dart';
import 'package:pixel_survivor/game/world/world_runtime_config.dart';

@immutable
class WorldChunkDescriptor {
  const WorldChunkDescriptor({
    required this.coordinate,
    required this.bounds,
    required this.layoutSeed,
    required this.isBoundary,
  });

  final WorldChunkCoordinate coordinate;
  final Rect bounds;
  final int layoutSeed;
  final bool isBoundary;
}

@immutable
class WorldLayoutAnchor {
  const WorldLayoutAnchor({
    required this.position,
    required this.coordinate,
    required this.layoutSeed,
  });

  final Offset position;
  final WorldChunkCoordinate coordinate;
  final int layoutSeed;
}

@immutable
class FiniteWorldLayout {
  FiniteWorldLayout._({
    required this.worldBounds,
    required List<WorldChunkDescriptor> chunks,
    required Map<WorldChunkCoordinate, Rect> chunkBounds,
    required List<WorldLayoutAnchor> boundaryDecorationAnchors,
    required List<WorldLayoutAnchor> landmarkAnchors,
    required List<WorldLayoutAnchor> reservedChestAnchors,
    required this._chunkSize,
  }) : chunks = List.unmodifiable(chunks),
       chunkBounds = UnmodifiableMapView(chunkBounds),
       boundaryDecorationAnchors = List.unmodifiable(boundaryDecorationAnchors),
       landmarkAnchors = List.unmodifiable(landmarkAnchors),
        reservedChestAnchors = List.unmodifiable(reservedChestAnchors);

  factory FiniteWorldLayout.generate({
    required String stageId,
    required int seed,
    required WorldRuntimeConfig config,
  }) {
    final worldBounds = config.worldBounds;
    final stageSalt = _fnv1a32(stageId);
    final chunks = <WorldChunkDescriptor>[];
    final chunkBounds = <WorldChunkCoordinate, Rect>{};
    final boundaryAnchors = <WorldLayoutAnchor>[];

    for (var y = 0; y < config.chunkRows; y += 1) {
      for (var x = 0; x < config.chunkColumns; x += 1) {
        final coordinate = WorldChunkCoordinate(x, y);
        final bounds = Rect.fromLTWH(
          x * config.chunkSize,
          y * config.chunkSize,
          config.chunkSize,
          config.chunkSize,
        );
        final layoutSeed = _layoutSeed(seed, stageSalt, x, y);
        final isBoundary =
            x == 0 ||
            y == 0 ||
            x == config.chunkColumns - 1 ||
            y == config.chunkRows - 1;
        chunks.add(
          WorldChunkDescriptor(
            coordinate: coordinate,
            bounds: bounds,
            layoutSeed: layoutSeed,
            isBoundary: isBoundary,
          ),
        );
        chunkBounds[coordinate] = bounds;
        if (isBoundary) {
          boundaryAnchors.addAll(
            _boundaryAnchors(
              coordinate: coordinate,
              bounds: bounds,
              layoutSeed: layoutSeed,
              worldBounds: worldBounds,
              columns: config.chunkColumns,
              rows: config.chunkRows,
            ),
          );
        }
      }
    }

    final landmarkAnchors = _interiorAnchors(
      count: 6,
      collectionSalt: 0x4c414e44,
      seed: seed,
      stageSalt: stageSalt,
      config: config,
      occupiedPositions: <String>{},
    );
    final occupiedPositions = landmarkAnchors
        .map((anchor) => _positionKey(anchor.position))
        .toSet();
    final chestAnchors = _interiorAnchors(
      count: 8,
      collectionSalt: 0x43484553,
      seed: seed,
      stageSalt: stageSalt,
      config: config,
      occupiedPositions: occupiedPositions,
    );

    return FiniteWorldLayout._(
      worldBounds: worldBounds,
      chunks: chunks,
      chunkBounds: chunkBounds,
      boundaryDecorationAnchors: boundaryAnchors,
      landmarkAnchors: landmarkAnchors,
      reservedChestAnchors: chestAnchors,
      chunkSize: config.chunkSize,
    );
  }

  final Rect worldBounds;
  final List<WorldChunkDescriptor> chunks;
  final Map<WorldChunkCoordinate, Rect> chunkBounds;
  final List<WorldLayoutAnchor> boundaryDecorationAnchors;
  final List<WorldLayoutAnchor> landmarkAnchors;
  final List<WorldLayoutAnchor> reservedChestAnchors;
  final double _chunkSize;

  bool containsWorldPosition(Vector2 position) =>
      position.x.isFinite &&
      position.y.isFinite &&
      worldBounds.contains(Offset(position.x, position.y));

  WorldChunkCoordinate chunkAt(Vector2 position) {
    if (!containsWorldPosition(position)) {
      throw RangeError('position must be a finite point inside worldBounds');
    }
    return WorldChunkCoordinate.fromWorldPosition(
      position,
      chunkSize: _chunkSize,
    );
  }
}

List<WorldLayoutAnchor> _boundaryAnchors({
  required WorldChunkCoordinate coordinate,
  required Rect bounds,
  required int layoutSeed,
  required Rect worldBounds,
  required int columns,
  required int rows,
}) {
  final exposedEdges = <_WorldEdge>[
    if (coordinate.x == 0) _WorldEdge.left,
    if (coordinate.y == 0) _WorldEdge.top,
    if (coordinate.x == columns - 1) _WorldEdge.right,
    if (coordinate.y == rows - 1) _WorldEdge.bottom,
  ];
  return List.generate(4, (index) {
    final edge = exposedEdges[index % exposedEdges.length];
    final point = _pointOnEdge(bounds, edge, index, layoutSeed, worldBounds);
    return WorldLayoutAnchor(
      position: point,
      coordinate: coordinate,
      layoutSeed: _mix32(layoutSeed, index, edge.index, 0),
    );
  });
}

Offset _pointOnEdge(
  Rect bounds,
  _WorldEdge edge,
  int index,
  int layoutSeed,
  Rect worldBounds,
) {
  final jitter = (_mix32(layoutSeed, index, edge.index, 1) % 25) - 12;
  final fraction = (index + 1) / 5;
  final alongX = bounds.left + bounds.width * fraction + jitter;
  final alongY = bounds.top + bounds.height * fraction + jitter;
  switch (edge) {
    case _WorldEdge.left:
      return Offset(
        worldBounds.left + 24,
        alongY.clamp(bounds.top, bounds.bottom - 1).toDouble(),
      );
    case _WorldEdge.top:
      return Offset(
        alongX.clamp(bounds.left, bounds.right - 1).toDouble(),
        worldBounds.top + 24,
      );
    case _WorldEdge.right:
      return Offset(
        worldBounds.right - 24,
        alongY.clamp(bounds.top, bounds.bottom - 1).toDouble(),
      );
    case _WorldEdge.bottom:
      return Offset(
        alongX.clamp(bounds.left, bounds.right - 1).toDouble(),
        worldBounds.bottom - 24,
      );
  }
}

List<WorldLayoutAnchor> _interiorAnchors({
  required int count,
  required int collectionSalt,
  required int seed,
  required int stageSalt,
  required WorldRuntimeConfig config,
  required Set<String> occupiedPositions,
}) {
  final anchors = <WorldLayoutAnchor>[];
  for (var index = 0; anchors.length < count; index += 1) {
    final choice = _mix32(seed, stageSalt, collectionSalt, index);
    final x = 1 + choice % (config.chunkColumns - 2);
    final y = 1 + (choice ~/ 17) % (config.chunkRows - 2);
    final coordinate = WorldChunkCoordinate(x, y);
    final layoutSeed = _layoutSeed(seed ^ collectionSalt, stageSalt, x, y);
    final offsetSeed = _mix32(layoutSeed, collectionSalt, index, 2);
    final position = Offset(
      x * config.chunkSize + 64 + offsetSeed % 385,
      y * config.chunkSize + 64 + (offsetSeed ~/ 389) % 385,
    );
    if (!occupiedPositions.add(_positionKey(position))) continue;
    anchors.add(
      WorldLayoutAnchor(
        position: position,
        coordinate: coordinate,
        layoutSeed: layoutSeed,
      ),
    );
  }
  return anchors;
}

String _positionKey(Offset position) => '${position.dx}:${position.dy}';

int _fnv1a32(String value) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(value)) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash;
}

int _layoutSeed(int seed, int stageSalt, int x, int y) =>
    _mix32(seed, stageSalt, x, y);

int _mix32(int first, int second, int third, int fourth) {
  var value = (first ^ 0x9e3779b9) & 0xffffffff;
  for (final part in [second, third, fourth]) {
    value = (value ^ part) & 0xffffffff;
    value = ((value * 0x85ebca6b) + 0xc2b2ae35) & 0xffffffff;
    value ^= value >> 16;
  }
  value ^= value >> 13;
  return value & 0xffffffff;
}

enum _WorldEdge { left, top, right, bottom }
