import 'dart:async';

import 'package:flutter/foundation.dart';

import '../backend_config.dart';
import 'account_service.dart';
import 'account_session.dart';

enum AccountAvailability { disabled, ready, offline, blocked }

class AccountController extends ChangeNotifier {
  AccountController({
    required this.config,
    required this.service,
    this.clearLocalState,
    this.clearPaidCache,
    this.onPermanentAccount,
  }) : availability = config.enabled
           ? AccountAvailability.ready
           : AccountAvailability.disabled;

  final BackendConfig config;
  final AccountService service;
  final Future<void> Function()? clearLocalState;
  final Future<void> Function()? clearPaidCache;
  Future<void> Function()? onPermanentAccount;

  AccountSession session = const AccountSession.signedOut();
  AccountAvailability availability;
  bool busy = false;
  String? errorMessage;
  StreamSubscription<AccountSession>? _subscription;
  Future<void> _transitionTail = Future<void>.value();
  AccountSession? _blockedTarget;
  bool _disposed = false;
  int _operationGeneration = 0;

  bool get isGuest => !session.isPermanent;
  bool get purchaseReady =>
      availability == AccountAvailability.ready && session.isPermanent;
  AccountSession get syncSession => availability == AccountAvailability.ready
      ? session
      : const AccountSession.signedOut();

  Future<void> initialize() async {
    if (_disposed) return;
    final operation = ++_operationGeneration;
    if (!config.enabled) {
      session = const AccountSession.signedOut();
      availability = AccountAvailability.disabled;
      _notify();
      return;
    }
    _subscription ??= service.changes.listen((next) {
      if (!_disposed) unawaited(_queueTransition(next));
    });
    busy = true;
    errorMessage = null;
    _notify();
    try {
      final next = await service.ensureGuest();
      if (!_isActive(operation)) return;
      await _queueTransition(next);
    } on Object {
      if (!_isActive(operation)) return;
      session = const AccountSession.signedOut();
      availability = AccountAvailability.offline;
    } finally {
      if (_isActive(operation)) {
        busy = false;
        _notify();
      }
    }
  }

  Future<void> connectGoogle() async {
    if (_disposed || !config.enabled || busy) return;
    final operation = ++_operationGeneration;
    busy = true;
    errorMessage = null;
    _notify();
    try {
      final next = await service.connectGoogle();
      if (!_isActive(operation)) return;
      await _queueTransition(next);
    } on Object {
      if (!_isActive(operation)) return;
      final actual = service.current;
      if (actual != session) await _queueTransition(actual);
      if (!_isActive(operation)) return;
      errorMessage = 'Google 계정 연결에 실패했습니다. 오프라인 플레이는 계속할 수 있습니다.';
    } finally {
      if (_isActive(operation)) {
        busy = false;
        _notify();
      }
    }
  }

  Future<void> signOut() =>
      _endAccount(service.signOut, failureMessage: '로그아웃하지 못했습니다.');

  Future<void> deleteAccount() => _endAccount(
    service.deleteAccount,
    failureMessage: '계정을 삭제하지 못했습니다. 다시 로그인한 뒤 시도해 주세요.',
  );

  Future<void> retryBlockedTransition() async {
    final target = _blockedTarget;
    if (_disposed || target == null || busy) return;
    busy = true;
    _notify();
    try {
      await _queueTransition(target, retryCleanup: true);
    } finally {
      if (!_disposed) {
        busy = false;
        _notify();
      }
    }
  }

  Future<void> _endAccount(
    Future<void> Function() endRemote, {
    required String failureMessage,
  }) async {
    if (_disposed || busy) return;
    final operation = ++_operationGeneration;
    busy = true;
    errorMessage = null;
    _notify();
    var remoteCompleted = false;
    Object? endError;
    try {
      await endRemote();
      remoteCompleted = true;
    } on AccountEndException catch (error) {
      remoteCompleted = error.remoteCompleted;
      endError = error;
    } on Object catch (error) {
      endError = error;
    }
    if (!_isActive(operation)) return;
    if (remoteCompleted) {
      await _queueTransition(const AccountSession.signedOut());
      if (_isActive(operation) &&
          endError != null &&
          availability != AccountAvailability.blocked) {
        errorMessage = failureMessage;
      }
    } else {
      errorMessage = failureMessage;
    }
    if (_isActive(operation)) {
      busy = false;
      _notify();
    }
  }

  Future<void> _queueTransition(
    AccountSession next, {
    bool retryCleanup = false,
  }) {
    final result = Completer<void>();
    _transitionTail = _transitionTail.then((_) async {
      try {
        await _transitionTo(next, retryCleanup: retryCleanup);
        result.complete();
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }

  Future<void> _transitionTo(
    AccountSession next, {
    required bool retryCleanup,
  }) async {
    if (_disposed) return;
    if (!retryCleanup && _blockedTarget == null && session == next) return;
    final requiresCleanup = retryCleanup || _requiresCleanup(session, next);
    if (requiresCleanup) {
      availability = AccountAvailability.blocked;
      _notify();
      final cleanupError = await _clearAccountLocalState();
      if (_disposed) return;
      if (cleanupError != null) {
        _blockedTarget = next;
        errorMessage = '기기 계정 데이터를 지우지 못했습니다. 정리를 다시 시도해 주세요.';
        availability = AccountAvailability.blocked;
        _notify();
        return;
      }
    }
    _blockedTarget = null;
    session = next;
    availability = AccountAvailability.ready;
    errorMessage = null;
    _notify();
    if (next.isPermanent) {
      await onPermanentAccount?.call();
    }
  }

  bool _requiresCleanup(AccountSession current, AccountSession next) {
    if (!current.isAuthenticated) return false;
    return current.userId != next.userId ||
        (current.isPermanent && !next.isPermanent);
  }

  Future<Object?> _clearAccountLocalState() async {
    Object? cleanupError;
    try {
      await clearLocalState?.call();
    } on Object catch (error) {
      cleanupError = error;
    }
    try {
      await clearPaidCache?.call();
    } on Object catch (error) {
      cleanupError ??= error;
    }
    return cleanupError;
  }

  bool _isActive(int operation) =>
      !_disposed && operation == _operationGeneration;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _operationGeneration++;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
