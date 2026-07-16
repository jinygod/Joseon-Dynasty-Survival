import 'dart:convert';

import '../../game/systems/save_system.dart';

class CloudRevision {
  CloudRevision(int value) : value = _requireNonNegative('revision', value);

  final int value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CloudRevision && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class CloudProgressSnapshot {
  CloudProgressSnapshot({required int revision, required this.save})
    : revision = _requireNonNegative('revision', revision);

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

int _requireNonNegative(String name, int value) {
  if (value < 0) {
    throw ArgumentError.value(value, name, 'must not be negative');
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
    required CloudRevision expectedRevision,
  });
}
