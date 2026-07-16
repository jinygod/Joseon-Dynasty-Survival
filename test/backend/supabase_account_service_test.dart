import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/backend/account/account_service.dart';
import 'package:pixel_survivor/backend/account/account_session.dart';
import 'package:pixel_survivor/backend/account/supabase_account_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('delete API sends exact confirmation contract before signout', () async {
    String? functionName;
    Object? requestBody;
    var signOutCalls = 0;
    final api = SupabaseAccountApi(
      invoke: (name, {body}) async {
        functionName = name;
        requestBody = body;
        return const FunctionResponse(status: 204);
      },
      signOut: () async => signOutCalls++,
    );

    await api.deleteAccount();

    expect(functionName, 'delete-account');
    expect(requestBody, {'confirm': 'DELETE'});
    expect(signOutCalls, 1);
  });

  test('delete API rejects failure status without signing out', () async {
    var signOutCalls = 0;
    final api = SupabaseAccountApi(
      invoke: (_, {body}) async => const FunctionResponse(status: 400),
      signOut: () async => signOutCalls++,
    );

    await expectLater(api.deleteAccount(), throwsStateError);

    expect(signOutCalls, 0);
  });

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
    'failed existing-account fallback leaves the service signed out',
    () async {
      final gateway = _FakeGateway()
        ..identityExists = true
        ..signInGoogleError = Exception('offline');
      final service = SupabaseAccountService(
        authGateway: gateway,
        googleProvider: _FakeGoogleProvider(),
      );

      await expectLater(service.connectGoogle(), throwsException);

      expect(service.current, const AccountSession.signedOut());
    },
  );

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

      await expectLater(
        service.signOut(),
        throwsA(
          isA<AccountEndException>().having(
            (error) => error.remoteCompleted,
            'remote completed',
            isTrue,
          ),
        ),
      );

      expect(gateway.user, isNull);
      expect(gateway.calls, contains('sign-out'));
    },
  );

  test('native Google cleanup runs when Supabase signout fails', () async {
    final gateway = _FakeGateway()..signOutError = Exception('supabase');
    final google = _FakeGoogleProvider();
    final service = SupabaseAccountService(
      authGateway: gateway,
      googleProvider: google,
    );

    await expectLater(service.signOut(), throwsException);

    expect(google.signOutCalls, 1);
  });

  test('native Google cleanup runs when account deletion fails', () async {
    final gateway = _FakeGateway()..deleteError = Exception('delete');
    final google = _FakeGoogleProvider();
    final service = SupabaseAccountService(
      authGateway: gateway,
      googleProvider: google,
    );

    await expectLater(service.deleteAccount(), throwsException);

    expect(google.signOutCalls, 1);
  });
}

class _FakeGateway implements AccountAuthGateway {
  AccountAuthUser? user;
  bool identityExists = false;
  Object? signInGoogleError;
  Object? signOutError;
  Object? deleteError;
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
    if (signInGoogleError case final error?) throw error;
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
    if (signOutError case final error?) throw error;
    user = null;
  }

  @override
  Future<void> deleteAccount() async {
    if (deleteError case final error?) throw error;
    user = null;
  }
}

class _FakeGoogleProvider implements GoogleIdentityProvider {
  Object? signOutError;
  int initializeCalls = 0;
  int signOutCalls = 0;

  @override
  Future<void> initialize({String? serverClientId}) async => initializeCalls++;

  @override
  Future<String?> authenticate() async => 'id-token';

  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (signOutError case final error?) throw error;
  }
}
