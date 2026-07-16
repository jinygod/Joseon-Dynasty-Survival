import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/backend/account/account_controller.dart';
import 'package:pixel_survivor/backend/account/account_service.dart';
import 'package:pixel_survivor/backend/account/account_session.dart';
import 'package:pixel_survivor/backend/backend_config.dart';

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
  int ensureGuestCalls = 0;
  int deleteCalls = 0;

  void setCurrent(AccountSession value) => _current = value;

  @override
  Stream<AccountSession> get changes => _changes.stream;

  @override
  AccountSession get current => _current;

  @override
  Future<AccountSession> ensureGuest() async {
    ensureGuestCalls++;
    if (ensureGuestError case final error?) throw error;
    if (!_current.isAuthenticated) {
      _current = AccountSession.anonymous(userId: 'guest-created');
    }
    return _current;
  }

  @override
  Future<AccountSession> connectGoogle() async {
    if (connectError case final error?) throw error;
    _current = connectResult ?? _current;
    return _current;
  }

  @override
  Future<void> signOut() async {
    _current = const AccountSession.signedOut();
  }

  @override
  Future<void> deleteAccount() async {
    deleteCalls++;
    _current = const AccountSession.signedOut();
  }
}
