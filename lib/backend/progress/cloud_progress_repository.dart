import '../../game/systems/save_system.dart';

class CloudProgressSnapshot {
  const CloudProgressSnapshot({required this.revision, required this.save});

  final int revision;
  final SaveState save;
}

class CloudSyncResult {
  const CloudSyncResult({required this.snapshot, required this.hasConflict});

  const CloudSyncResult.updated(CloudProgressSnapshot snapshot)
    : this(snapshot: snapshot, hasConflict: false);

  const CloudSyncResult.conflict(CloudProgressSnapshot snapshot)
    : this(snapshot: snapshot, hasConflict: true);

  final CloudProgressSnapshot snapshot;
  final bool hasConflict;
}

abstract interface class CloudProgressRepository {
  Future<CloudProgressSnapshot?> fetch();
  Future<CloudProgressSnapshot> create(SaveState save);
  Future<CloudSyncResult> update({
    required SaveState save,
    required int expectedRevision,
  });
}
