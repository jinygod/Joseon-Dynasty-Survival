import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../game/systems/save_system.dart';
import '../account/account_session.dart';
import 'cloud_progress_repository.dart';
import 'save_state_validator.dart';
import 'supabase_cloud_progress_repository.dart';

enum SyncStatus { idle, syncing, synced, offline, conflict }

extension SyncStatusLabel on SyncStatus {
  String get label => switch (this) {
    SyncStatus.idle => '로컬 저장',
    SyncStatus.syncing => '동기화 중',
    SyncStatus.synced => '동기화 완료',
    SyncStatus.offline => '오프라인 · 나중에 다시 시도',
    SyncStatus.conflict => '더 최신인 클라우드 저장을 불러옴',
  };
}

class ProgressSyncController extends ChangeNotifier {
  ProgressSyncController({
    required this.readAccount,
    required this.store,
    required this.repository,
    SaveStateValidator? validator,
    Future<void> Function(Duration)? delay,
  }) : validator = validator ?? SaveStateValidator(),
       _injectedDelay = delay;

  static const retryDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 16),
  ];

  final AccountSession Function() readAccount;
  final SaveStore store;
  final CloudProgressRepository repository;
  final SaveStateValidator validator;
  final Future<void> Function(Duration)? _injectedDelay;

  SyncStatus status = SyncStatus.idle;
  int? revision;
  String? lastError;
  String? _accountId;
  AccountSession? _observedSession;
  int _sessionGeneration = 0;
  bool _disposed = false;
  bool _syncRequested = false;
  Future<void>? _drainFuture;
  Timer? _retryTimer;
  Completer<bool>? _retryCompleter;

  Future<void> syncNow() {
    if (_disposed) return Future<void>.value();
    _syncRequested = true;
    final running = _drainFuture;
    if (running != null) return running;
    final drain = _drainWithCleanup();
    _drainFuture = drain;
    return drain;
  }

  Future<void> invalidateSession() async {
    if (_disposed) return;
    _observedSession = null;
    _sessionGeneration++;
    _accountId = null;
    revision = null;
    _syncRequested = false;
    _cancelRetryWait();
    final running = _drainFuture;
    if (running != null) await running;
    if (_disposed) return;
    status = SyncStatus.idle;
    lastError = null;
    _notify();
  }

  Future<void> _drainWithCleanup() async {
    try {
      await _drain();
    } finally {
      _drainFuture = null;
    }
    if (_syncRequested && !_disposed) await syncNow();
  }

  Future<void> _drain() async {
    while (_syncRequested && !_disposed) {
      _syncRequested = false;
      final account = readAccount();
      final token = _observe(account);
      if (!account.isPermanent) {
        status = SyncStatus.idle;
        revision = null;
        _accountId = null;
        _notify();
        continue;
      }
      if (_accountId != account.userId) {
        _accountId = account.userId;
        revision = null;
      }
      status = SyncStatus.syncing;
      lastError = null;
      _notify();

      for (var attempt = 0; !_disposed; attempt++) {
        try {
          final conflict = await _syncOnce(token);
          _ensureActive(token);
          status = conflict ? SyncStatus.conflict : SyncStatus.synced;
          lastError = null;
          _notify();
          break;
        } on _StaleSession {
          break;
        } on _SyncCancelled {
          return;
        } on Object catch (error) {
          if (_disposed) return;
          try {
            _ensureActive(token);
          } on _StaleSession {
            break;
          }
          status = SyncStatus.offline;
          lastError = error.toString();
          _notify();
          if (attempt >= retryDelays.length) break;
          final completed = await _waitForRetry(retryDelays[attempt]);
          if (!completed || _disposed) return;
          try {
            _ensureActive(token);
          } on _StaleSession {
            break;
          }
        }
      }
    }
  }

  Future<bool> _syncOnce(_SessionToken token) async {
    final local = await _bound(token, store.load);
    validator.validate(local);
    _ensureActive(token);
    if (revision == null) {
      final cloud = await _bound(token, repository.fetch);
      if (cloud == null) {
        try {
          final created = await _bound(token, () => repository.create(local));
          validator.validate(created.save);
          _ensureActive(token);
          revision = created.revision;
        } on CloudProgressConflict catch (conflict) {
          _ensureActive(token);
          validator.validate(conflict.snapshot.save);
          await _bound(token, () => store.save(conflict.snapshot.save));
          _ensureActive(token);
          revision = conflict.snapshot.revision;
          return true;
        }
      } else {
        validator.validate(cloud.save);
        _ensureActive(token);
        await _bound(token, () => store.save(cloud.save));
        _ensureActive(token);
        revision = cloud.revision;
      }
      return false;
    }

    final expectedRevision = revision!;
    final result = await _bound(
      token,
      () => repository.update(save: local, expectedRevision: expectedRevision),
    );
    validator.validate(result.snapshot.save);
    _ensureActive(token);
    if (result.hasConflict) {
      await _bound(token, () => store.save(result.snapshot.save));
      _ensureActive(token);
      revision = result.snapshot.revision;
      return true;
    }
    revision = result.snapshot.revision;
    return false;
  }

  Future<T> _bound<T>(
    _SessionToken token,
    Future<T> Function() operation,
  ) async {
    _ensureActive(token);
    final result = await operation();
    _ensureActive(token);
    return result;
  }

  _SessionToken _observe(AccountSession session) {
    if (_observedSession != session) {
      _observedSession = session;
      _sessionGeneration++;
    }
    return _SessionToken(session, _sessionGeneration);
  }

  void _ensureActive(_SessionToken token) {
    if (_disposed) throw const _SyncCancelled();
    final current = readAccount();
    if (current != _observedSession ||
        current != token.session ||
        token.generation != _sessionGeneration) {
      _observe(current);
      throw const _StaleSession();
    }
  }

  Future<bool> _waitForRetry(Duration duration) async {
    if (_disposed) return false;
    final completer = Completer<bool>();
    _retryCompleter = completer;
    final injected = _injectedDelay;
    if (injected != null) {
      unawaited(
        injected(duration).then(
          (_) {
            if (!completer.isCompleted) completer.complete(true);
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!completer.isCompleted) {
              completer.completeError(error, stackTrace);
            }
          },
        ),
      );
    } else {
      _retryTimer = Timer(duration, () {
        if (!completer.isCompleted) completer.complete(true);
      });
    }
    final completed = await completer.future;
    if (identical(_retryCompleter, completer)) {
      _retryCompleter = null;
      _retryTimer = null;
    }
    return completed;
  }

  void _cancelRetryWait() {
    _retryTimer?.cancel();
    _retryTimer = null;
    final retry = _retryCompleter;
    _retryCompleter = null;
    if (retry != null && !retry.isCompleted) retry.complete(false);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _syncRequested = false;
    _cancelRetryWait();
    super.dispose();
  }
}

class _SessionToken {
  const _SessionToken(this.session, this.generation);
  final AccountSession session;
  final int generation;
}

class _StaleSession implements Exception {
  const _StaleSession();
}

class _SyncCancelled implements Exception {
  const _SyncCancelled();
}
