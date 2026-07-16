import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/backend/account/account_session.dart';
import 'package:pixel_survivor/backend/progress/cloud_progress_repository.dart';
import 'package:pixel_survivor/backend/progress/progress_sync_controller.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';

void main() {
  test('guest play remains local-only', () async {
    final store = _MemorySaveStore(_save(kills: 4));
    final repository = _FakeCloudRepository();
    final controller = ProgressSyncController(
      readAccount: () => AccountSession.anonymous(userId: 'guest'),
      store: store,
      repository: repository,
    );

    await controller.syncNow();

    expect(store.loadCalls, 0);
    expect(repository.fetchCalls, 0);
    expect(controller.status, SyncStatus.idle);
  });

  test('initial sync uploads local save when cloud is absent', () async {
    final local = _save(kills: 12);
    final repository = _FakeCloudRepository();
    final controller = _controller(local: local, repository: repository);

    await controller.syncNow();

    expect(repository.created, local);
    expect(controller.revision, 1);
    expect(controller.status, SyncStatus.synced);
  });

  test('existing cloud wins first synchronization', () async {
    final cloud = _save(kills: 99);
    final store = _MemorySaveStore(_save(kills: 12));
    final repository = _FakeCloudRepository(
      cloud: CloudProgressSnapshot(revision: 7, save: cloud),
    );
    final controller = _controller(
      local: store.state,
      store: store,
      repository: repository,
    );

    await controller.syncNow();

    expect(store.state.totalKills, 99);
    expect(repository.updateCalls, 0);
    expect(controller.revision, 7);
  });

  test('later sync updates using remembered revision', () async {
    final store = _MemorySaveStore(_save(kills: 10));
    final repository = _FakeCloudRepository(
      cloud: CloudProgressSnapshot(revision: 3, save: _save(kills: 10)),
    );
    final controller = _controller(
      local: store.state,
      store: store,
      repository: repository,
    );
    await controller.syncNow();
    store.state = _save(kills: 14);

    await controller.syncNow();

    expect(repository.expectedRevision, 3);
    expect(repository.updated?.totalKills, 14);
    expect(controller.revision, 4);
  });

  test('conflict adopts returned server snapshot', () async {
    final server = _save(kills: 55);
    final store = _MemorySaveStore(_save(kills: 10));
    final repository = _FakeCloudRepository(
      cloud: CloudProgressSnapshot(revision: 2, save: _save(kills: 10)),
    );
    final controller = _controller(
      local: store.state,
      store: store,
      repository: repository,
    );
    await controller.syncNow();
    store.state = _save(kills: 20);
    repository.conflict = CloudProgressSnapshot(revision: 5, save: server);

    await controller.syncNow();

    expect(store.state.totalKills, 55);
    expect(controller.status, SyncStatus.conflict);
    expect(controller.revision, 5);
  });

  test('offline retry uses bounded exponential delays', () async {
    final repository = _FakeCloudRepository()..failuresRemaining = 2;
    final delays = <Duration>[];
    final controller = _controller(
      local: _save(kills: 3),
      repository: repository,
      delay: (duration) async => delays.add(duration),
    );

    await controller.syncNow();

    expect(delays, const [Duration(seconds: 1), Duration(seconds: 2)]);
    expect(repository.fetchCalls, 3);
    expect(controller.status, SyncStatus.synced);
  });

  test(
    'account switch forgets revision and loads new cloud snapshot',
    () async {
      var account = AccountSession.google(userId: 'one', email: 'one@test');
      final store = _MemorySaveStore(_save(kills: 1));
      final repository = _FakeCloudRepository(
        cloud: CloudProgressSnapshot(revision: 2, save: _save(kills: 2)),
      );
      final controller = ProgressSyncController(
        readAccount: () => account,
        store: store,
        repository: repository,
      );
      await controller.syncNow();
      account = AccountSession.google(userId: 'two', email: 'two@test');
      repository.cloud = CloudProgressSnapshot(
        revision: 8,
        save: _save(kills: 80),
      );

      await controller.syncNow();

      expect(repository.fetchCalls, 2);
      expect(repository.updateCalls, 0);
      expect(store.state.totalKills, 80);
      expect(controller.revision, 8);
    },
  );
}

ProgressSyncController _controller({
  required SaveState local,
  required _FakeCloudRepository repository,
  _MemorySaveStore? store,
  Future<void> Function(Duration)? delay,
}) => ProgressSyncController(
  readAccount: () => AccountSession.google(userId: 'google', email: 'g@test'),
  store: store ?? _MemorySaveStore(local),
  repository: repository,
  delay: delay,
);

SaveState _save({required int kills}) =>
    SaveState.defaults().copyWith(totalKills: kills);

class _MemorySaveStore implements SaveStore {
  _MemorySaveStore(this.state);
  SaveState state;
  int loadCalls = 0;
  @override
  Future<SaveState> load() async {
    loadCalls++;
    return state;
  }

  @override
  Future<void> save(SaveState state) async => this.state = state;
}

class _FakeCloudRepository implements CloudProgressRepository {
  _FakeCloudRepository({this.cloud});
  CloudProgressSnapshot? cloud;
  CloudProgressSnapshot? conflict;
  SaveState? created;
  SaveState? updated;
  int? expectedRevision;
  int fetchCalls = 0;
  int updateCalls = 0;
  int failuresRemaining = 0;

  void _maybeFail() {
    if (failuresRemaining > 0) {
      failuresRemaining--;
      throw Exception('offline');
    }
  }

  @override
  Future<CloudProgressSnapshot?> fetch() async {
    fetchCalls++;
    _maybeFail();
    return cloud;
  }

  @override
  Future<CloudProgressSnapshot> create(SaveState save) async {
    _maybeFail();
    created = save;
    return cloud = CloudProgressSnapshot(revision: 1, save: save);
  }

  @override
  Future<CloudSyncResult> update({
    required SaveState save,
    required int expectedRevision,
  }) async {
    updateCalls++;
    _maybeFail();
    updated = save;
    this.expectedRevision = expectedRevision;
    if (conflict case final snapshot?) {
      return CloudSyncResult.conflict(snapshot);
    }
    final snapshot = CloudProgressSnapshot(
      revision: expectedRevision + 1,
      save: save,
    );
    cloud = snapshot;
    return CloudSyncResult.updated(snapshot);
  }
}
