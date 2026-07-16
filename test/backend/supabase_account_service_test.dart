import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/backend/account/account_session.dart';
import 'package:pixel_survivor/backend/account/supabase_account_service.dart';

void main() {
  test('permanence requires an actual Google identity provider', () {
    final gateway = _FakeGateway()
      ..user = const AccountAuthUser(
        id: 'password-user',
        email: 'password@test',
        isAnonymous: false,
        providers: {'email'},
      );
    final service = SupabaseAccountService(
      authGateway: gateway,
      googleProvider: _FakeGoogleProvider(),
    );

    expect(service.current, const AccountSession.signedOut());

    gateway.user = const AccountAuthUser(
      id: 'google-user',
      email: 'google@test',
      isAnonymous: false,
      providers: {'email', 'google'},
    );
    expect(service.current.isPermanent, isTrue);
    expect(service.current.userId, 'google-user');
  });

  test(
    'connect from signed out bootstraps guest before linking Google',
    () async {
      final gateway = _FakeGateway();
      final google = _FakeGoogleProvider();
      final service = SupabaseAccountService(
        authGateway: gateway,
        googleProvider: google,
      );

      final session = await service.connectGoogle();

      expect(gateway.calls, ['anonymous', 'link:id-token']);
      expect(session.userId, 'guest-created');
      expect(session.isPermanent, isTrue);
    },
  );

  test('existing Google identity switches after bootstrapping guest', () async {
    final gateway = _FakeGateway()..identityExists = true;
    final service = SupabaseAccountService(
      authGateway: gateway,
      googleProvider: _FakeGoogleProvider(),
    );

    final session = await service.connectGoogle();

    expect(gateway.calls, [
      'anonymous',
      'link:id-token',
      'sign-out',
      'google:id-token',
    ]);
    expect(session.userId, 'existing-google');
  });

  test(
    'Supabase remains signed out when native Google signout fails',
    () async {
      final gateway = _FakeGateway()
        ..user = const AccountAuthUser(
          id: 'google-user',
          email: 'google@test',
          isAnonymous: false,
          providers: {'google'},
        );
      final google = _FakeGoogleProvider()..signOutError = Exception('native');
      final service = SupabaseAccountService(
        authGateway: gateway,
        googleProvider: google,
      );

      await expectLater(service.signOut(), throwsException);

      expect(gateway.user, isNull);
      expect(gateway.calls, contains('sign-out'));
    },
  );
}

class _FakeGateway implements AccountAuthGateway {
  AccountAuthUser? user;
  bool identityExists = false;
  final calls = <String>[];
  final controller = StreamController<AccountAuthUser?>.broadcast();

  @override
  Stream<AccountAuthUser?> get changes => controller.stream;

  @override
  AccountAuthUser? get currentUser => user;

  @override
  Future<AccountAuthUser> signInAnonymously() async {
    calls.add('anonymous');
    return user = const AccountAuthUser(
      id: 'guest-created',
      isAnonymous: true,
      providers: {'anonymous'},
    );
  }

  @override
  Future<AccountAuthUser> linkGoogle(String idToken) async {
    calls.add('link:$idToken');
    if (identityExists) throw const AccountIdentityAlreadyExists();
    return user = AccountAuthUser(
      id: user!.id,
      email: 'new@test',
      isAnonymous: false,
      providers: const {'google'},
    );
  }

  @override
  Future<AccountAuthUser> signInGoogle(String idToken) async {
    calls.add('google:$idToken');
    return user = const AccountAuthUser(
      id: 'existing-google',
      email: 'existing@test',
      isAnonymous: false,
      providers: {'google'},
    );
  }

  @override
  Future<void> signOut() async {
    calls.add('sign-out');
    user = null;
  }

  @override
  Future<void> deleteAccount() async => user = null;
}

class _FakeGoogleProvider implements GoogleIdentityProvider {
  Object? signOutError;
  int initializeCalls = 0;

  @override
  Future<void> initialize({String? serverClientId}) async => initializeCalls++;

  @override
  Future<String?> authenticate() async => 'id-token';

  @override
  Future<void> signOut() async {
    if (signOutError case final error?) throw error;
  }
}
