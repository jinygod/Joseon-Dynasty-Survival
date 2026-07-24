import 'dart:collection';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../content/ids.dart';
import 'world_chunk_coordinate.dart';

@immutable
class SleepingEnemyRecord {
  SleepingEnemyRecord({
    required this.enemyId,
    required Vector2 position,
    required this.healthFraction,
    required this.rank,
    required this.stateSeed,
  }) : position = position.clone();

  final EnemyId enemyId;
  final Vector2 position;
  final double healthFraction;
  final EnemyRank rank;
  final int stateSeed;
}

class WorldChunkRepository {
  WorldChunkRepository({required this.chunkSize}) {
    if (!chunkSize.isFinite || chunkSize <= 0) {
      throw ArgumentError.value(chunkSize, 'chunkSize');
    }
  }

  final double chunkSize;
  final Map<WorldChunkCoordinate, List<SleepingEnemyRecord>> _sleeping = {};
  final Map<WorldChunkCoordinate, int> _visitPressure = {};
  final Set<WorldChunkCoordinate> _visited = {};

  int get sleepingCount =>
      _sleeping.values.fold(0, (total, records) => total + records.length);
  Map<WorldChunkCoordinate, int> get visitPressure =>
      UnmodifiableMapView(_visitPressure);

  void sleepEnemy(SleepingEnemyRecord record) {
    final coordinate = _coordinateFor(record.position);
    _sleeping.putIfAbsent(coordinate, () => []).add(record);
  }

  List<SleepingEnemyRecord> restoreEnemiesNear(Rect bounds) {
    final restored = <SleepingEnemyRecord>[];
    for (final coordinate in _coordinatesOverlapping(bounds).toList()) {
      final records = _sleeping[coordinate];
      if (records == null) continue;
      final matching = records
          .where((record) => bounds.contains(record.position.toOffset()))
          .toList(growable: false);
      if (matching.isEmpty) continue;
      records.removeWhere(matching.contains);
      if (records.isEmpty) _sleeping.remove(coordinate);
      restored.addAll(matching);
      _visitPressure.update(
        coordinate,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return List.unmodifiable(restored);
  }

  void markVisited(Rect bounds) {
    for (final coordinate in _coordinatesOverlapping(bounds)) {
      if (!_visited.add(coordinate)) continue;
      _visitPressure.update(
        coordinate,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
  }

  int recycleFarRecords(Rect retainedBounds) {
    var recycled = 0;
    for (final coordinate in _sleeping.keys.toList()) {
      if (_chunkBounds(coordinate).overlaps(retainedBounds)) continue;
      final records = _sleeping.remove(coordinate)!;
      recycled += records.length;
      _visitPressure.update(
        coordinate,
        (value) => value + records.length,
        ifAbsent: () => records.length,
      );
    }
    return recycled;
  }

  double visitPressureAt(Vector2 position) =>
      (_visitPressure[_coordinateFor(position)] ?? 0).toDouble();

  WorldChunkCoordinate _coordinateFor(Vector2 position) =>
      WorldChunkCoordinate.fromWorldPosition(position, chunkSize: chunkSize);

  Iterable<WorldChunkCoordinate> _coordinatesOverlapping(Rect bounds) sync* {
    if (bounds.isEmpty) return;
    final left = (bounds.left / chunkSize).floor();
    final top = (bounds.top / chunkSize).floor();
    final right = ((bounds.right - .0001) / chunkSize).floor();
    final bottom = ((bounds.bottom - .0001) / chunkSize).floor();
    for (var y = top; y <= bottom; y += 1) {
      for (var x = left; x <= right; x += 1) {
        yield WorldChunkCoordinate(x, y);
      }
    }
  }

  Rect _chunkBounds(WorldChunkCoordinate coordinate) => Rect.fromLTWH(
    coordinate.x * chunkSize,
    coordinate.y * chunkSize,
    chunkSize,
    chunkSize,
  );
}
