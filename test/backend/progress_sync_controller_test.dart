import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/backend/account/account_session.dart';
import 'package:pixel_survivor/backend/progress/cloud_progress_repository.dart';
import 'package:pixel_survivor/backend/progress/progress_sync_controller.dart';
import 'package:pixel_survivor/backend/progress/supabase_cloud_progress_repository.dart';
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

  test('exhausted retries use exactly 1 2 4 8 and 16 seconds', () async {
    final repository = _FakeCloudRepository()..failuresRemaining = 20;
    final delays = <Duration>[];
    final controller = _controller(
      local: _save(kills: 3),
      repository: repository,
      delay: (duration) async => delays.add(duration),
    );

    await controller.syncNow();

    expect(delays, ProgressSyncController.retryDelays);
    expect(repository.fetchCalls, 6);
    expect(controller.status, SyncStatus.offline);
  });

  test('account switch during load cannot upload stale account data', () async {
    var account = AccountSession.google(userId: 'one', email: 'one@test');
    final delayedLoad = Completer<SaveState>();
    final store = _MemorySaveStore(_save(kills: 1))..nextLoad = delayedLoad;
    final repository = _FakeCloudRepository();
    final controller = ProgressSyncController(
      readAccount: () => account,
      store: store,
      repository: repository,
    );

    final first = controller.syncNow();
    await _waitFor(() => store.loadCalls == 1);
    account = AccountSession.google(userId: 'two', email: 'two@test');
    store.state = _save(kills: 2);
    final queued = controller.syncNow();
    delayedLoad.complete(_save(kills: 1));
    await Future.wait([first, queued]);

    expect(repository.fetchCalls, 1);
    expect(repository.created?.totalKills, 2);
  });

  test('sync requested during an in-flight sync is queued', () async {
    final repository = _FakeCloudRepository()
      ..fetchCompleter = Completer<CloudProgressSnapshot?>();
    final controller = _controller(
      local: _save(kills: 4),
      repository: repository,
    );

    final first = controller.syncNow();
    await _waitFor(() => repository.fetchCalls == 1);
    final queued = controller.syncNow();
    repository.fetchCompleter!.complete(null);
    await Future.wait([first, queued]);

    expect(repository.fetchCalls, 1);
    expect(repository.updateCalls, 1);
    expect(controller.revision, 2);
  });

  test('create-time conflict adopts the returned server snapshot', () async {
    final server = CloudProgressSnapshot(revision: 5, save: _save(kills: 55));
    final store = _MemorySaveStore(_save(kills: 2));
    final repository = _FakeCloudRepository()..createConflict = server;
    final controller = _controller(
      local: store.state,
      store: store,
      repository: repository,
    );

    await controller.syncNow();

    expect(store.state.totalKills, 55);
    expect(controller.revision, 5);
    expect(controller.status, SyncStatus.conflict);
  });

  test('dispose cancels a retry wait and prevents another attempt', () async {
    final retryWait = Completer<void>();
    final repository = _FakeCloudRepository()..failuresRemaining = 20;
    var delayCalls = 0;
    final controller = _controller(
      local: _save(kills: 1),
      repository: repository,
      delay: (_) {
        delayCalls++;
        return retryWait.future;
      },
    );

    final sync = controller.syncNow();
    await _waitFor(() => delayCalls == 1);
    controller.dispose();
    await sync;

    expect(repository.fetchCalls, 1);
  });

  test(
    'dispose guards an in-flight fetch completion and local write',
    () async {
      final store = _MemorySaveStore(_save(kills: 1));
      final repository = _FakeCloudRepository()
        ..fetchCompleter = Completer<CloudProgressSnapshot?>();
      final controller = _controller(
        local: store.state,
        store: store,
        repository: repository,
      );

      final sync = controller.syncNow();
      await _waitFor(() => repository.fetchCalls == 1);
      controller.dispose();
      repository.fetchCompleter!.complete(
        CloudProgressSnapshot(revision: 9, save: _save(kills: 99)),
      );
      await sync;

      expect(store.saveCalls, 0);
      expect(controller.revision, isNull);
    },
  );

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

  test(
    'new account uploads only progress earned after account-local reset',
    () async {
      var account = AccountSession.google(userId: 'a', email: 'a@test');
      final store = _MemorySaveStore(_save(kills: 500));
      final repository = _FakeCloudRepository(
        cloud: CloudProgressSnapshot(revision: 3, save: _save(kills: 500)),
      );
      final controller = ProgressSyncController(
        readAccount: () => account,
        store: store,
        repository: repository,
      );
      await controller.syncNow();

      account = const AccountSession.signedOut();
      store.state = SaveState.defaults();
      store.state = _save(kills: 7);
      account = AccountSession.google(userId: 'b', email: 'b@test');
      repository.cloud = null;
      repository.created = null;

      await controller.syncNow();

      expect(repository.created?.totalKills, 7);
    },
  );

  test(
    'session invalidation prevents same account reset from overwriting cloud',
    () async {
      final account = AccountSession.google(userId: 'a', email: 'a@test');
      final cloud = CloudProgressSnapshot(revision: 4, save: _save(kills: 400));
      final store = _MemorySaveStore(_save(kills: 400));
      final repository = _FakeCloudRepository(cloud: cloud);
      final controller = ProgressSyncController(
        readAccount: () => account,
        store: store,
        repository: repository,
      );
      await controller.syncNow();
      store.state = SaveState.defaults();

      controller.invalidateSession();
      await controller.syncNow();

      expect(repository.updateCalls, 0);
      expect(repository.fetchCalls, 2);
      expect(store.state.totalKills, 400);
    },
  );

  test(
    'session invalidation drains an in-flight local save before reset',
    () async {
      final cloud = CloudProgressSnapshot(revision: 4, save: _save(kills: 400));
      final store = _BlockingSaveStore(_save(kills: 1));
      final controller = _controller(
        local: store.state,
        store: store,
        repository: _FakeCloudRepository(cloud: cloud),
      );

      final sync = controller.syncNow();
      await store.saveStarted.future;
      var invalidated = false;
      final invalidate = controller.invalidateSession().then(
        (_) => invalidated = true,
      );
      await Future<void>.delayed(Duration.zero);
      expect(invalidated, isFalse);

      store.releaseSave.complete();
      await Future.wait([sync, invalidate]);
      await store.save(SaveState.defaults());

      expect(store.state.totalKills, 0);
    },
  );

  test('session invalidation immediately cancels a retry wait', () async {
    final retryWait = Completer<void>();
    final repository = _FakeCloudRepository()..failuresRemaining = 20;
    var delayCalls = 0;
    final controller = _controller(
      local: _save(kills: 1),
      repository: repository,
      delay: (_) {
        delayCalls++;
        return retryWait.future;
      },
    );

    final sync = controller.syncNow();
    await _waitFor(() => delayCalls == 1);

    await controller.invalidateSession();
    await sync.timeout(const Duration(milliseconds: 100));

    expect(repository.fetchCalls, 1);
  });

  test('sync invoked after dispose starts no work', () async {
    final store = _MemorySaveStore(_save(kills: 1));
    final repository = _FakeCloudRepository();
    final controller = _controller(
      local: store.state,
      store: store,
      repository: repository,
    );

    controller.dispose();
    await controller.syncNow();

    expect(store.loadCalls, 0);
    expect(repository.fetchCalls, 0);
  });
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

