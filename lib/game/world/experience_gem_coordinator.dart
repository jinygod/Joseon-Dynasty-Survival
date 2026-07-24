import 'dart:collection';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import 'experience_ledger.dart';
import 'world_chunk_coordinate.dart';

@immutable
class ExperienceGemRecord {
  ExperienceGemRecord({
    required this.id,
    required this.value,
    required Vector2 position,
  }) : position = position.clone();

  final int id;
  final int value;
  final Vector2 position;
}

class ExperiencePickupToken {
  ExperiencePickupToken({required this.recordId, required this.value});

  final int recordId;
  final int value;
  bool _consumed = false;

  bool get isConsumed => _consumed;

  int consume() {
    if (_consumed) return 0;
    _consumed = true;
    return value;
  }

  int cancel() => consume();
}

class ExperienceGemCoordinator {
  ExperienceGemCoordinator({
    required this.maxActiveGems,
    required this.chunkSize,
    ExperienceLedger? ledger,
  }) : ledger = ledger ?? ExperienceLedger() {
    if (maxActiveGems <= 0) {
      throw ArgumentError.value(maxActiveGems, 'maxActiveGems');
    }
    if (!chunkSize.isFinite || chunkSize <= 0) {
      throw ArgumentError.value(chunkSize, 'chunkSize');
    }
  }

  factory ExperienceGemCoordinator.test({required int maxActiveGems}) =>
      ExperienceGemCoordinator(maxActiveGems: maxActiveGems, chunkSize: 512);

  final int maxActiveGems;
  final double chunkSize;
  final ExperienceLedger ledger;
  final Map<int, ExperienceGemRecord> _active = {};
  final Map<WorldChunkCoordinate, _CompressedExperience> _compressed = {};
  final Map<int, int> _magnetized = {};
  int _nextId = 0;

  int get totalOwnedExperience => ledger.totalOwnedExperience;
  int get compressedExperience => ledger.valueOf(ExperienceOwner.compressed);
  int get grantedExperience => ledger.valueOf(ExperienceOwner.granted);
  int get ownedComponentCount => _active.length + _magnetized.length;
  List<ExperienceGemRecord> get activeRecords =>
      UnmodifiableListView(_active.values.toList(growable: false));

  ExperienceGemRecord? drop(int value, Vector2 position) {
    if (value <= 0) return null;
    ledger.add(ExperienceOwner.dropped, value);
    final record = ExperienceGemRecord(
      id: _nextId++,
      value: value,
      position: position,
    );
    if (ownedComponentCount < maxActiveGems) {
      _active[record.id] = record;
      ledger.transfer(
        from: ExperienceOwner.dropped,
        to: ExperienceOwner.mounted,
        amount: value,
      );
      return record;
    }
    _compress(record);
    ledger.transfer(
      from: ExperienceOwner.dropped,
      to: ExperienceOwner.compressed,
      amount: value,
    );
    return null;
  }

  void mergeNearby({double radius = 24}) {
    final records = _active.values.toList(growable: false);
    final consumed = <int>{};
    for (var leftIndex = 0; leftIndex < records.length; leftIndex += 1) {
      final left = records[leftIndex];
      if (consumed.contains(left.id)) continue;
      var value = left.value;
      for (
        var rightIndex = leftIndex + 1;
        rightIndex < records.length;
        rightIndex += 1
      ) {
        final right = records[rightIndex];
        if (consumed.contains(right.id) ||
            _gradeFor(value) != _gradeFor(right.value) ||
            left.position.distanceToSquared(right.position) > radius * radius) {
          continue;
        }
        value += right.value;
        consumed.add(right.id);
      }
      if (value != left.value) {
        _active[left.id] = ExperienceGemRecord(
          id: left.id,
          value: value,
          position: left.position,
        );
      }
    }
    for (final id in consumed) {
      _active.remove(id);
    }
  }

