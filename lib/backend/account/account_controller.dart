import 'dart:async';

import 'package:flutter/foundation.dart';

import '../backend_config.dart';
import 'account_service.dart';
import 'account_session.dart';

enum AccountAvailability { disabled, ready, offline }

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
  bool _disposed = false;
  int _operationGeneration = 0;

  bool get isGuest => !session.isPermanent;
  bool get purchaseReady => session.isPermanent;

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
      if (_disposed) return;
      session = next;
      availability = AccountAvailability.ready;
      _notify();
    });
    busy = true;
    errorMessage = null;
    _notify();
    try {
      final next = await service.ensureGuest();
      if (!_isActive(operation)) return;
      session = next;
      availability = AccountAvailability.ready;
      if (session.isPermanent && onPermanentAccount != null) {
        await onPermanentAccount!();
        if (!_isActive(operation)) return;
      }
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
      session = next;
      availability = AccountAvailability.ready;
      if (next.isPermanent) {
        await onPermanentAccount?.call();
        if (!_isActive(operation)) return;
      }
    } on Object {
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

  Future<void> _endAccount(
    Future<void> Function() endRemote, {
    required String failureMessage,
  }) async {
    if (_disposed || busy) return;
    final operation = ++_operationGeneration;
    final previousSession = session;
    final previousAvailability = availability;
    busy = true;
    errorMessage = null;
    _notify();
    try {
      await endRemote();
      if (!_isActive(operation)) return;
      session = const AccountSession.signedOut();
      await _clearAccountLocalState();
    } on Object {
      if (!_isActive(operation)) return;
      session = previousSession;
      availability = previousAvailability;
      errorMessage = failureMessage;
    } finally {
      if (_isActive(operation)) {
        busy = false;
        _notify();
      }
    }
  }

  Future<void> _clearAccountLocalState() async {
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
    if (!_disposed && cleanupError != null && errorMessage == null) {
      errorMessage = '기기 계정 데이터를 지우지 못했습니다.';
    }
  }

  bool _isActive(int operation) =>
      !_disposed && operation == _operationGeneration;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _operationGeneration++;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