Future<void> _waitFor(bool Function() condition) async {
  for (var i = 0; i < 50 && !condition(); i++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(condition(), isTrue);
}

class _MemorySaveStore implements SaveStore {
  _MemorySaveStore(this.state);
  SaveState state;
  int loadCalls = 0;
  int saveCalls = 0;
  Completer<SaveState>? nextLoad;
  @override
  Future<SaveState> load() async {
    loadCalls++;
    final pending = nextLoad;
    nextLoad = null;
    if (pending != null) return pending.future;
    return state;
  }

  @override
  Future<void> save(SaveState state) async {
    saveCalls++;
    this.state = state;
  }
}

class _BlockingSaveStore extends _MemorySaveStore {
  _BlockingSaveStore(super.state);

  final saveStarted = Completer<void>();
  final releaseSave = Completer<void>();
  var _blocked = false;

  @override
  Future<void> save(SaveState state) async {
    saveCalls++;
    if (!_blocked) {
      _blocked = true;
      saveStarted.complete();
      await releaseSave.future;
    }
    this.state = state;
  }
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
  Completer<CloudProgressSnapshot?>? fetchCompleter;
  CloudProgressSnapshot? createConflict;

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
    if (fetchCompleter case final pending?) return pending.future;
    return cloud;
  }

  @override
  Future<CloudProgressSnapshot> create(SaveState save) async {
    _maybeFail();
    created = save;
    if (createConflict case final snapshot?) {
      throw CloudProgressConflict(snapshot);
    }
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
