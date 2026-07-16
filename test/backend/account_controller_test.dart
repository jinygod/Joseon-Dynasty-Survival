import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/backend/account/account_controller.dart';
import 'package:pixel_survivor/backend/account/account_service.dart';
import 'package:pixel_survivor/backend/account/account_session.dart';
import 'package:pixel_survivor/backend/backend_config.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';

void main() {
  const enabled = BackendConfig(
    url: 'https://example.supabase.co',
    publishableKey: 'publishable',
  );

  test('disabled backend remains a playable local guest', () async {
    final service = _FakeAccountService();
    final controller = AccountController(
      config: const BackendConfig.disabled(),
      service: service,
    );

    await controller.initialize();

    expect(controller.isGuest, isTrue);
    expect(controller.availability, AccountAvailability.disabled);
    expect(service.ensureGuestCalls, 0);
  });

  test('offline guest bootstrap never blocks local play', () async {
    final service = _FakeAccountService()
      ..ensureGuestError = Exception('offline');
    final controller = AccountController(config: enabled, service: service);

    await controller.initialize();

    expect(controller.isGuest, isTrue);
    expect(controller.availability, AccountAvailability.offline);
    expect(controller.busy, isFalse);
  });

  test('restores anonymous and Google sessions', () async {
    final anonymous = _FakeAccountService(
      current: AccountSession.anonymous(userId: 'guest-1'),
    );
    final anonymousController = AccountController(
      config: enabled,
      service: anonymous,
    );
    await anonymousController.initialize();
    expect(anonymousController.session.userId, 'guest-1');
    expect(anonymousController.isGuest, isTrue);

    final google = _FakeAccountService(
      current: AccountSession.google(
        userId: 'google-1',
        email: 'player@example.com',
      ),
    );
    final googleController = AccountController(
      config: enabled,
      service: google,
    );
    await googleController.initialize();
    expect(googleController.session.isPermanent, isTrue);
    expect(googleController.session.email, 'player@example.com');
  });

  test(
    'new Google identity preserves guest ID and triggers cloud sync',
    () async {
      final service =
          _FakeAccountService(
              current: AccountSession.anonymous(userId: 'guest-1'),
            )
            ..connectResult = AccountSession.google(
              userId: 'guest-1',
              email: 'new@example.com',
            );
      var syncCalls = 0;
      final controller = AccountController(
        config: enabled,
        service: service,
        onPermanentAccount: () async => syncCalls++,
      );
      await controller.initialize();

      await controller.connectGoogle();

      expect(controller.session.userId, 'guest-1');
      expect(controller.session.isPermanent, isTrue);
      expect(syncCalls, 1);
    },
  );

  test('existing Google identity switches to its cloud account', () async {
    final service =
        _FakeAccountService(
            current: AccountSession.anonymous(userId: 'guest-1'),
          )
          ..connectResult = AccountSession.google(
            userId: 'existing-9',
            email: 'existing@example.com',
          );
    final controller = AccountController(config: enabled, service: service);
    await controller.initialize();

    await controller.connectGoogle();

    expect(controller.session.userId, 'existing-9');
    expect(controller.session.email, 'existing@example.com');
  });

  test('Google cancellation keeps guest state without an error', () async {
    final guest = AccountSession.anonymous(userId: 'guest-1');
    final service = _FakeAccountService(current: guest)..connectResult = guest;
    final controller = AccountController(config: enabled, service: service);
    await controller.initialize();

    await controller.connectGoogle();

    expect(controller.session, guest);
    expect(controller.errorMessage, isNull);
  });

  test('Google errors are recoverable and keep local play available', () async {
    final guest = AccountSession.anonymous(userId: 'guest-1');
    final service = _FakeAccountService(current: guest)
      ..connectError = Exception('network');
    final controller = AccountController(config: enabled, service: service);
    await controller.initialize();

    await controller.connectGoogle();

    expect(controller.session, guest);
    expect(controller.errorMessage, isNotNull);
    expect(controller.busy, isFalse);
  });

  test(
    'identity fallback failure reflects the actual signed-out session',
    () async {
      final guest = AccountSession.anonymous(userId: 'guest-1');
      final service = _FakeAccountService(current: guest)
        ..connectError = Exception('existing account sign-in failed')
        ..connectCurrentOnError = const AccountSession.signedOut();
      final controller = AccountController(config: enabled, service: service);
      await controller.initialize();

      await controller.connectGoogle();

      expect(controller.session, const AccountSession.signedOut());
      expect(controller.errorMessage, isNotNull);
    },
  );

  test(
    'external account switch cleans old state before syncing new owner',
    () async {
      final accountA = AccountSession.google(userId: 'a', email: 'a@test');
      final accountB = AccountSession.google(userId: 'b', email: 'b@test');
      final service = _FakeAccountService(current: accountA);
      final calls = <String>[];
      late AccountController controller;
      controller = AccountController(
        config: enabled,
        service: service,
        clearLocalState: () async => calls.add('local'),
        clearPaidCache: () async => calls.add('paid'),
        onPermanentAccount: () async {
          calls.add('sync:${controller.session.userId}');
        },
      );
      await controller.initialize();
      calls.clear();

      service.emit(accountB);
      await flushAccountEvents();

      expect(calls, ['local', 'paid', 'sync:b']);
      expect(controller.session, accountB);
    },
  );

  test('failed transition cleanup blocks sync and can be retried', () async {
    final accountA = AccountSession.google(userId: 'a', email: 'a@test');
    final accountB = AccountSession.google(userId: 'b', email: 'b@test');
    final service = _FakeAccountService(current: accountA);
    var cleanupFails = true;
    var syncCalls = 0;
    final controller = AccountController(
      config: enabled,
      service: service,
      clearLocalState: () async {
        if (cleanupFails) throw StateError('disk');
      },
      onPermanentAccount: () async => syncCalls++,
    );
    await controller.initialize();
    syncCalls = 0;

    service.emit(accountB);
    await flushAccountEvents();

    expect(controller.availability, AccountAvailability.blocked);
    expect(controller.session, accountA);
    expect(controller.purchaseReady, isFalse);
    expect(controller.syncSession, const AccountSession.signedOut());
    expect(syncCalls, 0);

    cleanupFails = false;
    await controller.retryBlockedTransition();

    expect(controller.availability, AccountAvailability.ready);
    expect(controller.session, accountB);
    expect(syncCalls, 1);
  });

  test('sign out and deletion clear paid cache', () async {
    final service = _FakeAccountService(
      current: AccountSession.google(userId: 'g', email: 'g@example.com'),
    );
    var clears = 0;
    final controller = AccountController(
      config: enabled,
      service: service,
      clearPaidCache: () async => clears++,
    );
    await controller.initialize();

    await controller.signOut();
    expect(clears, 1);
    expect(controller.session, const AccountSession.signedOut());

    service.setCurrent(
      AccountSession.google(userId: 'g', email: 'g@example.com'),
    );
    await controller.initialize();
    await controller.deleteAccount();
    expect(clears, 2);
    expect(service.deleteCalls, 1);
  });

  test(
    'remote sign out failure keeps the session and local account state',
    () async {
      final original = AccountSession.google(
        userId: 'g',
        email: 'g@example.com',
      );
      final service = _FakeAccountService(current: original)
        ..signOutError = Exception('remote signout failed');
      final calls = <String>[];
      final controller = AccountController(
        config: enabled,
        service: service,
        clearLocalState: () async {
          calls.add('local');
          throw Exception('local clear failed');
        },
        clearPaidCache: () async => calls.add('paid'),
      );
      await controller.initialize();

      await controller.signOut();

      expect(calls, isEmpty);
      expect(controller.session, original);
      expect(controller.errorMessage, isNotNull);
      expect(controller.busy, isFalse);
    },
  );

  test('sign out removes account save before a new guest can play', () async {
    var local = SaveState.defaults().copyWith(totalKills: 500);
    final service = _FakeAccountService(
      current: AccountSession.google(userId: 'a', email: 'a@example.com'),
    );
    final controller = AccountController(
      config: enabled,
      service: service,
      clearLocalState: () async => local = SaveState.defaults(),
    );
    await controller.initialize();

    await controller.signOut();

    expect(local.totalKills, 0);
  });

  test(
    'remote success with native cleanup error does not restore old session',
    () async {
      final original = AccountSession.google(
        userId: 'g',
        email: 'g@example.com',
      );
      final service = _FakeAccountService(current: original)
        ..signOutError = AccountEndException(
          remoteCompleted: true,
          cause: Exception('native cleanup'),
        )
        ..endCurrentOnError = const AccountSession.signedOut();
      var clears = 0;
      final controller = AccountController(
        config: enabled,
        service: service,
        clearLocalState: () async => clears++,
      );
      await controller.initialize();

      await controller.signOut();

      expect(controller.session, const AccountSession.signedOut());
      expect(clears, 1);
      expect(controller.errorMessage, isNotNull);
    },
  );

  test('remote deletion failure keeps the existing session', () async {
    final original = AccountSession.google(userId: 'g', email: 'g@example.com');
    final service = _FakeAccountService(current: original)
      ..deleteError = Exception('remote deletion failed');
    var clears = 0;
    final controller = AccountController(
      config: enabled,
      service: service,
      clearLocalState: () async => clears++,
    );
    await controller.initialize();

    await controller.deleteAccount();

    expect(controller.session, original);
    expect(controller.errorMessage, isNotNull);
    expect(clears, 0);
  });

  test(
    'disposed initialization cannot mutate state or invoke callbacks',
    () async {
      final pending = Completer<AccountSession>();
      final service = _FakeAccountService()..ensureGuestCompleter = pending;
      var callbacks = 0;
      final controller = AccountController(
        config: enabled,
        service: service,
        onPermanentAccount: () async => callbacks++,
      );

      final initializing = controller.initialize();
      controller.dispose();
      pending.complete(
        AccountSession.google(userId: 'g', email: 'g@example.com'),
      );
      await initializing;

      expect(controller.session, const AccountSession.signedOut());
      expect(callbacks, 0);
    },
  );
}

