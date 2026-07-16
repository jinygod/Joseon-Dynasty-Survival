import 'account_session.dart';

class AccountEndException implements Exception {
  const AccountEndException({
    required this.remoteCompleted,
    required this.cause,
    this.nativeCleanupError,
  });

  final bool remoteCompleted;
  final Object cause;
  final Object? nativeCleanupError;

  @override
  String toString() => 'AccountEndException: $cause';
}

abstract interface class AccountService {
  Stream<AccountSession> get changes;
  AccountSession get current;
  Future<AccountSession> ensureGuest();
  Future<AccountSession> connectGoogle();
  Future<void> signOut();
  Future<void> deleteAccount();
}
