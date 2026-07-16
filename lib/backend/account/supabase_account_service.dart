import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account_service.dart';
import 'account_session.dart';

class AccountAuthUser {
  const AccountAuthUser({
    required this.id,
    required this.isAnonymous,
    required this.providers,
    this.email,
  });

  final String id;
  final String? email;
  final bool isAnonymous;
  final Set<String> providers;
}

class AccountIdentityAlreadyExists implements Exception {
  const AccountIdentityAlreadyExists();
}

abstract interface class AccountAuthGateway {
  Stream<AccountAuthUser?> get changes;
  AccountAuthUser? get currentUser;
  Future<AccountAuthUser> signInAnonymously();
  Future<AccountAuthUser> linkGoogle(String idToken);
  Future<AccountAuthUser> signInGoogle(String idToken);
  Future<void> signOut();
  Future<void> deleteAccount();
}

abstract interface class GoogleIdentityProvider {
  Future<void> initialize({String? serverClientId});
  Future<String?> authenticate();
  Future<void> signOut();
}

class SupabaseAccountService implements AccountService {
  SupabaseAccountService({
    AccountAuthGateway? authGateway,
    GoogleIdentityProvider? googleProvider,
    String? googleServerClientId,
  }) : _auth =
           authGateway ?? _SupabaseAccountAuthGateway(Supabase.instance.client),
       _google = googleProvider ?? _NativeGoogleIdentityProvider(),
       _googleServerClientId =
           googleServerClientId ??
           const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  final AccountAuthGateway _auth;
  final GoogleIdentityProvider _google;
  final String _googleServerClientId;
  Future<void>? _googleInitialization;

  @override
  Stream<AccountSession> get changes => _auth.changes.map(_fromUser);

  @override
  AccountSession get current => _fromUser(_auth.currentUser);

  @override
  Future<AccountSession> ensureGuest() async {
    final restored = current;
    if (restored.isAuthenticated) return restored;
    return _fromUser(await _auth.signInAnonymously());
  }

  @override
  Future<AccountSession> connectGoogle() async {
    await ensureGuest();
    await _ensureGoogleInitialized();
    final idToken = await _google.authenticate();
    if (idToken == null) return current;
    if (idToken.isEmpty) {
      throw StateError('Google Sign-In did not return an ID token');
    }

    try {
      return _fromUser(await _auth.linkGoogle(idToken));
    } on AccountIdentityAlreadyExists {
      await _auth.signOut();
      return _fromUser(await _auth.signInGoogle(idToken));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } finally {
      await _ensureGoogleInitialized();
      await _google.signOut();
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _auth.deleteAccount();
    } finally {
      await _ensureGoogleInitialized();
      await _google.signOut();
    }
  }

  Future<void> _ensureGoogleInitialized() {
    return _googleInitialization ??= _google.initialize(
      serverClientId: _googleServerClientId.isEmpty
          ? null
          : _googleServerClientId,
    );
  }

  static AccountSession _fromUser(AccountAuthUser? user) {
    if (user == null) return const AccountSession.signedOut();
    if (user.isAnonymous) return AccountSession.anonymous(userId: user.id);
    final email = user.email?.trim();
    if (!user.providers.contains('google') || email == null || email.isEmpty) {
      return const AccountSession.signedOut();
    }
    return AccountSession.google(userId: user.id, email: email);
  }
}

class _SupabaseAccountAuthGateway implements AccountAuthGateway {
  _SupabaseAccountAuthGateway(this._client);

  final SupabaseClient _client;

  @override
  Stream<AccountAuthUser?> get changes =>
      _client.auth.onAuthStateChange.map((event) => _user(event.session?.user));

  @override
  AccountAuthUser? get currentUser => _user(_client.auth.currentUser);

  @override
  Future<AccountAuthUser> signInAnonymously() async {
    return _requiredUser((await _client.auth.signInAnonymously()).user);
  }

  @override
  Future<AccountAuthUser> linkGoogle(String idToken) async {
    try {
      final response = await _client.auth.linkIdentityWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      return _requiredUser(response.user);
    } on AuthException catch (error) {
      if (_identityAlreadyExists(error)) {
        throw const AccountIdentityAlreadyExists();
      }
      rethrow;
    }
  }

  @override
  Future<AccountAuthUser> signInGoogle(String idToken) async {
    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
    return _requiredUser(response.user);
  }

  @override
  Future<void> signOut() => _client.auth.signOut(scope: SignOutScope.local);

  @override
  Future<void> deleteAccount() async {
    final response = await _client.functions.invoke('delete-account');
    if (response.status < 200 || response.status >= 300) {
      throw StateError('Account deletion failed (${response.status})');
    }
    await _client.auth.signOut(scope: SignOutScope.local);
  }

  static bool _identityAlreadyExists(AuthException error) {
    final code = error.code?.toLowerCase() ?? '';
    final message = error.message.toLowerCase();
    return code == 'identity_already_exists' ||
        code == 'identity_already_linked' ||
        (message.contains('identity') &&
            (message.contains('already exists') ||
                message.contains('already linked')));
  }

  static AccountAuthUser _requiredUser(User? user) {
    final mapped = _user(user);
    if (mapped == null) throw StateError('Authentication returned no user');
    return mapped;
  }

  static AccountAuthUser? _user(User? user) {
    if (user == null) return null;
    return AccountAuthUser(
      id: user.id,
      email: user.email,
      isAnonymous: user.isAnonymous,
      providers: {
        for (final identity in user.identities ?? const <UserIdentity>[])
          identity.provider,
      },
    );
  }
}

class _NativeGoogleIdentityProvider implements GoogleIdentityProvider {
  static Future<void>? _initialization;

  @override
  Future<void> initialize({String? serverClientId}) {
    return _initialization ??= GoogleSignIn.instance.initialize(
      serverClientId: serverClientId,
    );
  }

  @override
  Future<String?> authenticate() async {
    try {
      return (await GoogleSignIn.instance.authenticate())
          .authentication
          .idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> signOut() => GoogleSignIn.instance.signOut();
}
