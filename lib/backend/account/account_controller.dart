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
    this.clearPaidCache,
    this.onPermanentAccount,
  }) : availability = config.enabled
           ? AccountAvailability.ready
           : AccountAvailability.disabled;

  final BackendConfig config;
  final AccountService service;
  final Future<void> Function()? clearPaidCache;
  Future<void> Function()? onPermanentAccount;

  AccountSession session = const AccountSession.signedOut();
  AccountAvailability availability;
  bool busy = false;
  String? errorMessage;
  StreamSubscription<AccountSession>? _subscription;
  bool _disposed = false;

  bool get isGuest => !session.isPermanent;
  bool get purchaseReady => session.isPermanent;

  Future<void> initialize() async {
    if (!config.enabled) {
      session = const AccountSession.signedOut();
      availability = AccountAvailability.disabled;
      _notify();
      return;
    }
    _subscription ??= service.changes.listen((next) {
      session = next;
      availability = AccountAvailability.ready;
      _notify();
    });
    busy = true;
    errorMessage = null;
    _notify();
    try {
      session = await service.ensureGuest();
      availability = AccountAvailability.ready;
      if (session.isPermanent && onPermanentAccount != null) {
        unawaited(onPermanentAccount!());
      }
    } on Object {
      session = const AccountSession.signedOut();
      availability = AccountAvailability.offline;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> connectGoogle() async {
    if (!config.enabled || busy) return;
    busy = true;
    errorMessage = null;
    _notify();
    try {
      final next = await service.connectGoogle();
      session = next;
      availability = AccountAvailability.ready;
      if (next.isPermanent) await onPermanentAccount?.call();
    } on Object {
      errorMessage = 'Google 계정 연결에 실패했습니다. 오프라인 플레이는 계속할 수 있습니다.';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> signOut() async {
    if (busy) return;
    busy = true;
    errorMessage = null;
    _notify();
    try {
      await service.signOut();
      await clearPaidCache?.call();
      session = const AccountSession.signedOut();
    } on Object {
      errorMessage = '로그아웃하지 못했습니다.';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> deleteAccount() async {
    if (busy) return;
    busy = true;
    errorMessage = null;
    _notify();
    try {
      await service.deleteAccount();
      await clearPaidCache?.call();
      session = const AccountSession.signedOut();
    } on Object {
      errorMessage = '계정을 삭제하지 못했습니다. 다시 로그인한 뒤 시도해 주세요.';
    } finally {
      busy = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
