import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account_service.dart';
import 'account_session.dart';

class SupabaseAccountService implements AccountService {
  SupabaseAccountService({SupabaseClient? client, String? googleServerClientId})
    : _client = client ?? Supabase.instance.client,
      _googleServerClientId =
          googleServerClientId ??
          const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  final SupabaseClient _client;
  final String _googleServerClientId;
  static Future<void>? _googleInitialization;

  @override
  Stream<AccountSession> get changes => _client.auth.onAuthStateChange.map(
    (event) => _fromUser(event.session?.user),
  );

  @override
  AccountSession get current => _fromUser(_client.auth.currentUser);

  @override
  Future<AccountSession> ensureGuest() async {
    final restored = current;
    if (restored.isAuthenticated) return restored;
    final response = await _client.auth.signInAnonymously();
    return _fromUser(response.user);
  }

  @override
  Future<AccountSession> connectGoogle() async {
    await _ensureGoogleInitialized();

    GoogleSignInAccount googleAccount;
    try {
      googleAccount = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted) {
        return current;
      }
      rethrow;
    }
    final idToken = googleAccount.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google Sign-In did not return an ID token');
    }

    try {
      final response = await _client.auth.linkIdentityWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      return _fromUser(response.user);
    } on AuthException catch (error) {
      if (!_identityAlreadyExists(error)) rethrow;
      await _client.auth.signOut(scope: SignOutScope.local);
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      return _fromUser(response.user);
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut(scope: SignOutScope.local);
    await _ensureGoogleInitialized();
    await GoogleSignIn.instance.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final response = await _client.functions.invoke('delete-account');
    if (response.status < 200 || response.status >= 300) {
      throw StateError('Account deletion failed (${response.status})');
    }
    await signOut();
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

  Future<void> _ensureGoogleInitialized() {
    return _googleInitialization ??= GoogleSignIn.instance.initialize(
      serverClientId: _googleServerClientId.isEmpty
          ? null
          : _googleServerClientId,
    );
  }

  static AccountSession _fromUser(User? user) {
    if (user == null) return const AccountSession.signedOut();
    if (user.isAnonymous) return AccountSession.anonymous(userId: user.id);
    return AccountSession.google(
      userId: user.id,
      email: user.email ?? 'Google 계정',
    );
  }
}