  List<int> compressOutside(Rect retainedBounds) {
    final removedIds = <int>[];
    for (final record in _active.values.toList(growable: false)) {
      if (retainedBounds.contains(record.position.toOffset())) continue;
      _active.remove(record.id);
      _compress(record);
      ledger.transfer(
        from: ExperienceOwner.mounted,
        to: ExperienceOwner.compressed,
        amount: record.value,
      );
      removedIds.add(record.id);
    }
    return List.unmodifiable(removedIds);
  }

  List<ExperienceGemRecord> restoreNear(Rect bounds) {
    final restored = <ExperienceGemRecord>[];
    for (final coordinate in _compressed.keys.toList()) {
      if (ownedComponentCount >= maxActiveGems) break;
      final compressed = _compressed[coordinate]!;
      if (!bounds.contains(compressed.position.toOffset())) continue;
      _compressed.remove(coordinate);
      final record = ExperienceGemRecord(
        id: _nextId++,
        value: compressed.value,
        position: compressed.position,
      );
      _active[record.id] = record;
      ledger.transfer(
        from: ExperienceOwner.compressed,
        to: ExperienceOwner.mounted,
        amount: record.value,
      );
      restored.add(record);
    }
    return List.unmodifiable(restored);
  }

  ExperiencePickupToken? beginPickup(int recordId) {
    final record = _active.remove(recordId);
    if (record == null) return null;
    _magnetized[recordId] = record.value;
    ledger.transfer(
      from: ExperienceOwner.mounted,
      to: ExperienceOwner.magnetized,
      amount: record.value,
    );
    return ExperiencePickupToken(recordId: recordId, value: record.value);
  }

  int completePickup(ExperiencePickupToken token) {
    final ownedValue = _magnetized[token.recordId];
    if (ownedValue == null || ownedValue != token.value) return 0;
    final value = token.consume();
    if (value == 0) return 0;
    _magnetized.remove(token.recordId);
    ledger.transfer(
      from: ExperienceOwner.magnetized,
      to: ExperienceOwner.granted,
      amount: value,
    );
    return value;
  }

  ExperienceGemRecord? cancelPickup(
    ExperiencePickupToken token,
    Vector2 position,
  ) {
    final ownedValue = _magnetized[token.recordId];
    if (ownedValue == null || ownedValue != token.value) return null;
    final value = token.cancel();
    if (value == 0) return null;
    _magnetized.remove(token.recordId);
    final record = ExperienceGemRecord(
      id: token.recordId,
      value: value,
      position: position,
    );
    if (ownedComponentCount < maxActiveGems) {
      _active[record.id] = record;
      ledger.transfer(
        from: ExperienceOwner.magnetized,
        to: ExperienceOwner.mounted,
        amount: value,
      );
      return record;
    }
    _compress(record);
    ledger.transfer(
      from: ExperienceOwner.magnetized,
      to: ExperienceOwner.compressed,
      amount: value,
    );
    return null;
  }

  void _compress(ExperienceGemRecord record) {
    final coordinate = WorldChunkCoordinate.fromWorldPosition(
      record.position,
      chunkSize: chunkSize,
    );
    _compressed.update(
      coordinate,
      (current) => current.add(record.value, record.position),
      ifAbsent: () => _CompressedExperience(record.value, record.position),
    );
  }
}

@immutable
class _CompressedExperience {
  _CompressedExperience(this.value, Vector2 position)
    : position = position.clone();

  final int value;
  final Vector2 position;

  _CompressedExperience add(int addedValue, Vector2 addedPosition) {
    final total = value + addedValue;
    return _CompressedExperience(
      total,
      (position * value.toDouble() + addedPosition * addedValue.toDouble()) /
          total.toDouble(),
    );
  }
}

int _gradeFor(int value) {
  if (value <= 12) return 0;
  if (value <= 40) return 1;
  if (value <= 120) return 2;
  return 3;
}
