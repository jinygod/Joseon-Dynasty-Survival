import 'package:flutter/foundation.dart';

import '../../game/systems/save_system.dart';
import '../account/account_session.dart';
import 'cloud_progress_repository.dart';
import 'save_state_validator.dart';

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
       _delay = delay ?? Future<void>.delayed;

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
  final Future<void> Function(Duration) _delay;

  SyncStatus status = SyncStatus.idle;
  int? revision;
  String? lastError;
  String? _accountId;
  bool _disposed = false;
  bool _running = false;

  Future<void> syncNow() async {
    final account = readAccount();
    if (!account.isPermanent) {
      status = SyncStatus.idle;
      revision = null;
      _accountId = null;
      _notify();
      return;
    }
    if (_running) return;
    _running = true;
    if (_accountId != account.userId) {
      _accountId = account.userId;
      revision = null;
    }
    status = SyncStatus.syncing;
    lastError = null;
    _notify();

    try {
      for (var attempt = 0; ; attempt++) {
        try {
          final conflict = await _syncOnce();
          status = conflict ? SyncStatus.conflict : SyncStatus.synced;
          lastError = null;
          _notify();
          return;
        } on Object catch (error) {
          status = SyncStatus.offline;
          lastError = error.toString();
          _notify();
          if (attempt >= retryDelays.length || _disposed) return;
          await _delay(retryDelays[attempt]);
          if (_disposed) return;
        }
      }
    } finally {
      _running = false;
    }
  }

  Future<bool> _syncOnce() async {
    final local = await store.load();
    validator.validate(local);
    if (revision == null) {
      final cloud = await repository.fetch();
      if (cloud == null) {
        final created = await repository.create(local);
        validator.validate(created.save);
        revision = created.revision;
      } else {
        validator.validate(cloud.save);
        await store.save(cloud.save);
        revision = cloud.revision;
      }
      return false;
    }

    final result = await repository.update(
      save: local,
      expectedRevision: revision!,
    );
    validator.validate(result.snapshot.save);
    revision = result.snapshot.revision;
    if (result.hasConflict) {
      await store.save(result.snapshot.save);
      return true;
    }
    return false;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
