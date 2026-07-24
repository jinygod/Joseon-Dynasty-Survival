import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

@immutable
class WorldChunkCoordinate {
  const WorldChunkCoordinate(this.x, this.y);

  factory WorldChunkCoordinate.fromWorldPosition(
    Vector2 position, {
    required double chunkSize,
  }) {
    if (!chunkSize.isFinite || chunkSize <= 0) {
      throw ArgumentError.value(
        chunkSize,
        'chunkSize',
        'must be finite and positive',
      );
    }
    if (!position.x.isFinite ||
        !position.y.isFinite ||
        position.x < 0 ||
        position.y < 0) {
      throw RangeError('position must be finite and non-negative');
    }
    return WorldChunkCoordinate(
      (position.x / chunkSize).floor(),
      (position.y / chunkSize).floor(),
    );
  }

  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is WorldChunkCoordinate && other.x == x && other.y == y;

  @override
  int get hashCode => (x * 31) ^ y;
}