class _FakeAccountService implements AccountService {
  factory _FakeAccountService({
    AccountSession current = const AccountSession.signedOut(),
  }) => _FakeAccountService._(current);

  _FakeAccountService._(this._current);

  final _changes = StreamController<AccountSession>.broadcast();
  AccountSession _current;
  AccountSession? connectResult;
  Object? ensureGuestError;
  Object? connectError;
  AccountSession? connectCurrentOnError;
  Object? signOutError;
  Object? deleteError;
  AccountSession? endCurrentOnError;
  Completer<AccountSession>? ensureGuestCompleter;
  int ensureGuestCalls = 0;
  int deleteCalls = 0;

  void setCurrent(AccountSession value) => _current = value;

  void emit(AccountSession value) {
    _current = value;
    _changes.add(value);
  }

  @override
  Stream<AccountSession> get changes => _changes.stream;

  @override
  AccountSession get current => _current;

  @override
  Future<AccountSession> ensureGuest() async {
    ensureGuestCalls++;
    if (ensureGuestError case final error?) throw error;
    if (ensureGuestCompleter case final pending?) return pending.future;
    if (!_current.isAuthenticated) {
      _current = AccountSession.anonymous(userId: 'guest-created');
    }
    return _current;
  }

  @override
  Future<AccountSession> connectGoogle() async {
    if (connectError case final error?) {
      if (connectCurrentOnError case final next?) _current = next;
      throw error;
    }
    _current = connectResult ?? _current;
    return _current;
  }

  @override
  Future<void> signOut() async {
    if (signOutError case final error?) {
      if (endCurrentOnError case final next?) _current = next;
      throw error;
    }
    _current = const AccountSession.signedOut();
  }

  @override
  Future<void> deleteAccount() async {
    deleteCalls++;
    if (deleteError case final error?) throw error;
    _current = const AccountSession.signedOut();
  }
}

Future<void> flushAccountEvents() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
