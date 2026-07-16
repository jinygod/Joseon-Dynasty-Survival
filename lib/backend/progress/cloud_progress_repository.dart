import 'dart:convert';

import '../../game/systems/save_system.dart';

class CloudProgressSnapshot {
  CloudProgressSnapshot({required int revision, required this.save})
    : revision = _requirePositive('revision', revision);

  final int revision;
  final SaveState save;

  String get _encodedSave => jsonEncode(_canonicalize(save.toJson()));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CloudProgressSnapshot &&
          revision == other.revision &&
          _encodedSave == other._encodedSave;

  @override
  int get hashCode => Object.hash(revision, _encodedSave);
}

class CloudSyncResult {
  const CloudSyncResult({required this.snapshot, required this.hasConflict});

  const CloudSyncResult.updated(CloudProgressSnapshot snapshot)
    : this(snapshot: snapshot, hasConflict: false);

  const CloudSyncResult.conflict(CloudProgressSnapshot snapshot)
    : this(snapshot: snapshot, hasConflict: true);

  final CloudProgressSnapshot snapshot;
  final bool hasConflict;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CloudSyncResult &&
          snapshot == other.snapshot &&
          hasConflict == other.hasConflict;

  @override
  int get hashCode => Object.hash(snapshot, hasConflict);
}

int _requirePositive(String name, int value) {
  if (value < 1) {
    throw ArgumentError.value(value, name, 'must be positive');
  }
  return value;
}

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return {for (final key in keys) key: _canonicalize(value[key])};
  }
  if (value is Iterable) {
    return value.map(_canonicalize).toList();
  }
  return value;
}

abstract interface class CloudProgressRepository {
  Future<CloudProgressSnapshot?> fetch();
  Future<CloudProgressSnapshot> create(SaveState save);
  Future<CloudSyncResult> update({
    required SaveState save,
    required int expectedRevision,
  });
}
