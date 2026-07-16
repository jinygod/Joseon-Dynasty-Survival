import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/account_section.dart';
import 'package:pixel_survivor/backend/account/account_controller.dart';
import 'package:pixel_survivor/backend/account/account_service.dart';
import 'package:pixel_survivor/backend/account/account_session.dart';
import 'package:pixel_survivor/backend/backend_config.dart';

void main() {
  const enabled = BackendConfig(url: 'url', publishableKey: 'key');

  testWidgets('guest surface offers Google connection', (tester) async {
    final controller = AccountController(
      config: enabled,
      service: _FakeAccountService(AccountSession.anonymous(userId: 'guest')),
    );
    await controller.initialize();

    await tester.pumpWidget(_app(AccountSection(controller: controller)));

    expect(find.byKey(const Key('connect-google')), findsOneWidget);
    expect(find.textContaining('게스트'), findsOneWidget);
  });

  testWidgets('permanent surface shows email and sync action', (tester) async {
    var syncCalls = 0;
    final controller = AccountController(
      config: enabled,
      service: _FakeAccountService(
        AccountSession.google(userId: 'g', email: 'player@example.com'),
      ),
    );
    await controller.initialize();

    await tester.pumpWidget(
      _app(
        AccountSection(
          controller: controller,
          syncLabel: '동기화 완료',
          onSyncNow: () async => syncCalls++,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('sync-now')));

    expect(find.text('player@example.com'), findsOneWidget);
    expect(find.text('동기화 완료'), findsOneWidget);
    expect(syncCalls, 1);
  });

  testWidgets('account deletion requires confirmation', (tester) async {
    final service = _FakeAccountService(
      AccountSession.google(userId: 'g', email: 'player@example.com'),
    );
    final controller = AccountController(config: enabled, service: service);
    await controller.initialize();
    await tester.pumpWidget(_app(AccountSection(controller: controller)));

    await tester.tap(find.byKey(const Key('delete-account')));
    await tester.pumpAndSettle();
    expect(service.deleteCalls, 0);
    await tester.tap(find.byKey(const Key('delete-account-cancel')));
    await tester.pumpAndSettle();
    expect(service.deleteCalls, 0);

    await tester.tap(find.byKey(const Key('delete-account')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-account-confirm')));
    await tester.pumpAndSettle();
    expect(service.deleteCalls, 1);
  });
}

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

class _FakeAccountService implements AccountService {
  _FakeAccountService(this._current);

  final _changes = StreamController<AccountSession>.broadcast();
  AccountSession _current;
  int deleteCalls = 0;

  @override
  Stream<AccountSession> get changes => _changes.stream;
  @override
  AccountSession get current => _current;
  @override
  Future<AccountSession> ensureGuest() async => _current;
  @override
  Future<AccountSession> connectGoogle() async => _current;
  @override
  Future<void> signOut() async => _current = const AccountSession.signedOut();
  @override
  Future<void> deleteAccount() async {
    deleteCalls++;
    _current = const AccountSession.signedOut();
  }
}
